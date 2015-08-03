#! /bin/bash

IMAGE_NAME="jonathan0119/main-configuration-fixed-jenki"
CONTAINER_NAME="deleteme"
echo "
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
        - 'class=hudson.model.View$PropertyList'
  primaryView: 'All'
  slaveAgentPort: '0'
  label: ''
  nodeProperties: ''
  globalNodeProperties: ''
---
users:
  unhashed:
    - 'user1:password1'
  hashed:
    - 'user2:86484f84ac63058d39a08cb22e063edf00c86a04183c23debc33bf0687a4ee78'
#---
#certificates:
#  remote:
#    - 'ldap.example.com:636:2'
---
plugins:
  - 'flow:1.3'
" > config.yml

sudo docker run \
	-d \
	--name deleteme \
	-p 8081:8080 \
	-v `pwd`/config.yml:/config.yml \
	-v `pwd`/jenkins_home:/jenkins_home \
	jonathan0119/main-configuration-fixed-jenki

sudo python test_main.py ${CONTAINER_NAME}

sudo docker rm -f deleteme

sudo rm -f config.yml

sudo rm -fr jenkins_home