# !/usr/bin/env python
"""
Author: Jonathan Rosado Lugo
Email: jonathan.rosado-lugo@hp.com


Description:
        General script for parsing YAML lists and key value pairs 

Dependencies:
    -PyYaml

Input:

hudson:
  securityRealm:
    attributes: 'database-authentication'
    disableSignup: 'true'
    enableCaptcha: 'false'
  authorizationStrategy:
    attributes: 'login-authorization'

users:
  unhashed:
    - 'user1:password1'
    - 'user2:password2'
  hashed:
    - 'user3:7ca1aab96fc6b8bcf8de0b83423fad2dde8d6bc8c12e9c31ef058322e7e4ed02'

plugins:
  - 'durable-task:1.5'
  - 'docker-plugin:0.9.1'

Ouput:

/hudson/authorizationStrategy/attributes|login-authorization
/hudson/securityRealm/attributes|database-authentication
/hudson/securityRealm/enableCaptcha|false
/hudson/securityRealm/disableSignup|true
/users/hashed|['user3:7ca1aab96fc6b8bcf8de0b83423fad2dde8d6bc8c12e9c31ef058322e7e4ed02']
/users/unhashed|['user1:password1', 'user2:password2']
/plugins|['durable-task:1.5', 'docker-plugin:0.9.1']

"""

import sys
import types
import yaml
import copy


def dispatch(yamlObject):

    def cycle(obj, nodePath):
        if type(obj) == types.DictType:
            for key, value in obj.iteritems():
                patch = copy.copy(nodePath) # We need a true copy; pointers to objects won't work
                patch.append('/' + key)
                if type(value) == types.StringType or type(value) == types.BooleanType or type(value) == types.ListType:
                    print ''.join(patch) + '|' + value.__str__()
                else:
                    cycle(value, patch)
        else:
            sys.exit('RUN: Invalid value type reached PATH: ' + nodePath.__str__())

    cycle(yamlObject, [])

    return


def main():
    args = sys.argv[1:]

    inYamlFile = args[0]

    for yamlObject in yaml.load_all(open(inYamlFile)):
        dispatch(yamlObject)


if __name__ == '__main__':
    main()

# Breaks when yaml goes back to previous levels
# def dispatch(yamlObject):
#
#     def cycle(obj, nodePath):
#         if type(obj) == types.DictType:
#             for key, value in obj.iteritems():
#                 nodePath.append('/' + key)
#                 if type(value) == types.StringType or type(value) == types.BooleanType or type(value) == types.ListType:
#                     print ''.join(nodePath) + '|' + value.__str__()
#                     nodePath = nodePath[:-1]
#                 else:
#                     cycle(value, nodePath)
#         else:
#             sys.exit('RUN: Invalid value type reached')
#
#     cycle(yamlObject, [])
#
#     return