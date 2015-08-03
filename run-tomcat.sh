#!/bin/bash

echo "RUN: From run.sh"

# Aliases
declare -A ALIAS

ALIAS["ldap-authentication"]="['class=hudson.security.LDAPSecurityRealm','plugin=ldap@1.6']"
ALIAS["login-authorization"]="['class=hudson.security.FullControlOnceLoggedInAuthorizationStrategy']"
ALIAS["database-authentication"]="['class=hudson.security.HudsonPrivateSecurityRealm']"
ALIAS["matrix-authorization"]="['class=hudson.security.ProjectMatrixAuthorizationStrategy']"
ALIAS["unsecured-authorization"]="['class=hudson.security.AuthorizationStrategy\$Unsecured']"

ALIAS["credentials-create"]="com.cloudbees.plugins.credentials.CredentialsProvider.Create"
ALIAS["credentials-delete"]="com.cloudbees.plugins.credentials.CredentialsProvider.Delete"
ALIAS["credentials-manage-domains"]="com.cloudbees.plugins.credentials.CredentialsProvider.ManageDomains"
ALIAS["credentials-update"]="com.cloudbees.plugins.credentials.CredentialsProvider.Update"
ALIAS["credentials-view"]="com.cloudbees.plugins.credentials.CredentialsProvider.View"

ALIAS["view-configure"]="hudson.model.View.Configure"
ALIAS["view-create"]="hudson.model.View.Create"
ALIAS["view-delete"]="hudson.model.View.Delete"
ALIAS["view-read"]="hudson.model.View.Read"

ALIAS["scm-tag"]="hudson.scm.SCM.Tag"

ALIAS["run-delete"]="hudson.model.Run.Delete"
ALIAS["run-update"]="hudson.model.Run.Update"

ALIAS["job-build"]="hudson.model.Item.Build"
ALIAS["job-cancel"]="hudson.model.Item.Cancel"
ALIAS["job-configure"]="hudson.model.Item.Configure"
ALIAS["job-create"]="hudson.model.Item.Create"
ALIAS["job-delete"]="hudson.model.Item.Delete"
ALIAS["job-discover"]="hudson.model.Item.Discover"
ALIAS["job-read"]="hudson.model.Item.Read"
ALIAS["job-workspace"]="hudson.model.Item.Workspace"

ALIAS["overall-administer"]="hudson.model.Hudson.Administer"
ALIAS["overall-configure-update-center"]="hudson.model.Hudson.ConfigureUpdateCenter"
ALIAS["overall-read"]="hudson.model.Hudson.Read"
ALIAS["overall-run-scripts"]="hudson.model.Hudson.RunScripts"
ALIAS["overall-upload-plugins"]="hudson.model.Hudson.UploadPlugins"

ALIAS["slave-build"]="hudson.model.Computer.Build"
ALIAS["slave-configure"]="hudson.model.Computer.Configure"
ALIAS["slave-connect"]="hudson.model.Computer.Connect"
ALIAS["slave-create"]="hudson.model.Computer.Create"
ALIAS["slave-delete"]="hudson.model.Computer.Delete"
ALIAS["slave-disconnect"]="hudson.model.Computer.Disconnect"

# Regex is kept uncompressed for readability and maintainability
ALIAS_REGEX="^(ldap-authentication|login-authorization|database-authentication|matrix-authorization|\
credentials-create|credentials-delete|credentials-manage-domains|credentials-update|\
credentials-view|view-configure|view-create|view-delete|view-read|scm-tag|run-delete|\
run-update|job-build|job-cancel|job-configure|job-create|job-delete|job-discover|\
job-read|job-workspace|overall-administer|overall-configure-update-center|overall-read|\
overall-run-scripts|overall-upload-plugins|slave-build|slave-configure|slave-connect|slave-create|\
slave-delete|slave-disconnect|unsecured-authorization)$"

