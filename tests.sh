#! /bin/bash
# 
# Test suite for jenkins on tomcat + nginx 
# ========================================
# 
# ## Maintainer(s):
#	Jonathan Rosado Lugo <jonathan.rosado-lugo@hp.com>
#
# Example: Executing the script
#
# ```
# ./tests.sh \
# 	myContainer \
# 	~/jenkins/custom-jenkins-plugins.txt \
# 	localhost \
# 	~/hp/work/jenkins-served-by-nginx/sample_jobs.groovy
# ```



# Exit the script if any variable is used without being initialized
set -u

# Exit the script if any statement returns a non-true return value (so errors dont keep piling up)
set -e


# Verbose output
verbose=false


# An X marks failure, while an O marks success
success="PASSED"
failure="FAILED"


# Objectives with their status
isOnlineObjective=$failure
pluginsObjective=$failure
jobsObjective=$failure


# Show Usage
function show_usage {
	echo -e "Usage: $0\nUsage: $0 -v #verbose "
}


# Prepare environment for testing
function prepare_environment {
	$verbose && \
	 echo "Preparing Environment..." 

	$verbose && \
	 echo "For this test we will be installing two groovy jobs and the campfire plugin"

	# Make a directory for the container to use as volume
	mkdir -p /tmp/jenkins_test_dir/jenkins_home

	# Make a plugins.txt containing the plugins to be installed in the container
	echo -e "campfire:2.7\nant:1.2\ndocker-plugin:0.8\nssh-slaves:1.6\ndurable-task:0.5" > /tmp/jenkins_test_dir/plugins.txt

	# Make a groovy file containing the jobs the container must have
	echo -e \
	" 
	job('DSL-Tutorial-3-Test-groovy') {
	    scm {
	        git('git://github.com/jgritman/aws-sdk-test.git')
	    }
	    triggers {
	        scm('*/15 * * * *')
	    }
	    steps {
	        maven('-e clean test')
	    }
	}

	job('DSL-Tutorial-2-Test-groovy') {
	    scm {
	        git('git://github.com/jgritman/aws-sdk-test.git')
	    }
	    triggers {
	        scm('*/15 * * * *')
	    }
	    steps {
	        maven('-e clean test')
	    }
	}
	" > /tmp/jenkins_test_dir/my_jobs.groovy

	# Build image
	sudo docker build --quiet=true -t jenkins_test_img . > /dev/null

	# Run container with the files we just made
	sudo docker run \
		-d \
		--name jenkins_test_cont \
		-p 80:8081 \
		-v /tmp/jenkins_test_dir/plugins.txt:/usr/share/jenkins/plugins.txt \
		-v /tmp/jenkins_test_dir/my_jobs.groovy:/var/tmp/jobs.groovy \
		-v /tmp/jenkins_test_dir/jenkins_home:/var/jenkins_home \
		jenkins_test_img > /dev/null

	# Wait for Jenkins to start up (Jenkins has to restart the first time)
	# The loop will exit when Jenkins has successfuly started for the second time
	jenkinsFound=false
	toggles=0
	while [[ $toggles < 3 ]];
	do
		# If the GET request doesn't return an OK status, Jenkins is not running correctly
		if [[ ! $( curl -s --head --request GET http://localhost:80/ | grep "200 OK" ) ]]; then
			$verbose && \
			 echo "Jenkins is not running. Maybe it's initializing? Let's Try again."
			[[ $jenkinsFound = true ]] && toggles=$(($toggles + 1))
			jenkinsFound=false
		else
			$verbose && \
			 echo "Jenkins is running!"
			[[ $jenkinsFound = false ]] && toggles=$(($toggles + 1))
			jenkinsFound=true
		fi
	done

	sleep 10

}


# Prepare environment for testing
function cleanup_environment {

	$verbose && \
	 echo "========Cleaning Up Environment========" 

	# Remove test directory
	sudo rm -r /tmp/jenkins_test_dir > /dev/null

	# Remove container
	sudo docker rm -f jenkins_test_cont > /dev/null

	# Remove Image
	sudo docker rmi jenkins_test_img > /dev/null
}


# Check to see if default plugins have been installed (that they are in the plugins directory)
function test_has_default_plugins {

	# This boolean will represent the failure (or success) of the test
	status=true

	# Grab the list of default plugins from the text file
	for i in $( cat default_jenkins_plugins.txt | awk -F':' '{print $1}' ); 
	do 
		# Loop through each default plugin and see if it's in the plugins directory
	    if [[ $( sudo docker exec -ti jenkins_test_cont ls /var/jenkins_home/plugins | grep $i ) ]]; then 
	        $verbose && \
	         echo "$success The default plugin $i was found in Jenkins' home directory"
	    else
	    	status=false && \
	    	 $verbose && \
	    	 echo "$failure The default plugin $i was NOT found in Jenkins' home directory"
	    	return 1
	    fi 
	done

	printf "$( ( $status && echo $success ) || echo $failure) "
	printf "Checking to see if default plugins are installed\n"

	return 0
}


# Check to see if custom plugins have been installed
function test_has_custom_plugins {

	# This boolean will represent the failure (or success) of the test
	status=true

	# Grab the list of custom plugins from the text file
	for i in $( cat /tmp/jenkins_test_dir/plugins.txt | awk -F':' '{print $1}' ); 
	do 
		# Loop through each custom plugin and see if it's in the plugins directory
	    if [[ $( sudo docker exec -ti jenkins_test_cont ls /var/jenkins_home/plugins | grep $i ) ]]; then 
	        $verbose && \
	         echo "$success The custom plugin $i was found in Jenkins' home directory"
	    else
	    	status=false && \
	    	 $verbose && \
	    	 echo "$failure The custom plugin $i was NOT found in Jenkins' home directory"
	    	return 1
	    fi 
	done

	printf "$( ( $status && echo $success ) || echo $failure) "
	printf "Checking to see if custom plugins are installed\n"

	return 0
}


# Check to see if custom AND default plugins have been loaded (they're found in the 'installed' section)
function test_plugins_are_loaded {


	# This boolean will represent the failure (or success) of the test
	status=true

	# Grab the list of default plugins from the text file
	for i in $( cat default_jenkins_plugins.txt | awk -F':' '{print $1}' );
	do
		# Loop through them and see if they're in the installed section of the webapp
		if [[ $( curl -s "http://localhost:80/pluginManager/installed" | grep /$i\" ) ]]; then 
	        $verbose && \
	         echo "$success The default plugin $i was found in http://localhost:80/pluginManager/installed"
	    else
	    	status=false && \
	    	 $verbose && \
	    	 echo "$failure The default plugin $i was NOT found in http://localhost:80/pluginManager/installed"
	    	return 1
	    fi 
	done

	# Grab the list of custom plugins from the text file
	for i in $( cat /tmp/jenkins_test_dir/plugins.txt | awk -F':' '{print $1}' );
	do
		# Loop through them and see if they're in the installed section of the webapp
		if [[ $( curl -s "http://localhost:80/pluginManager/installed" | grep /$i\" ) ]]; then 
	        $verbose && \
	         echo "$success The custom plugin $i was found in http://localhost:80/pluginManager/installed"
	    else
	    	status=false && \
	    	 $verbose && \
	    	 echo "$failure The custom plugin $i was NOT found in http://localhost:80/pluginManager/installed"
	    	return 1
	    fi 
	done

	printf "$( ( $status && echo $success ) || echo $failure) "
	printf "Checking to see if the plugins are loaded\n"

	return 0
}


# Check to see if groovy jobs have been installed (they're found in the jobs directory)
function test_jobs_are_installed {

	# This boolean will represent the failure (or success) of the test
	status=true 

	# Grab each job name from the groovy file
	for i in $( awk '/job/{ print $0 }' /tmp/jenkins_test_dir/my_jobs.groovy | awk -F"'" '{print $2}' ); 
	do 
		# Loop through and see if the names appear in the jobs directory
	    if [[ $( sudo docker exec -ti jenkins_test_cont ls /var/jenkins_home/jobs | grep $i ) ]]; then 
	        $verbose && \
	         echo "$success The groovy job $i was found in Jenkins' home directory"
	    else
	    	status=false && \
	    	 $verbose && \
	    	 echo "$failure The groovy job $i was NOT found in Jenkins' home directory"
	    	return 1
	    fi 
	done

	printf "$( ( $status && echo $success ) || echo $failure) "
	printf "Checking to see if the jobs are installed\n"

	return 0
}


# Check to see if groovy jobs have been loaded (are found in the webapp)
function test_jobs_are_loaded {

	status=true

	# Grap job names from the groovy file
	for i in $( awk '/job/{ print $0 }' /tmp/jenkins_test_dir/my_jobs.groovy | awk -F"'" '{print $2}' ); 
	do 
		# Loop through each job name and see if they appear under 'jobs'
	    if [[ $( curl -s "http://localhost:80" | grep /$i/ ) ]]; then 
	        $verbose && \
	         echo "$success The groovy job $i was found in http://localhost:80/"
	    else
	    	status=false && \
	    	 $verbose && \
	    	 echo "$failure The groovy job $i was NOT found in http://localhost:80/"
	    	return 1
	    fi 
	done

	printf "$( ( $status && echo $success ) || echo $failure) "
	printf "Checking to see if the jobs are loaded\n"

	return 0
}


while getopts "v" opt; do
  case $opt in
    v)
      verbose=true
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      exit 1
      ;;
  esac
done


#ENTRYPOINT
if [[ $# -gt 1 ]]; then
        show_usage
else

		# Prepare environment for testing
		prepare_environment

		# Verify that the default and custom plugins are installed (in corresponding directory)
        test_has_default_plugins && \
        test_has_custom_plugins && \
        test_plugins_are_loaded

        # Verify that groovy jobs are loaded
        test_jobs_are_installed && \
        test_jobs_are_loaded

        # Clean up environment
        cleanup_environment
fi