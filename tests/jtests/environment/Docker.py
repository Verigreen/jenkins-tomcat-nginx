from docker import Client

class Docker:
    def __init__(self, client_url='unix://var/run/docker.sock', client_version='auto', timeout=50, client_tls=False):
        self.client = Client(base_url=client_url, version=client_version, tls=client_tls)

        self.all_containers = self.client.containers()

        self.attached_container = self.all_containers[0]['Id']

    def container_has_file(self, file_name, path="/"):
        has_file = False

        bash_command = "find %s -maxdepth 1 -type f" % path

        exec_id = self.client.exec_create(self.attached_container, bash_command)

        files_in_container = self.client.exec_start(exec_id['Id'])

        files_in_container = files_in_container.split('\n')

        for i in files_in_container:
            if file_name in i.split('/'):
                has_file = True

        return has_file

    def container_has_dir(self, dir_name, path="/"):
        has_dir = False

        bash_command = "find %s -maxdepth 1 -type d" % path

        exec_id = self.client.exec_create(self.attached_container, bash_command)

        dirs_in_container = self.client.exec_start(exec_id['Id'])

        dirs_in_container = dirs_in_container.split('\n')

        for i in dirs_in_container:
            if dir_name in i.split('/'):
                has_dir = True

        return has_dir

    def attach_container(self, id):
        self.attached_container = id