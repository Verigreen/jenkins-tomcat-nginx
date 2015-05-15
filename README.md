Jenkins on tomcat + nginx
=========================

A Jenkins docker image running on tomcat and nginx with a focus on enabling user configuration and automation.

## Usage

To run this jenkins container you may the following command:

```
sudo docker run \
	-it \
	-p $PORT_FOR_JENKINS:8081 \
	-v path/to/jenkins_home:/var/jenkins_home \
	verigreen/jenkins-tomcat-nginx
```

Then, from your host, you may access the jenkins UI at `localhost:$PORT_FOR_JENKINS`. 

The `-p $PORT_FOR_JENKINS:8081` is *required* to map a host port to the port where jenkins is exposed in the container. The `-v path/to/jenkins_home:/var/jenkins_home` is *recommended* if you want to persist any configuration and data that happens during the execution of jenkins in that container instance. The `-it` command runs the container interactively. To run the container in *detached* mode replace the `-it` option with `-d` or if it is already running press `CTRL`+`P` followed by `CTRL`+`Q` and it will detach.

The following is the complete list of mountable volumes that you may use for *customizing* `jenkins`, `nginx`, and/or `tomcat` to your needs:

```
sudo docker run \
	-d \
	--name $CONTAINER_NAME \
	-p $PORT_FOR_JENKINS:8081 \
	-v /path/to/nginx.conf:/etc/nginx/nginx.conf:ro \
	-v /path/to/supervisord.conf:/etc/supervisor/conf.d/supervisord.conf:ro \
	-v /path/to/jenkins/log/directory/:/var/log/nginx/jenkins \
	-v /path/to/supervisor/log/directory:/var/log/supervisor \
	-v /path/to/plugins.txt:/usr/share/jenkins/plugins.txt \
	-v /path/to/sample_jobs.groovy:/var/tmp/jobs.groovy \
	-v /path/to/jenkins_home:/var/jenkins_home \
	jonathan/jenkins-nginx
```

## Configuration

### Migrating existing Jenkins

If you already have a jenkins instance you can migrate your existing data and configuration to be used with this container. To accomplish this, you must add the `-v /path/to/jenkins_home:/var/jenkins_home` to the `docker run` command. Your `/path/to/jenkins_home` should allow you to point the following assets:

1. **Existing jobs**: the jobs that you want to reuse and persist with this container should be located in your *host's* `/path/to/jenkins_home/jobs`. The jenkins running within the container will look for them in `/var/jenkins_home/jobs` during startup.

2. **Existing plugins**: the plugins that you want to reuse and persist with this container should be located in your *host's* `/path/to/jenkins_home/plugins`. The jenkins running within the container will look for them in `/var/jenkins_home/plugins`.


### Adding new plugins

#### Using `plugins.txt`

You may add new plugins to be *installed automatically* during the setup of your container during `docker run` by mapping the `-v /path/to/plugins.txt:/usr/share/jenkins/plugins.txt` volume. Before running the container, you need to create a file in your host called `/path/to/plugins.txt` and add each plugin in a separate line with the following format: `plugin:version`. Here is an example:

```
# /path/to/plugins.txt
dockerhub:1.0
disk-usage:0.25
job-dsl:1.30
token-macro:1.10
```

> Note that you must have a valid internet connection to be able to download
> the plugins to the container's volume.
> 
> Also, make sure the plugin you want to install is referenced in this list 
> http://updates.jenkins-ci.org/download/plugins

You may also add new plugins to the `/path/to/plugins.txt` and restart the container. The setup script will download the new plugins only.

#### Copying `*.jpi` and `*.hpi` packages

Yoy may also copy manually jenkins plugins that are packed as `<plugin-name>.jpi` or `<plugin-name>.hpi` into the `/path/to/jenkins_home/plugins` and then `run` or `restart` your jenkins container.

### Adding new jobs

In jenkins, it is possible to configure a job by creating custom XML files that describe the job. However, this container *supports* the use the [Job DSL plugin](https://github.com/jenkinsci/job-dsl-plugin/wiki/Tutorial---Using-the-Jenkins-Job-DSL) by allowing the specification of jobs using a `groovy` DSL and adding mapping those jobs to the container at runtime using the `-v /path/to/sample_jobs.groovy:/var/tmp/jobs.groovy` volume mapping.

We recommend that you take a look at the [tutorial](https://github.com/jenkinsci/job-dsl-plugin/wiki/Tutorial---Using-the-Jenkins-Job-DSL) for using the DSL plugin before attempting this.

Once you have written some plugins, add them to `/path/to/sample_jobs.groovy` file. It is *required* that the file ends with `.groovy` extension. It should look something similar to the following:

```groovy
// Example of sample_jobs.groovy
job('NAME-groovy') { //for the script's sake, please add the *-groovy to your groovy defined job
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
```

When you are done, `run` or `restart` your container. The setup script will inspect the `/var/tmp/jobs.groovy` file and install them correctly by setting up the Job DSL plugin and performing some requests on Jenkins.

### Configuring `nginx`

We use nginx to serve jenkins' static files. You may customize its configuration by writing your own `nginx.conf` and mapping it to the container using the `-v /path/to/nginx.conf:/etc/nginx/nginx.conf:ro` volume mapping. We recommend that you use the included `nginx.conf` as a starting point. You must `run` or `restart` the container after modifications are done to pick up any changes.

### Configuring `supervisord`

We use a process management tool called Supervisor (http://docs.docker.com/articles/using_supervisord/) to better handle our multi-process container. You may customize it by writing your own `supervisord.conf` configuration file and mapping it to the container using `-v /path/to/supervisord.conf:/etc/supervisor/conf.d/supervisord.conf:ro` volume mapping.  We recommend that you use the included `supervisord.conf` as a starting point. You must `run` or `restart` the container after modifications are done to pick up any changes.