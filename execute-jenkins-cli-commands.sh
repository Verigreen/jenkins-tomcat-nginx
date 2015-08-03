#! /bin/bash

#	Author: Jonathan Rosado Lugo
#	Description: 
# 		Script for triggering
# 		the seed job. The seed
#		job is responsible for
#		initializing the groovy
#		defined jobs.


echo "CLI: From cli script"

# Wait for Jenkins to load
while ! curl -s --head --request GET http://localhost:8080/ | grep "200 OK" > /dev/null;
do
	echo "CLI: Waiting for jenkins.."
	sleep 10
done

# Wait for Jenkins to load assets
sleep 10

if [[ -f "/var/tmp/cli.txt" ]]; then
	echo -e "\n" >> /var/tmp/cli.txt

	while read i; 
	do 
		echo "CLI: executing cli command $i"
		cd / && \
			$i | java -jar jenkins-cli.jar -s http://localhost:8081/ groovy =
	done < /var/tmp/cli.txt

	exit 0

else
	echo "CLI: /var/tmp/cli.txt was not found. Moving forward..."
	exit 0
fi