function take_care_of_special_cases {
	NODE_PATH=$1
	NODE_NAME=$2
	NODE_VALUE=$3

	if [[ "$NODE_NAME" == "attributes" ]]; then

		[[ "$NODE_VALUE" =~ $ALIAS_REGEX ]] && \
			NODE_VALUE="${ALIAS[$NODE_VALUE]}"

		LIST=$(python -c "for i in ${NODE_VALUE}: print i;")

		IFS=$'\n'
		for i in $LIST; do
			ATTR_NAME=$(echo $i | awk -F'=' '{print $1}')
			ATTR_VALUE=$(echo $i | awk -F'=' '{print $2}')
			OPERATION="$(xmlstarlet ed -i "$NODE_PATH" -t attr -n $ATTR_NAME -v $ATTR_VALUE /config.xml)"
			if [[ -n $OPERATION ]]; then
				echo "$OPERATION" > /config.xml
			fi
		done
		unset IFS

		return 1;

	elif [[ "${NODE_NAME}" == "plugins" ]]; then

		LIST=$(python -c "for i in ${NODE_VALUE}: print i;")

		IFS=$'\n'
		for i in $LIST; do
			echo $i >> /plugins.txt
		done
		unset IFS

		return 1;

	elif [[ "$NODE_PATH" == "/certificates" ]] && [[ "${NODE_NAME}" == "remote" ]]; then

		LIST=$(python -c "for i in ${NODE_VALUE}: print i;")

		IFS=$'\n'
		for i in $LIST; do
			echo $i >> /SSLcerts.txt
		done
		unset IFS

		return 1;

	elif [[ "$NODE_PATH" == "/certificates" ]] && [[ "${NODE_NAME}" == "local" ]]; then

		LIST=$(python -c "for i in ${NODE_VALUE}: print i;")

		IFS=$'\n'
		for i in $LIST; do
			echo $i >> /SSLcerts_local.txt
		done
		unset IFS

		return 1;

	elif [[ "${NODE_NAME}" == "commands" ]]; then

		LIST=$(python -c "for i in ${NODE_VALUE}: print i;")

		IFS=$'\n'
		for i in $LIST; do
			echo $i >> /cli.txt
		done
		unset IFS

		return 1;

	elif [[ "$NODE_PATH" == "/users" ]] && [[ "${NODE_NAME}" == "hashed" ]]; then

		LIST=$(python -c "for i in ${NODE_VALUE}: print i;")

		IFS=$'\n'
		for i in $LIST; do
			echo "${i}:hashed" >> /users.txt
		done
		unset IFS

		return 1;

	elif [[ "$NODE_PATH" == "/users" ]] && [[ "${NODE_NAME}" == "unhashed" ]]; then

		LIST=$(python -c "for i in ${NODE_VALUE}: print i;")

		IFS=$'\n'
		for i in $LIST; do
			echo "${i}:unhashed" >> /users.txt
		done
		unset IFS

		return 1;

	elif [[ "$NODE_PATH" == "/hudson/securityRealm" ]] && [[ "$NODE_NAME" == "managerPassword" ]]; then

		NODE_VALUE=$(echo $NODE_VALUE | base64 | awk -F'=' '{print $1}')

		echo -e "$(xmlstarlet ed -s "$NODE_PATH" -t elem -n "$NODE_NAME" -v "$NODE_VALUE" /config.xml)" > /config.xml

		return 1;

	elif [[ "$NODE_PATH" == "/hudson/authorizationStrategy" ]] && [[ "$NODE_NAME" == "permissions" ]]; then

		LIST=$(python -c "for i in ${NODE_VALUE}: print i;")

		IFS=$'\n'
		for i in $LIST; do
			PERMISSION=$(echo $i | awk -F':' '{print $1}');
			USER=$(echo $i | awk -F':' '{print $2}');

			if [[ "${PERMISSION}" =~ $ALIAS_REGEX ]]; then
				i="${ALIAS[$PERMISSION]}:${USER}"
			fi

		    echo -e "$(xmlstarlet ed -s "$NODE_PATH" -t elem -n "permission" -v "$i" /config.xml)" > /config.xml
		done
		unset IFS

		return 1;

	else
		return 0;
	fi
}

function build_path {
	NODE_PATH=$1

	INCREMENTAL_PATH=''

	IFS=$'/'
	for i in $NODE_PATH; do
		if [[ ! -z $i ]] && [[ "$i" != "attributes" ]]; then
			NODE="$i"
			cPATH="${INCREMENTAL_PATH}"
    		INCREMENTAL_PATH="${cPATH}/${NODE}"
    		COUNT=$(xmlstarlet sel -t -v "count(${INCREMENTAL_PATH})" /config.xml)
    		echo "INCREMENTAL_PATH: ${INCREMENTAL_PATH}, cPATH: ${cPATH}, NODE: ${NODE}"
    		[[ $COUNT -eq 0 ]] && \
    			echo -e "$(xmlstarlet ed -s "$cPATH" -t elem -n "$NODE" -v "" /config.xml)" > /config.xml
		fi
	done
	unset IFS

	return 0
}

CONFIG_YML_HAS_HUDSON_TAG="false"

