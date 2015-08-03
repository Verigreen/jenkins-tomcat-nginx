#####Provisioning slaves with the Docker Plugin

Here we use the [docker plugin](https://wiki.jenkins-ci.org/display/JENKINS/Docker+Plugin) to dynamically provision slaves using a Docker host.

First, you should have Docker installed in the slave nodes. After [installing docker](https://docs.docker.com/installation/ubuntulinux/), you will need to tell the Daemon to listen on port 4243. You can do this by modifying the default parameters on startup, see **[On Demand Jenkins Slaves Using Docker](https://developer.jboss.org/people/pgier/blog/2014/06/30/on-demand-jenkins-slaves-using-docker?_sscc=t)**. Finally, pull the plugin's docker image.

**Implementation steps**

Make docker host listen to port

`sudo service docker stop`

Now edit Docker’s upstart file at /etc/default/docker so it looks like this:

```bash
# Docker Upstart and SysVinit configuration file

# Customize location of Docker binary (especially for development testing).
#DOCKER="/usr/local/bin/docker"

# Use DOCKER_OPTS to modify the daemon startup options.
#DOCKER_OPTS="--dns 8.8.8.8 --dns 8.8.4.4"
DOCKER_OPTS="-H tcp://0.0.0.0:4243 -H unix:///var/run/docker.sock"  # MODIFIED
# If you need Docker to use an HTTP proxy, it can also be specified here.
#export http_proxy="http://127.0.0.1:3128/"
# This is also a handy place to tweak where Docker's temporary files go.
#export TMPDIR="/mnt/bigdrive/docker-tmp"
```

Also, if your vm goes through a proxy; add it to /etc/default/docker
```bash
export http_proxy="http://<your-proxy-host-ip-and-port>/"
```

then

`sudo service docker start`

and Docker will be listening on por 4243

1. while in your slaves, pull the plugin's docker image, `sudo docker pull evarga/jenkins-slave`.

2. Include the docker-plugin (and it's dependencies) in the config.yml of your Master.

3. Modify the `com.nirima.jenkins.plugins.docker.DockerCloud-*` tags (in the `clouds` tag) to match your details. 

4. Run the Master.

```yml
hudson:
  authorizationStrategy:
    attributes:
    - class=hudson.security.AuthorizationStrategy$Unsecured
  buildsDir: ${ITEM_ROOTDIR}/builds
  clouds:
    com.nirima.jenkins.plugins.docker.DockerCloud-1: # First Node
      attributes:
      - plugin=docker-plugin@0.9.3
      connectTimeout: '50'
      containerCap: '5'
      credentialsId: ''
      name: ANYNAME
      readTimeout: '150'
      serverUrl: http://my-slave2:4243 # Url of node
      templates:
        com.nirima.jenkins.plugins.docker.DockerTemplate:
          bindAllPorts: 'false'
          bindPorts: ''
          credentialsId: 6504ac81-34vg3t4-4654-9714-343545f34 # Default credentials for the `evarga/jenkins-slave` image. 
          dnsHosts: ''
          dockerCommand: ''
          environment: ''
          hostname: ''
          idleTerminationMinutes: '5'
          image: evarga/jenkins-slave # Docker image in First Node
          instanceCap: '5'
          javaPath: ''
          jvmOptions: ''
          labelString: ''
          lxcConfString: ''
          mode: EXCLUSIVE
          numExecutors: '1'
          prefixStartSlaveCmd: ''
          privileged: 'false'
          remoteFs: /home/jenkins
          remoteFsMapping: ''
          sshLaunchTimeoutMinutes: '1'
          suffixStartSlaveCmd: ''
          tty: 'false'
          volumes: ''
          volumesFrom2: ''
      version: 1.7.0
    com.nirima.jenkins.plugins.docker.DockerCloud-2: # Second Node
      attributes:
      - plugin=docker-plugin@0.9.3
      connectTimeout: '50'
      containerCap: '5'
      credentialsId: ''
      name: ANYNAME2
      readTimeout: '150'
      serverUrl: http://my-slave1:4243
      templates:
        com.nirima.jenkins.plugins.docker.DockerTemplate:
          bindAllPorts: 'false'
          bindPorts: ''
          credentialsId: 34t3v4t-4f69-3v4tv4-9817-505cea27717b
          dnsHosts: ''
          dockerCommand: ''
          environment: ''
          hostname: ''
          idleTerminationMinutes: '5'
          image: jenkins_slave
          instanceCap: '5'
          javaPath: ''
          jvmOptions: ''
          labelString: ''
          lxcConfString: ''
          mode: NORMAL
          numExecutors: '1'
          prefixStartSlaveCmd: ''
          privileged: 'false'
          remoteFs: /home/jenkins
          remoteFsMapping: ''
          sshLaunchTimeoutMinutes: '1'
          suffixStartSlaveCmd: ''
          tty: 'false'
          volumes: ''
          volumesFrom2: ''
      version: 1.7.0
  disableRememberMe: 'false'
  disabledAdministrativeMonitors: ''
  globalNodeProperties: ''
  jdks: ''
  label: ''
  markupFormatter:
    attributes:
    - class=hudson.markup.EscapedMarkupFormatter
  mode: EXCLUSIVE
  myViewsTabBar:
    attributes:
    - class=hudson.views.DefaultMyViewsTabBar
  nodeProperties: ''
  numExecutors: '2'
  primaryView: All
  projectNamingStrategy:
    attributes:
    - class=jenkins.model.ProjectNamingStrategy$DefaultProjectNamingStrategy
  quietPeriod: '5'
  scmCheckoutRetryCount: '0'
  securityRealm:
    attributes:
    - class=hudson.security.SecurityRealm$None
  slaveAgentPort: '0'
  slaves: ''
  useSecurity: 'true'
  version: 1.596.2
  views:
    hudson.model.AllView:
      filterExecutors: 'false'
      filterQueue: 'false'
      name: All
      owner:
        attributes:
        - class=hudson
        - reference=../../..
  viewsTabBar:
    attributes:
    - class=hudson.views.DefaultViewsTabBar
  workspaceDir: ${ITEM_ROOTDIR}/workspace
---
plugins:
  - 'docker-plugin:0.9.3'
  - 'durable-task:0.5'
  - 'token-macro:1.7'
  - 'ssh-slaves:1.6'
```


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

#####Using Jenkins' database for authentication and authorization (with matrix authorization)

```yaml
###################
#DATABASE + MATRIX#
###################
hudson:
  . . .
  securityRealm:
    attributes: 'database-authentication'
    disableSignup: 'true'
    enableCaptcha: 'false'
  authorizationStrategy:
    attributes: 'matrix-authorization'
    permissions:
      - 'overall-administer:user1'
      - 'overall-configure-update-center:user1'
      - 'overall-read:user1'
      - 'overall-run-scripts:user1'
      - 'overall-upload-plugins:user1'
  . . .
---
users:
  unhashed:
    - 'user1:password1' # Has all privileges
    - 'user2:password2' # User has no privileges
```

#####Using LDAP authentication with basic login authorization

```yaml
##############
#LDAP + LOGIN#
##############
hudson:
  . . .
  securityRealm:
    attributes: 'ldap-authentication'
    # attributes:
    #   - 'class=hudson.security.LDAPSecurityRealm'
    #   - 'plugin=ldap@1.6'
    server: 'ldap://ldap.example.com:636'
    rootDN: 'OU=users,DC=example,DC=net'
    inhibitInferRootDN: ''
    userSearchBase: ''
    userSearch: 'sAMAccountName={0}'
    groupSearchBase: ''
    groupSearchFilter: ''
    managerDN: 'CN=example@main.com,DC=example,DC=net'
    managerPassword: 'MANAGER_PASSWORD'
    disableMailAddressResolver: ''
  authorizationStrategy:
    attributes: 'login-authorization'
  . . .
---
certificates: # 4. List of certificates 'DOMAIN:PORT:CERTIFICATE'
  remote:
    - 'ldap.example.net:636:1' # The third parameter let's you choose a specific certificate in the certificate chain
```

#####Using LDAP authentication with matrix authorization

```yaml
###############
#LDAP + MATRIX#
###############
hudson:
  . . .
  securityRealm:
    attributes: 'ldap-authentication'
    # attributes:
    #   - 'class=hudson.security.LDAPSecurityRealm'
    #   - 'plugin=ldap@1.6'
    server: 'ldap://ldap.example.com:636'
    rootDN: 'OU=users,DC=example,DC=net'
    inhibitInferRootDN: ''
    userSearchBase: ''
    userSearch: 'sAMAccountName={0}'
    groupSearchBase: ''
    groupSearchFilter: ''
    managerDN: 'CN=example@main.com,DC=example,DC=net'
    managerPassword: 'MANAGER_PASSWORD'
    disableMailAddressResolver: ''
  authorizationStrategy:
    attributes: 'matrix-authorization'
    permissions:
      - 'overall-read:example2@mail.com' # User example2@mail.com will only have read permission
  . . .
```


