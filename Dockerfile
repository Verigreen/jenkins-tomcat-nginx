#	Jenkins on tomcat + nginx
#	=========================
#	## Description: 
# 	
#	Dockerfile for running
# 	Jenkins on top of Tomcat (with
# 	nginx serving the static content)
# 	within a docker container.
#
#	## Maintainer(s)
#
#	Jonathan Rosado Lugo <jonathan.rosado-lugo@hp.com>
#	Ricardo Quintana <ricardo.quintana@hp.com>
#
#	## References
#	
#	- [Jenkins offical docker image](https://github.com/jenkinsci/docker)
#	- [Tomcat official docker image](https://github.com/docker-library/tomcat/)
# 

FROM nginx:1.7.12
MAINTAINER Jonathan Rosado <jonathan.rosado-lugo@hp.com>

# Version for jenkins
# Update center for jenkins
# Versions for tomcat
# Tomcat home
ENV JENKINS_VERSION=1.596.2 \
	JENKINS_UC=https://updates.jenkins-ci.org \
	TOMCAT_MAJOR_VERSION=7 \
	TOMCAT_MINOR_VERSION=7.0.55 \
	CATALINA_HOME=/tomcat 


# Add script for running Tomcat
ADD run-tomcat.sh /run.sh

# Install the supervisor process management tool to run both nginx and jetty
# Install the necessary packages to download and install Tomcat and Jenkins
# Clean up packages
RUN apt-get update && apt-get install -y --fix-missing --force-yes --no-install-recommends \
	git \
	wget \
	curl \
	zip \
	supervisor \
	unzip \
 	openjdk-7-jdk \
 	ca-certificates && \
	apt-get clean && \
	wget -q https://archive.apache.org/dist/tomcat/tomcat-${TOMCAT_MAJOR_VERSION}/v${TOMCAT_MINOR_VERSION}/bin/apache-tomcat-${TOMCAT_MINOR_VERSION}.tar.gz && \
	wget -qO- https://archive.apache.org/dist/tomcat/tomcat-${TOMCAT_MAJOR_VERSION}/v${TOMCAT_MINOR_VERSION}/bin/apache-tomcat-${TOMCAT_MINOR_VERSION}.tar.gz.md5 | md5sum -c - && \
	tar zxf apache-tomcat-*.tar.gz && \
	rm apache-tomcat-*.tar.gz && \
	mv apache-tomcat* tomcat && \
	chmod u+xwr /*.sh && \
	rm -rf /tomcat/webapps/* && \
	curl -L http://mirrors.jenkins-ci.org/war-stable/$JENKINS_VERSION/jenkins.war -o /tomcat/webapps/ROOT.war && \
	unzip /tomcat/webapps/ROOT.war -d /tomcat/webapps/ROOT && \
	apt-get purge -y \
	zip \
	unzip && \
	rm -rf /var/lib/apt/lists/* && \
	mkdir -p /tomcat/webapps/ROOT/ref/init.groovy.d && \
	mkdir -p /var/log/nginx/jenkins/


# Set the home folder for jenkins
ENV JENKINS_HOME /var/jenkins_home


# Add jenkins user
RUN useradd -d "$JENKINS_HOME" -u 1000 -m -s /bin/bash jenkins


# Add init file for setting the agent port for jnlp
ADD init.groovy /tomcat/webapps/ROOT/ref/init.groovy.d/tcp-slave-angent-port.groovy


# Add script for adding Jenkins plugins via text file
ADD download-plugins.sh /usr/local/bin/plugins.sh


# Add the text file containing the necessary plugins to be installed
ADD default_jenkins_plugins.txt /usr/share/jenkins/plugins.txt


# Execute the plugins.sh script against plugins.txt to install the necessary plugins
RUN /usr/local/bin/plugins.sh /usr/share/jenkins/plugins.txt && > /usr/share/jenkins/plugins.txt


# Add the default nginx configuration
ADD nginx.conf /etc/nginx/nginx.conf


# Add the default supervisor conf
ADD supervisord.conf /etc/supervisor/conf.d/supervisord.conf


# Add the job (seed job) that will build all the groovy defined jobs to the container
ADD groovy-dsl-job /var/tmp/groovy-dsl-job


# Add the script that will trigger the seed job
ADD build-groovy-jobs.sh /build-groovy-jobs.sh


# Port 50000 will be used by jenkins slave
# Port 8080 will be used for the Jenkins web interface
EXPOSE 8080 50000


# Run NGINX, Tomcat, plugins.sh (to install the plugins)
CMD ["/usr/bin/supervisord"]

