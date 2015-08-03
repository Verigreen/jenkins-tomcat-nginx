#!/bin/bash

# Programmically Enable Jobs in Jenkins Jobs DSL Plugin
# =====================================================
#
# ## Maintainer(s)
# 	Jonathan Rosado Lugo
# 
# ## Description: 
#
# 	Script for triggering the seed job. The seed job is responsible for
#	initializing the groovy defined jobs.


echo "GRO: Executing..."

JOB_INSTALLED="true"

function check_groovy_dsl_job {
	# Wait for Jenkins to load
	while ! curl -s --head --request GET http://localhost:8080/ | grep "200 OK" > /dev/null;
	do
		echo "GRO: Waiting for jenkins.."
		sleep 10
	done

	# Wait for Jenkins to load assets
	sleep 10

	# Once it loads, look to see if the groovy-dsl-job persisted from a past instance
	if [[ $( curl -s "http://localhost:8080" | grep /groovy-dsl-job/ ) ]]; then 
		echo "GRO: groovy-dsl-job was found"
	else
		JOB_INSTALLED="false"
		echo "GRO: groovy-dsl-job was NOT found"
	fi 
}

check_groovy_dsl_job

while true;
do
	if [[ -f "/var/tmp/jobs.groovy" ]]; then

		if [[ $JOB_INSTALLED == "false" ]]; then
			cp -f /var/tmp/jobs.groovy /var/tmp/groovy-dsl-job/workspace/jobs.groovy
			mkdir -p /var/jenkins_home/jobs/ && \
 				cp -f -R /var/tmp/groovy-dsl-job/ /var/jenkins_home/jobs/groovy-dsl-job/
			echo "GRO: Job installed"
			JOB_INSTALLED="true"
			supervisorctl restart all:jenkins
			check_groovy_dsl_job
		else
			if [[ $(curl -s --head --request GET http://localhost:8080/job/groovy-dsl-job/build?token=khDWRWANOPMLKJNbVTcRCreXerTYrcTUvtuCREYBuYYfvUYTC \
				    | grep "201 Created" ) ]]; then
				echo "GRO: Seed has been built"

				# Wait for the seed job to build
				sleep 50

				#curl -s --head --request POST http://localhost:8080/job/groovy-dsl-job/doDelete
				exit 0
			fi
		fi

	else
		exit 0
	fi
done