# Parse and dispatch config.yml
if [[ -f /config.yml ]]; then
	echo -e "RUN: config.yml detected."

	echo -e '<?xml version="1.0" encoding="UTF-8"?>\n<hudson>\n\n</hudson>' > /config.xml

	IFS=$'\n'
	for i in $(python configparser.py config.yml); do
		NODE_PATH=$(echo $i | awk -F'|' '{print $1}' | awk -F'/' -v OFS='/' '{$NF="" ;print $0}' | sed 's/.\{1\}$//');
		NODE_NAME=$(echo $i | awk -F'|' '{print $1}' | awk -F'/' '{print $(NF)}');
		NODE_VALUE=$(echo $i | awk -F'|' '{print $2}');

		# If a hudson tag is detected, flag it. This means that the config.xml generated by the config.yml configuration
		# Should be copied to the /var/jenkins_home. Overwriting any previous configuration if necessary
		[[ "${NODE_PATH}" =~ ^/hudson.*$ ]] && \
			echo "RUN: Hudson detected in config.yml" && \
			CONFIG_YML_HAS_HUDSON_TAG="true"

		if build_path "${NODE_PATH}" && take_care_of_special_cases "$NODE_PATH" "$NODE_NAME" "$NODE_VALUE"; then
			echo -e "$(xmlstarlet ed -s "$NODE_PATH" -t elem -n "$NODE_NAME" -v "$NODE_VALUE" /config.xml)" > /config.xml
		fi
	done
	unset IFS

	# Could use the 'g' option to match multiple instances in a line
	# Workaroud for editing a file with sed. See http://stackoverflow.com/questions/2585438/redirect-output-from-sed-s-c-d-myfile-to-myfile
	sed -r 's:(<.*)-[1-9]*( *| .*)?(>.*):\1\2\3:' /config.xml |  sed -r 's:(<.*)-[1-9]*( *| .*)?(>.*):\1\2\3:' > /temp_file && mv /temp_file /config.xml
fi

# Dispatch files to the appropriate directory
[[ -f /nginx.conf ]] && \
	cd /etc/nginx/ && \
	rm nginx.conf && \
	ln -s /nginx.conf
[[ -f /supervisor.conf ]] && \
	cd /etc/supervisor/conf.d/ && \
	rm supervisord.conf && \
	ln -s /supervisor.conf
[[ -f /plugins.txt ]] && \
	cd /usr/share/jenkins/ && \
	rm plugins.txt && \
	ln -s /plugins.txt
[[ -f /jobs.groovy ]] && \
	cd /var/tmp/ && \
	ln -s /jobs.groovy
[[ -f /cli.txt ]] && \
	cd /var/tmp/ && \
	ln -s /cli.txt
[[ -d /jenkins_home ]] && \
	cd /var/ && \
	rm -r jenkins_home && \
	ln -s /jenkins_home


timestamp() {
  date +"%T"
}


# If $ADMIN_PASSWORD was defined,
# create a quick admin account
if [[ -f /config.xml ]] && [[ $CONFIG_YML_HAS_HUDSON_TAG == "true" ]]; then
	echo "RUN: Moving config.xml to /var/jenkins_home"

	cd /var/jenkins_home && \
	if [[ ! -d .git ]]; then
		echo "RUN: Git repo not found in /var/jenkins_home; Initializing."
		git init
	fi

	TIMESTAMP=$( echo $(timestamp) | sed -r 's|(.*):(.*):(.*)|\1-\2-\3|' )

	echo "RUN: commiting {TIMESTAMP}"

	git add -A .

	git commit -m "timestamp: ${TIMESTAMP}"

	cp /config.xml /var/jenkins_home/config.xml

	echo "RUN: Moved /config.xml to /var/jenkins_home"

fi


# If SSLcerts.txt is found in the root folder,
# read the file line by line, parsing each line
# and feeding them to the Java keytool
[[ -f /SSLcerts.txt ]] && \
	while read i;
	do

		ADDRESS=$(echo $i | awk -F':' '{print $1}');
		PORT=$(echo $i | awk -F':' '{print $2}');
		CERT_IN_CHAIN=$(echo $i | awk -F':' '{print $3}');

		echo "RUN: Downloading certificate for $ADDRESS:$PORT"

		# Store the whole certificate chain in /tmp/ADDRESS.cert
		echo -n | openssl s_client -showcerts -connect $ADDRESS:$PORT | \
		sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' > /tmp/$ADDRESS-$PORT-$CERT_IN_CHAIN.cert

# 		# Grab the nth certificate from the chain
python -c "
import re

