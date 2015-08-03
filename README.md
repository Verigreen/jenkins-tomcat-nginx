Jenkins on tomcat + nginx
=========================

A Jenkins docker image running on tomcat and nginx with a focus on enabling user configuration and automation.

## Usage

To run this jenkins container you may run the following command:

```bash
sudo docker run \
    -it \
    -p $PORT_FOR_JENKINS:8081 \
    -v path/to/config.yml:/config.yml
    -v path/to/jenkins_home:/jenkins_home
    verigreen/jenkins-tomcat-nginx
```

Where `config.yml` represents the configuration for each container instance

If you're behind a proxy, include the appropriate environment variables.

```bash
sudo docker run \
    -e http_proxy="http://my-proxy.myserver.com:8080/" \
    -e https_proxy="http://my-proxy.myserver.com:8080/" \
    -e HTTP_PROXY="http://my-proxy.myserver.com:8080/" \
    -e HTTPS_PROXY="http://my-proxy.myserver.com:8080/" \ 
    -e no_proxy="127.0.0.1, localhost" \
    -it \
    -p $PORT_FOR_JENKINS:8081 \
    -v path/to/config.yml:/config.yml
    -v path/to/jenkins_home:/jenkins_home
    verigreen/jenkins-tomcat-nginx
```

Here is an example of a simple Jenkins setup.

```yaml
##################################
# Use Jenkins' own user database #
##################################
hudson:
  disabledAdministrativeMonitors: ''
  version: '1.0'
  numExecutors: '2'
  mode: 'NORMAL'
  useSecurity: 'true'
  authorizationStrategy:
    attributes: 'login-authorization'
  securityRealm:
    attributes: 'database-authentication'
    disableSignup: 'true'
    enableCaptcha: 'false'
  disableRememberMe: 'false'
  projectNamingStrategy:
    attributes:
    - 'class=jenkins.model.ProjectNamingStrategy$DefaultProjectNamingStrategy'
  workspaceDir: '${ITEM_ROOTDIR}/workspace'
  buildsDir: '${ITEM_ROOTDIR}/builds'
  markupFormatter:
    attributes:
    - 'class=hudson.markup.EscapedMarkupFormatter'
  jdks: ''
  viewsTabBar:
    attributes:
    - 'class=hudson.views.DefaultViewsTabBar'
  myViewsTabBar:
    attributes:
    - 'class=hudson.views.DefaultMyViewsTabBar'
  clouds: ''
  slaves: ''
  scmCheckoutRetryCount: '0'
  views:
    hudson.model.AllView:
      owner:
        attributes:
        - 'class=hudson'
        - 'reference=../../..'
      name: 'All'
      filterExecutors: 'false'
      filterQueue: 'false'
      properties:
        attributes:
        - 'class="hudson.model.View$PropertyList'
  primaryView: 'All'
  slaveAgentPort: '0'
  label: ''
  nodeProperties: ''
  globalNodeProperties: ''
---
users:
  unhashed:
    - 'user1:password1'
    - 'user2:password2'
```

Then, from your host, you may access the jenkins UI at `localhost:$PORT_FOR_JENKINS`.

The `-p $PORT_FOR_JENKINS:8081` is *required* to map a host port to the port where jenkins is exposed in the container. The `-v path/to/jenkins_home:/var/jenkins_home` is *recommended* if you want to persist any configuration and data that happens during the execution of jenkins in that container instance. The `-v path/to/config.yml:/config.yml` is how each Jenkins instance is customized. The `-it` command runs the container interactively. To run the container in *detached* mode replace the `-it` option with `-d` or if it is already running press `CTRL`+`P` followed by `CTRL`+`Q` and it will detach.

The following is the complete list of mountable volumes that you may use for *customizing* `jenkins`, `nginx`, and/or `tomcat` to your needs:
```bash
sudo docker run \
    -d \
    --name $CONTAINER_NAME \
    -e ADMIN_PASSWORD=mysecretpass \
    -p $PORT_FOR_JENKINS:8081 \
    -v path/to/nginx.conf:/nginx.conf \
    -v path/to/supervisord.conf:/supervisord.conf \
    -v path/to/jenkins/log/directory/:/var/log/nginx/jenkins/ \
    -v path/to/supervisor/log/directory:/var/log/supervisor/ \
    -v path/to/sample_jobs.groovy:/jobs.groovy \
    -v path/to/jenkins_home:/jenkins_home \
    -v path/to/config.xml:/config.xml \
    jonathan/jenkins-nginx
```

## Configuration

### Migrating existing Jenkins

If you already have a jenkins instance you can migrate your existing data and configuration to be used with this container. To accomplish this, you must mount the JENKINS_HOME by adding the `-v /path/to/jenkins_home:/var/jenkins_home` to the `docker run` command. Your `/path/to/jenkins_home` should allow you to point the following assets:

1. **Existing jobs**: the jobs that you want to reuse and persist with this container should be located in your *host's* `/path/to/jenkins_home/jobs`. The jenkins running within the container will look for them in `/var/jenkins_home/jobs` during startup.

2. **Existing plugins**: the plugins that you want to reuse and persist with this container should be located in your *host's* `/path/to/jenkins_home/plugins`. The jenkins running within the container will look for them in `/var/jenkins_home/plugins`.

By default, the JENKINS_HOME is set to `~/.jenkins`. 

```bash
docker run \
  -d
  -p $PORT_FOR_JENKINS:8081
  -v `pwd`/.jenkins:/jenkins_home # Imported configuration
  verigreen/jenkins-tomcat-nginx
```

