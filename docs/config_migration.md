#Migrating to root configuration

You can convert your root config.xml into yaml by feeding the xml to a parser inside the container.

```bash
docker run \
  -ti \
  -v `pwd`/config.xml:/config.xml \
  --entrypoint="bash" \
  verigreen/jenkins-tomcat-nginx -c "python xml2yaml.py config.xml" > config.yml
```

If you now look at the content of `config.yml`, you should see your configuration in yaml.

```yaml
hudson:
  authorizationStrategy:
    attributes:
    - class=hudson.security.AuthorizationStrategy$Unsecured
  buildsDir: ${ITEM_ROOTDIR}/builds
  clouds: ''
  disableRememberMe: 'false'
  disabledAdministrativeMonitors: ''
  .
  .
  .
  .
```

#Migrating to JobDSL

Having your jobs in groovy (as opposed to xml in JENKINS_HOME) allows you to make simple modifications without having to go through the UI.

We provide a tool for converting your jobs into JobDSL format.

Simply mount the job directory ($JENKINS_HOME/jobs/test_job) as a volume and run the `xml2jobDSL.py` script against it.

```bash
docker run \
  -ti \
  -v `pwd`/test_job:/test_job \
  --entrypoint="bash" \
  verigreen/jenkins-tomcat-nginx -c "python xml2jobDSL.py test_job" > myjob.groovy
```

In `myjob.groovy` you should see your job translated.

```groovy
job('test_job-groovy') {
	configure {
		(it/'actions').value = 'None'
		(it/'logRotator'(class: 'hudson.tasks.LogRotator')/'daysToKeep').value = '-1'
		(it/'logRotator'(class: 'hudson.tasks.LogRotator')/'numToKeep').value = '10'
		(it/'logRotator'(class: 'hudson.tasks.LogRotator')/'artifactDaysToKeep').value = '-1'
		(it/'logRotator'(class: 'hudson.tasks.LogRotator')/'artifactNumToKeep').value = '10'
		(it/'keepDependencies').value = 'false'
		.
		.
		.
		.
	}
}
```

Due to some limitations of the JobDSL plugin, some of the values might not be affected by the `configure {}` block. Please see the [documentation](https://github.com/jenkinsci/job-dsl-plugin/wiki) if you haven't already.