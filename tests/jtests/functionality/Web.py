import requests
import urllib
import lxml.html
import time

class Web:
    """ Test the functionality of a web application """

    def __init__(self, web_url, ignore_validity=False):
        """
        :param web_url: Full URL of website.
        :return: n/a
        """
        # Base will never be modified
        self.base = web_url
        # Includes routes, will be modified
        self.url = web_url
        self.ignore_valid = ignore_validity
        self.session = requests.Session()

        # Request will crash when the connection is refused
        try:
            self.__status = self.session.get(self.base).status_code
            self.__headers = self.session.get(self.base).headers
            self.__encoding = self.session.get(self.base).encoding
            self.__text = self.session.get(self.base).text
            self.__json = self.session.get(self.base).json
            self.__links = self.__get_links()
        except Exception:
            if not self.ignore_valid:
                print "Connection to %s couldn't be established" % self.base
                exit(1)
            self.__status = ''
            self.__headers = ''
            self.__encoding = ''
            self.__text = ''
            self.__json = ''
            self.__links = ''

    def __get_links(self):
        """
        Gets hyperlinks found in current page
        :return: List of hyperlinks in current url.
        """
        connection = urllib.urlopen(self.url)

        dom = lxml.html.fromstring(connection.read())

        links = []

        for link in dom.xpath('//a/@href'):
            links.append(link)

        return links

    def __reload(self):
        """
        Get the current page's status, headers, enconding, text, json, and links
        :return: n/a
        """
        # Request will crash when the connection is refused
        try:
            self.__status = self.session.get(self.url).status_code
            self.__headers = self.session.get(self.url).headers
            self.__encoding = self.session.get(self.url).encoding
            self.__text = self.session.get(self.url).text
            self.__json = self.session.get(self.url).json
            self.__links = self.__get_links()
        # TODO: catch connection_refused
        except Exception:
            if not self.ignore_valid:
                print "Connection to %s couldn't be established" % self.base
                exit(1)
            self.__status = ''
            self.__headers = ''
            self.__encoding = ''
            self.__text = ''
            self.__json = ''
            self.__links = ''

    def check_route(self, route=""):
        """
        Check if route is valid. It differs from exists() in that it will always
        append the route to the base_url
        :param route: Route to page.
        :return: True is the route is up and valid; False, otherwise.
        """
        page_is_ok = True

        # Request will crash when the connection is refused
        try:
            __status = self.session.get(self.base + route).status_code
        except Exception:
            page_is_ok = False
            __status = 520

        if 600 > __status > 399:
            page_is_ok = False

        return page_is_ok

    # TODO: change the substring lookup to a regex
    def wait_for(self, status_code=0, html='', time_in_seconds=120):
        """
        Waits for a page to have a given status or html
        :param status_code: Status code to wait for.
        :param html: Html text to wait for. Example "<b>I'm here</b>"
        :return: n/a
        """
        start = time.time()
        if status_code:
            while self.__status != status_code:
                elapsed_time = time.time() - start
                assert elapsed_time <= time_in_seconds, 'Wait_for() %s timeout' % self.url
                self.__reload()

        if html:
            while html not in self.__text:
                elapsed_time = time.time() - start
                assert elapsed_time <= time_in_seconds, 'Wait_for() %s timeout' % self.url
                self.__reload()

    # TODO: eliminate redundancy by merging exists() with check_route()
    def exists(self, route=""):
        """
        Check if route is valid. It differs from check_route() in that it will always
        append the route to the current url.
        :param route: Route to page.
        :return: True is the route is up and valid; False, otherwise.
        """
        page_is_ok = True

        # Request will crash when the connection is refused
        try:
            __status = self.session.get(self.url + route).status_code
        except Exception:
            page_is_ok = False
            __status = 520

        if 399 < __status < 600:
            page_is_ok = False

        return page_is_ok

    def go_to(self, route=""):
        """
        Append a route to current URL.
        :param route: Route to page.
        :return: True if the route is valid; False, otherwise.
        """
        valid_url = self.check_route(route)

        if valid_url:
            self.url = self.base + route
            self.__reload()

        return valid_url

    # TODO: change the substring lookup to a regex
    def has(self, html):
        """
        Checks if current URL contains specific html
        :param html: Html to look for.
        :return: True if it contains the html; False, otherwise.
        """
        found = True

        position = self.__text.find(html)

        if position == -1:
            found = False

        return found

    # TODO: Automate/simplify this step. As it is, it requires too much from the user.
    def login(self, action_route, login_data):
        """
        Attempt a login post request.
        :param action_route: Login action route.
        :param login_data: Dictionary of <input> login parameters.
        :return:
        """
        html = "empty"

        try:
            url = self.base + action_route
            self.session.get(url)
            # Jenkins will not accept requests without a header
            html = self.session.post(url, data=login_data, headers={"Referer": "http://ci-jenkins.org/"})
        except Exception:
            if not self.ignore_valid:
                print "Connection to %s couldn't be established" % self.base
                exit(1)

        return html.text
