import sys
from jtests.functionality.Web import Web
from jtests.environment.Docker import Docker

"""
Configuration
"""
docker_run_name = sys.argv[1]

"""
Tests
"""
# Check if Jenkins is running
web_page = Web('http://localhost:8081', ignore_validity=True)
web_page.wait_for(html="log in")


# Check unhashed credentials
login_data = {'j_username': 'user1', 'j_password': 'password1', 'from': '/', \
              'json': '{"j_username": "user1", "j_password": "password1", "remember_me": true, \
              "from": "/"}', 'Submit': 'log in'}

web_page.login('/j_acegi_security_check', login_data)

assert web_page.go_to('/manage'), "Could not connect to /manage" # Only user1/user2 can access /manage

assert web_page.has('Configure global settings and paths.'), "Expected html in /manage not found"


# Check hashed credentials
login_data = {'j_username': 'user2', 'j_password': 'password2', 'from': '/',\
              'json': '{"j_username": "user2", "j_password": "password2", "remember_me": true, \
              "from": "/"}', 'Submit': 'log in'}

web_page.login('/j_acegi_security_check', login_data)

assert web_page.go_to('/manage'), "Could not connect to /manage"

assert web_page.has('Configure global settings and paths.'), "Expected html in /manage not found"


# Check if plugin is loaded
assert web_page.go_to('/pluginManager/installed'), "Could not connect to /pluginManager/installed"

assert web_page.has('FLOW Plugin'), "Flow plugin not found in web page"


# Check files in container
docker = Docker()
docker.attach_container(docker_run_name)

assert docker.container_has_file('config.yml'), "Config.yml not found in container"

assert docker.container_has_file('config.xml'), "Config.yml not found in container"

assert docker.container_has_dir('jenkins_home'), "Jenkins_home not found in container"

assert docker.container_has_dir('user1', '/var/jenkins_home/users'), "user1 not found in container"

assert docker.container_has_dir('user2', '/var/jenkins_home/users'), "user2 not found in container"

assert docker.container_has_file('flow.jpi', '/var/jenkins_home/plugins'), "Flow.jpi not found in container"

print 'All test passed'