pattern = re.compile(\"\-\-\-\-\-BEGIN CERTIFICATE\-\-\-\-\-[^-]+\-\-\-\-\-END CERTIFICATE\-\-\-\-\-\")

with open (\"/tmp/${ADDRESS}-${PORT}-${CERT_IN_CHAIN}.cert\", \"r\") as certificateFile:
  certificateData = certificateFile.read()

print pattern.findall(certificateData)[${CERT_IN_CHAIN} - 1]" > /tmp/${ADDRESS}-${PORT}-${CERT_IN_CHAIN}_single.cert


		echo -e "changeit\nyes" | $JAVA_HOME/bin/keytool -import -alias $ADDRESS-$PORT-$CERT_IN_CHAIN -keystore $JAVA_HOME/jre/lib/security/cacerts -file /tmp/${ADDRESS}-${PORT}-${CERT_IN_CHAIN}_single.cert

	done < /SSLcerts.txt


# If SSLcerts_local.txt is found in the root folder,
# read the file line by line, grabing the certificate
# from the mounted directory and feeding it to the keytool
[[ -f /SSLcerts_local.txt ]] && \
	while read i;
	do

		echo "RUN: Importing local certificate in $i"

		echo -e "changeit\nyes" | $JAVA_HOME/bin/keytool -import -alias $i -keystore $JAVA_HOME/jre/lib/security/cacerts -file $i

	done < /SSLcerts_local.txt


# If users.txt was is found,
# loop through the file and
# create each user
[[ -f /users.txt ]] && \
	echo -e "\n" >> /users.txt && \
	while read i;
	do
		USERNAME=$(echo $i | awk -F':' '{print $1}');
		PASSWORD=$(echo $i | awk -F':' '{print $2}');
		SECURITY=$(echo $i | awk -F':' '{print $3}');

		echo "RUN: Making account for $USERNAME"

		[[ -d /var/jenkins_home/users ]] || mkdir /var/jenkins_home/users

		mkdir /var/jenkins_home/users/$USERNAME

		# Copy user xml template
		cp -f /user-template.xml /var/jenkins_home/users/$USERNAME/config.xml

		# If password is not hashed, convert password to hash
		[[ "$SECURITY" == "unhashed" ]] && \
			PASSWORD=$(echo -n "$PASSWORD{oxulLC}" | sha256sum | awk '{print $1}')

		# Replace dummy values in template
		echo -e "$(xmlstarlet ed -u '/user/fullName' -v "$USERNAME" /var/jenkins_home/users/${USERNAME}/config.xml)" > /var/jenkins_home/users/$USERNAME/config.xml
		echo -e "$(xmlstarlet ed -u '/user/properties/hudson.security.HudsonPrivateSecurityRealm_-Details/passwordHash' -v "oxulLC:${PASSWORD}" /var/jenkins_home/users/${USERNAME}/config.xml)" \
			> /var/jenkins_home/users/$USERNAME/config.xml

	done < /users.txt


# If $ADMIN_PASSWORD was defined,
# create a quick admin account
if [[ ! -z $ADMIN_PASSWORD ]]; then
	USERNAME="admin"
	PASSWORD=$ADMIN_PASSWORD

	echo "RUN: Making account for $USERNAME"

	[[ -d /var/jenkins_home/users ]] || mkdir /var/jenkins_home/users

	mkdir /var/jenkins_home/users/$USERNAME

	# Copy user xml template
	cp -f /user-template.xml /var/jenkins_home/users/$USERNAME/config.xml

	# Convert password to hash (and add some embedded salt)
	PASSWORD=$(echo -n "$PASSWORD{oxulLC}" | sha256sum | awk '{print $1}')

	# Replace dummy values in template
	echo -e "$(xmlstarlet ed -u '/user/fullName' -v "$USERNAME" /var/jenkins_home/users/${USERNAME}/config.xml)" > /var/jenkins_home/users/$USERNAME/config.xml
	echo -e "$(xmlstarlet ed -u '/user/properties/hudson.security.HudsonPrivateSecurityRealm_-Details/passwordHash' -v "oxulLC:${PASSWORD}" /var/jenkins_home/users/${USERNAME}/config.xml)" \
		> /var/jenkins_home/users/$USERNAME/config.xml
fi


# Clean up old groovy jobs (if any)
# Temporary solution
rm -r /var/jenkins_home/jobs/*-groovy


# Copy the seed job into the jobs directory
[[ -d /var/tmp/groovy-dsl-job/workspace/ ]] || mkdir -p /var/tmp/groovy-dsl-job/workspace/
cp -f /var/tmp/jobs.groovy /var/tmp/groovy-dsl-job/workspace/jobs.groovy
[[ -d /var/jenkins_home/jobs/ ]] || mkdir -p /var/jenkins_home/jobs/
cp -f -R /var/tmp/groovy-dsl-job/ /var/jenkins_home/jobs/groovy-dsl-job/

PLUGINS_INSTALLED="true"

for i in $( cat /usr/share/jenkins/plugins.txt | awk -F':' '{print $1}' );
do
    if [[ ! $( ls /tomcat/webapps/ROOT/WEB-INF/plugins | grep "${i}.hpi" ) ]]; then
        PLUGINS_INSTALLED="false"
    fi
done

if [[ $PLUGINS_INSTALLED == "false" ]]; then
	# Load the plugins before running Catalina
	# Do not load plugins if they've already been loaded
	# (This can happen when Jenkins needs to restart)
	source /usr/local/bin/plugins.sh /usr/share/jenkins/plugins.txt
fi

exec ${CATALINA_HOME}/bin/catalina.sh run
