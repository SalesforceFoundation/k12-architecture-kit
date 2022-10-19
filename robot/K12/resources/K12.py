import logging
import warnings

from robot.libraries.BuiltIn import RobotNotRunningError
from cumulusci.robotframework.utils import selenium_retry,capture_screenshot_on_error
from robot.libraries.BuiltIn import BuiltIn

from locators_54 import K12_lex_locators as locators_54

locators_by_api_version = {
    54.0: locators_54     # spring '22
}
# will get populated in _init_locators
K12_lex_locators = {}

@selenium_retry
class K12(object):

    ROBOT_LIBRARY_SCOPE = "GLOBAL"
    ROBOT_LIBRARY_VERSION = 1.0

    def __init__(self, debug=False):
        self.debug = debug
        self.current_page = None
        self._session_records = []
        # Turn off info logging of all http requests
        logging.getLogger("requests.packages.urllib3.connectionpool").setLevel(
            logging.WARN
        )
        self._init_locators()

    def _init_locators(self):
        try:
            client = self.cumulusci.tooling
            response = client._call_salesforce(
                'GET', 'https://{}/services/data'.format(client.sf_instance))
            self.latest_api_version = float(response.json()[-1]['version'])
            if not self.latest_api_version in locators_by_api_version:
                warnings.warn("Could not find locator library for API %d" % self.latest_api_version)
                self.latest_api_version = max(locators_by_api_version.keys())
        except RobotNotRunningError:
            # We aren't part of a running test, likely because we are
            # generating keyword documentation. If that's the case, assume
            # the latest supported version
            self.latest_api_version = max(locators_by_api_version.keys())
        locators = locators_by_api_version[self.latest_api_version]
        K12_lex_locators.update(locators)

    @property
    def builtin(self):
        return BuiltIn()

    @property
    def cumulusci(self):
        return self.builtin.get_library_instance("cumulusci.robotframework.CumulusCI")

    @property
    def pageobjects(self):
        return self.builtin.get_library_instance("cumulusci.robotframework.PageObjects")

    @property
    def salesforce(self):
        return self.builtin.get_library_instance('cumulusci.robotframework.Salesforce')

    @property
    def selenium(self):
        return self.builtin.get_library_instance("SeleniumLibrary")

    def _check_if_element_exists(self, xpath):
        """ Checks if the given xpath exists
            this is only a helper function being called from other keywords
        """
        elements = int(self.selenium.get_element_count(xpath))
        return True if elements > 0 else False

    @capture_screenshot_on_error
    def select_app_launcher(self,app_name):
        """ Navigates to a Salesforce App via the App Launcher and searches for app. Args required: Name of app(ex. ReviewerCommunity)
        """
        locator_waffle = K12_lex_locators["app_launcher"]["button"]
        locator_search_bar = K12_lex_locators["app_launcher"]["search_bar"]
        locator_search_term = K12_lex_locators["app_launcher"]["search_return_term"].format(app_name)

        self.builtin.log("Clicking on waffle button")
        self.salesforce.wait_until_loading_is_complete()
        self.selenium.set_focus_to_element(locator_waffle)

        for i in range(3):
                i += 1
                self.salesforce._jsclick(locator_waffle)
                if self._check_if_element_exists(locator_search_bar):
                    break
        self.salesforce._populate_field(locator_search_bar,app_name)
        self.selenium.wait_until_page_contains_element(locator_search_term)
        self.selenium.set_focus_to_element(locator_search_term)
        self.salesforce._jsclick(locator_search_term)

    def go_to_education_cloud_settings(self):
        """ Navigates to the Education Cloud Settings Page"""
        url = self.cumulusci.org.lightning_base_url
        namespace=self.get_eda_namespace_prefix()
        if namespace=="hed__":
            url = "{}/lightning/cmp/{}EDASettingsContainer".format(url,namespace)
        else:
            url = "{}/lightning/cmp/c__EDASettingsContainer".format(url)
        self.selenium.go_to(url)
        self.salesforce.wait_until_loading_is_complete()  

    def get_eda_namespace_prefix(self):
        """ Returns the EDA namespace value if the target org is a managed org else returns blank value """
        if not hasattr(self.cumulusci, '_describe_result'):
            self.cumulusci._describe_result = self.cumulusci.sf.describe()
        objects = self.cumulusci._describe_result['sobjects']
        level_object = [o for o in objects if o['label'] == 'Program Plan'][0]
        return self._get_namespace_prefix(level_object['name'])        

    def _get_namespace_prefix(self, name):
        """" This is a helper function to capture the EDA namespace prefix of the target org """
        parts = name.split('__')
        if parts[-1] == 'c':
            parts = parts[:-1]
        if len(parts) > 1:
            return parts[0] + '__'
        else:
            return ''        

    def verify_household_settings(self):
        """ Check the proper settings are selected for Household settings """
        household_account_locator = K12_lex_locators["eda_settings"]["household_account"]
        administrative_name_format_locator = K12_lex_locators["eda_settings"]["administrative_name_format"]        
        
        self.selenium.wait_until_page_contains_element(
            household_account_locator,
            error=f"The error message '{household_account_locator}' is not available on the EDA settings page"
        )
        self.selenium.wait_until_page_contains_element(
            administrative_name_format_locator,
            error=f"The error message '{administrative_name_format_locator}' is not available on the EDA settings page"
        )        
                

    def _scroll_into_view(self,locator):
        """Workaround for fixing scroll into view error caused by latest version of Chromdriver. Use whenever srolling element into view"""
        element = self.selenium.get_webelement(locator)
        self.selenium.driver.execute_script("arguments[0].scrollIntoView({behavior: 'auto', block: 'center', inline: 'center'})", element)

   