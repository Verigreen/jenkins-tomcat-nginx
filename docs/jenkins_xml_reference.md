#Config.xml

The root `config.xml` holds the actual state of Jenkins. It has all the configuration regarding security, version, views, slaves, etc.

You can find the root `config.xml` in your `$JENKINS_HOME`.

```
JENKINS_HOME
 +- config.xml     (jenkins root configuration)
 +- *.xml          (other site-wide configuration files)
 +- userContent    (files in this directory will be served under your http://server/userContent/)
 +- fingerprints   (stores fingerprint records)
 +- plugins        (stores plugins)
 +- jobs
     +- [JOBNAME]      (sub directory for each job)
         +- config.xml     (job configuration file)
         +- workspace      (working directory for the version control system)
         +- latest         (symbolic link to the last successful build)
         +- builds
             +- [BUILD_ID]     (for each build)
                 +- build.xml      (build result summary)
                 +- log            (log file)
                 +- changelog.xml  (change log)
```

Some familiarity with the root configuration file might prove useful when configuring your new Jenkins intance programmatically.

For a complete reference, visit the [Jenkins-ci](https://wiki.jenkins-ci.org/display/JENKINS/Administering+Jenkins) website.

Heres a complete config.xml with default values:
```xml
<?xml version='1.0' encoding='UTF-8'?>
<hudson>
  <disabledAdministrativeMonitors/>
  <version>1.0</version>
  <numExecutors>2</numExecutors>
  <mode>NORMAL</mode>
  <useSecurity>true</useSecurity>
  <authorizationStrategy class="hudson.security.AuthorizationStrategy$Unsecured"/>
  <securityRealm class="hudson.security.SecurityRealm$None"/>
  <disableRememberMe>false</disableRememberMe>
  <projectNamingStrategy class="jenkins.model.ProjectNamingStrategy$DefaultProjectNamingStrategy"/>
  <workspaceDir>${ITEM_ROOTDIR}/workspace</workspaceDir>
  <buildsDir>${ITEM_ROOTDIR}/builds</buildsDir>
  <markupFormatter class="hudson.markup.EscapedMarkupFormatter"/>
  <jdks/>
  <viewsTabBar class="hudson.views.DefaultViewsTabBar"/>
  <myViewsTabBar class="hudson.views.DefaultMyViewsTabBar"/>
  <clouds/>
  <slaves/>
  <scmCheckoutRetryCount>0</scmCheckoutRetryCount>
  <views>
    <hudson.model.AllView>
      <owner class="hudson" reference="../../.."/>
      <name>All</name>
      <filterExecutors>false</filterExecutors>
      <filterQueue>false</filterQueue>
      <properties class="hudson.model.View$PropertyList"/>
    </hudson.model.AllView>
  </views>
  <primaryView>All</primaryView>
  <slaveAgentPort>0</slaveAgentPort>
  <label></label>
  <nodeProperties/>
  <globalNodeProperties/>
</hudson>
```
###Authentication
####Ldap
```xml
...
<mode>...</mode>
<useSecurity>...</useSecurity>
<authorizationStrategy .../>
<securityRealm class="hudson.security.LDAPSecurityRealm" plugin="ldap@1.6">
    <server>ldap://ldap.example.com</server>
    <rootDN>ou=People,O=example</rootDN>
    <inhibitInferRootDN>false</inhibitInferRootDN>
    <userSearchBase></userSearchBase>
    <userSearch>uid={}</userSearch>
    <groupSearchBase>groupAttr</groupSearchBase>
    <groupSearchFilter>groupAttr=100</groupSearchFilter>
    <managerDN>cn=john.doe@example.com,ou=people,o=example</managerDN>
    <managerPassword>bG9s</managerPassword>
    <disableMailAddressResolver>false</disableMailAddressResolver>
</securityRealm>
...
```
The values provided in the snippet should serve as a clue as to how to format your own.

The value for `<managerPassword>` is base64 encoded. This is how Jenkins stores passwords and it is how it'll read them.


####Jenkins’ own user database
```xml
...
<mode>...</mode>
<useSecurity>...</useSecurity>
<authorizationStrategy .../>
<securityRealm class="hudson.security.HudsonPrivateSecurityRealm">
    <disableSignup>false</disableSignup>
    <enableCaptcha>false</enableCaptcha>
</securityRealm>
...
```
####Unix user/group database
```xml
...
<mode>...</mode>
<useSecurity>...</useSecurity>
<authorizationStrategy .../>
<securityRealm class="hudson.security.PAMSecurityRealm" plugin="pam-auth@1.1">
    <serviceName>sshd</serviceName>
</securityRealm>
...
```
###Authorization
####Anyone can do anything
```xml
...
<numExecutors>...</numExecutors>
<mode>...</mode>
<useSecurity>true</useSecurity>
<authorizationStrategy class="hudson.security.AuthorizationStrategy$Unsecured"/>
<securityRealm .../>
<disableRememberMe>...</disableRememberMe>
...
```
####Legacy mode
```xml
...
<numExecutors>...</numExecutors>
<mode>...</mode>
<useSecurity>true</useSecurity>
<authorizationStrategy class="hudson.security.LegacyAuthorizationStrategy"/>
<securityRealm .../>
<disableRememberMe>...</disableRememberMe>
...
```
####Logged-in users can do anything
```xml
...
<numExecutors>...</numExecutors>
<mode>...</mode>
<useSecurity>true</useSecurity>
<authorizationStrategy class="hudson.security.FullControlOnceLoggedInAuthorizationStrategy"/>
<securityRealm .../>
<disableRememberMe>...</disableRememberMe>
...
```
####Matrix-based security
Here we give `Anonymous`  reading privileges and we give `User1` full control.
```xml
...
<numExecutors>...</numExecutors>
<mode>...</mode>
<useSecurity>true</useSecurity>
<authorizationStrategy class="hudson.security.ProjectMatrixAuthorizationStrategy">
    <permission>com.cloudbees.plugins.credentials.CredentialsProvider.Create:user1</permission>
    <permission>com.cloudbees.plugins.credentials.CredentialsProvider.Delete:user1</permission>
    <permission>com.cloudbees.plugins.credentials.CredentialsProvider.ManageDomains:user1</permission>
    <permission>com.cloudbees.plugins.credentials.CredentialsProvider.Update:user1</permission>
    <permission>com.cloudbees.plugins.credentials.CredentialsProvider.View:user1</permission>
    <permission>hudson.model.Computer.Build:user1</permission>
    <permission>hudson.model.Computer.Configure:user1</permission>
    <permission>hudson.model.Computer.Connect:user1</permission>
    <permission>hudson.model.Computer.Create:user1</permission>
    <permission>hudson.model.Computer.Delete:user1</permission>
    <permission>hudson.model.Computer.Disconnect:user1</permission>
    <permission>hudson.model.Hudson.Administer:user1</permission>
    <permission>hudson.model.Hudson.ConfigureUpdateCenter:user1</permission>
    <permission>hudson.model.Hudson.Read:anonymous</permission>
    <permission>hudson.model.Hudson.Read:user1</permission>
    <permission>hudson.model.Hudson.RunScripts:user1</permission>
    <permission>hudson.model.Hudson.UploadPlugins:user1</permission>
    <permission>hudson.model.Item.Build:user1</permission>
    <permission>hudson.model.Item.Cancel:user1</permission>
    <permission>hudson.model.Item.Configure:user1</permission>
    <permission>hudson.model.Item.Create:user1</permission>
    <permission>hudson.model.Item.Delete:user1</permission>
    <permission>hudson.model.Item.Discover:user1</permission>
    <permission>hudson.model.Item.Read:user1</permission>
    <permission>hudson.model.Item.Workspace:user1</permission>
    <permission>hudson.model.Run.Delete:user1</permission>
    <permission>hudson.model.Run.Update:user1</permission>
    <permission>hudson.model.View.Configure:user1</permission>
    <permission>hudson.model.View.Create:user1</permission>
    <permission>hudson.model.View.Delete:user1</permission>
    <permission>hudson.model.View.Read:user1</permission>
    <permission>hudson.scm.SCM.Tag:user1</permission>
</authorizationStrategy>
<securityRealm .../>
<disableRememberMe>...</disableRememberMe>
...
```