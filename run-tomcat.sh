#!/bin/bash

if [ ! -f /.tomcat_admin_created ]; then
    /create_tomcat_admin_user.sh
fi

# Dispatch files to the appropriate directory
# -v path/to/nginx.conf:/etc/nginx/nginx.conf:ro \
# 	-v path/to/supervisord.conf:/etc/supervisor/conf.d/supervisord.conf:ro \
# 	-v path/to/jenkins/log/directory/:/var/log/nginx/jenkins/ \
# 	-v path/to/supervisor/log/directory:/var/log/supervisor/ \
# 	-v path/to/plugins.txt:/usr/share/jenkins/plugins.txt \
# 	-v path/to/sample_jobs.groovy:/var/tmp/jobs.groovy \
# 	-v path/to/jenkins_home:/var/jenkins_home \

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
[[ -d /jenkins_home ]] && \
	cd /var/ && \
	rm -r jenkins_home && \
	ln -s /jenkins_home


# Clean up old groovy jobs (if any)
# Temporary solution
rm -r /var/jenkins_home/jobs/*


# Copy the seed job into the jobs directory
cp -f /var/tmp/jobs.groovy /var/tmp/groovy-dsl-job/workspace/jobs.groovy
mkdir -p /var/jenkins_home/jobs/ && \
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
	/bin/bash /usr/local/bin/plugins.sh /usr/share/jenkins/plugins.txt
fi

exec ${CATALINA_HOME}/bin/catalina.sh run