If you want to extract the configuration for your Jenkins to have programmatic control, [click here](docs/config_migration.md)

### The config.yml

The specification for the config.yml allows you to modify Jenkins' root configuration file. You can keep track of your Jenkins instance with a single clean/readable configuration file.

For a brief reference on how to structure Jenkins' config.xml, click [here](docs/jenkins_xml_reference.md)

Through the config.yml, you can also:

1. **Use aliases**: You may specify intuitive aliases for attributes when working with the root configuration file.

2. **Download and install plugins**: You may specify a list containing the name of the plugin and it's version. The container will then download the plugin and install it.

3. **Add users to Jenkins' internal database**: You may specify a list of user names and passwords. The container will proceed to encrypt the passwords and make the appropriate xml files for each user.

4. **Add SSL certificates**: You may be using an external service which requires secured communication, such as ldap. You may specify a list of servers in YAML file. The container will then download the appropriate certificate for each server in the list and will import them into the keystore.

5. **Run CLI commands**: You may have Jenkins run CLI commands on startup. Simply provide a list of commands in the config.yml.

```yaml
hudson:
  disabledAdministrativeMonitors: ''
  version: '1.596.2'
  numExecutors: '2'
  . . .
---
plugins: # 2. List of plugins 'PlUGIN:VERSION'
  - 'dockerhub:1.0'
  - 'token-macro:1.10'
---
users: # 3. List of users 'USERNAME:PASSWORD'
  unhashed:
    - 'user1:password1'
    - 'user2:password2'
---
certificates: # 4. List of certificates 'DOMAIN:PORT:CERTIFICATE'
  remote:
    - 'ldap.example1.net:636:1' # The third parameter let's you choose a specific certificate in the certificate chain
    - 'ldap.example2.com:636:1' # If unsure, leave it at `1`
---
commands: # 5. List of commands
  - echo 'jenkins.model.Jenkins.instance.securityRealm.createAccount("admin", "password")'
```

###Examples

#####Using Jenkins' database for authentication and authorization

```yaml
##################################
# Use Jenkins' own user database #
##################################
hudson:
  . . .
  securityRealm:
    attributes: 'database-authentication'
    disableSignup: 'true'
    enableCaptcha: 'false'
  authorizationStrategy:
    attributes: 'login-authorization'
  . . .
---
users:
  unhashed:
    - 'user1:password1'
    - 'user2:password2'
```

More [samples](docs/samples.md)

### Adding new plugins

Specify a list of plugins in the config.yml. The value of each list item should match the format <PLUGIN:VERSION>. This list has to be a 'separate document', meaning that you have to separate the list from the others with three dashes ("---"). The container will look for the plugin in http://updates.jenkins-ci.org/download/plugins, so make sure that what you are referencing appears on that list.

```yaml
.
.
.
---
plugins:
  - 'dockerhub:1.0'
  - 'token-macro:1.10'
```

More on [plugins](docs/plugins.md)

###Adding users programmatically
Specify a list of users in the config.yml in the format <USERNAME:PASSWORD>. This list has to be a 'separate document', meaning that you have to separate the list from the others with three dashes ("---"). The container will parse each list item from the list and create an XML file for each user.

```yaml
.
.
.
---
users:
  unhashed:
    - 'user1:password1'
    - 'user2:password2'
    - 'user3:password3'
    - 'user4:password4'
```

If security is a concern, you can provide a hashed password instead.

```bash
sudo docker run -ti --entrypoint="bash" verigreen/jenkins-tomcat-nginx pwencrypt
# Program will prompt for password
password: MY-PASSWORD
# Copy this into your config.yml
8e902968fe313800b53d00e89489ad6106c69f484a5d8a1589cf9f39a0d0e91b
```

```yaml
.
.
.
---
users:
  hashed: # Note the change from unhashed to hashed
    - 'user1:8e902968fe313800b53d00e89489ad6106c69f484a5d8a1589cf9f39a0d0e91b'
```

###Running commands in the Jenkins CLI
Jenkins has a built-in command line client that allows you to access Jenkins from a script or from your shell. This is convenient for automation of routine tasks, bulk updates, trouble diagnosis, and so on.

You can supply CLI commands to Jenkins listing the commands in the config.yml.

`cli.txt`
```yaml
.
.
.
---
commands:
  - echo 'jenkins.model.Jenkins.instance.securityRealm.createAccount("admin", "password")'
  - echo 'restart'
```

These commands will create a new user within Jenkins own user database and restart the server.

### Adding new jobs

In jenkins, it is possible to configure a job by creating custom XML files that describe the job. However, this container *supports* the use of the [Job DSL plugin](https://github.com/jenkinsci/job-dsl-plugin/wiki/Tutorial---Using-the-Jenkins-Job-DSL) by allowing the specification of jobs using a `groovy` DSL. Simply map the groovy script to the container's root directory `-v /path/to/sample_jobs.groovy:/var/tmp/jobs.groovy`.

We recommend that you take a look at the [tutorial](https://github.com/jenkinsci/job-dsl-plugin/wiki/Tutorial---Using-the-Jenkins-Job-DSL) for using the DSL plugin before attempting this.

Once you have written some jobs, add them to `/path/to/sample_jobs.groovy` file. It is *required* that the file ends with `.groovy` extension. It should look something similar to the following:

```groovy
// Example of sample_jobs.groovy
job('NAME-groovy') { //To separate groovy jobs from other, please add the *-groovy to your groovy defined job
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

