#Plugin limit

While there is no limit to how many plugins you can specify in the config.yml,

```yaml
---
plugins: # 2. List of plugins 'PlUGIN:VERSION'
  - 'plugin1:1.0'
  - 'plugin2:1.0'
  - 'plugin3:1.0'
  - 'plugin4:1.0'
  - 'plugin5:1.0'
  - 'plugin6:1.0'
  - 'plugin7:1.0'
```

Adding too many may delay the container's startup time, since it needs to download every plugin before booting Tomcat.

You can bypass this drawback by creating your own image, using this one as base.

```bash
FROM verigreen/jenkins-tomcat-nginx

# Add the text file containing the necessary plugins to be installed
ADD default_jenkins_plugins.txt /usr/share/jenkins/plugins.txt


# Execute the plugins.sh script against plugins.txt to install the necessary plugins
RUN /usr/local/bin/plugins.sh /usr/share/jenkins/plugins.txt && > /usr/share/jenkins/plugins.txt
```

You will have to create a `default_jenkins_plugins.txt` in the Dockerfile's directory.

`default_jenkins_plugins.txt`
```bash
plugin1:1.0
plugin2:1.0
plugin3:1.0
plugin4:1.0
plugin5:1.0
plugin6:1.0
plugin7:1.0
```

Alternatively, you may build the `verigreen/jenkins-tomcat-nginx` image yourself. Just make sure to modify the `default_jenkins_plugins.txt`.