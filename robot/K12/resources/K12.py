import datetime
import logging
import pytz
import time
import warnings

from robot.libraries.BuiltIn import RobotNotRunningError
from cumulusci.robotframework.utils import selenium_retry,capture_screenshot_on_error
from robot.libraries.BuiltIn import BuiltIn
from datetime import datetime

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

    def close_all_tabs(self):
        """ Gets the count of the tabs that are open and closes them all """
        locator = K12_lex_locators["close_tab"]
        count = int(self.selenium.get_element_count(locator))
        for i in range(count):
            self.selenium.wait_until_element_is_visible(locator)
            self.selenium.get_webelement(locator).click()

    def click_new_button(self):
        """ Clicks on New button on a list view """
        locator = K12_lex_locators["new_button"]
        self.selenium.get_webelement(locator).click()

    def click_save_button(self):
        """ Clicks on Save button on a form """
        locator_save = K12_lex_locators["save_button"]
        self.selenium.get_webelement(locator_save).click()

    def click_cancel_button(self):
        """ Clicks on Cancel button on a form """
        locator_cancel = K12_lex_locators["cancel_button"]
        self.selenium.get_webelement(locator_cancel).click()

    def click_save_and_verify_toast_message(self,value):
        """ Clicks on save button on form and verifies the toast message"""

        locator = K12_lex_locators["save_button"]
        self.selenium.get_webelement(locator).click()
        time.sleep(2)
        self.verify_toast_message(value)

    def click_save_and_verify_validation_error_message(self,value,error_location=None):
        """Clicks on save button on form and verifies the validation error message. A validation error can display either
           inline(below a field) or as a pop up message at bottom of form. If it's inline pass in 'inline' in test
           else don't pass in any argument.Required argument: error message. Optional argument: inline(if error is inline error)"""

        locator = K12_lex_locators["save_button"]
        self.selenium.get_webelement(locator).click()
        self.verify_validation_error_message(value,error_location)

    def verify_toast_message(self,value):
        """Verifies that toast contains specified value"""
        locator=K12_lex_locators["toast_message"]
        self.selenium.wait_until_element_is_visible(locator)
        msg=self.selenium.get_webelement(locator).text
        if value in msg:
            print(f"Toast message verified: {msg}")
        else:
            raise Exception("Expected Toast message not found on page")

    def verify_validation_error_message(self,value,error_location=None):
        """Verifies validation error message that displays on a form. A validation error can display either inline(below a field) or
           as a pop up message at bottom of form. If it's inline pass in 'inline' in test else don't pass in any argument.
           Required argument: error message. Optional argument: inline(if error is inline error)"""

        if error_location=="inline":
            locator=K12_lex_locators["inline_validation_error_message"].format(value)
        else:
            locator=K12_lex_locators["validation_error_message"].format(value)

        self.selenium.wait_until_page_contains_element(locator)
        msg=self.selenium.get_webelement(locator).text

        if not value in msg:
            raise Exception(f"Expected validation error message '{value}' not found on page. Actual message: '{msg}'")

    def format_all(self, loc, value):
        """ Formats the given locator with the value for all {} occurrences """
        count = loc.count('{')

        if count == 1:
            return loc.format(value)
        elif count == 2:
            return loc.format(value, value)
        elif count == 3:
            return loc.format(value, value, value)

    def select_xpath(self, loc, value):
        """ Selects the correct xpath by checking if it exists on the page
            from the given list of locator possibilities
        """
        locators = K12_lex_locators[loc].values()
        for i in locators:
            locator = self.format_all(i, value)
            if self._check_if_element_exists(locator):
                return locator

        assert "Button with the provided locator not found"

    def populate_placeholder_applications(self, loc, value):
        """ Populates placeholder element with a value
            Finds the placeholder element, inputs value
            and waits for the suggestion and clicks on it
        """
        xpath_lookup = K12_lex_locators["input_placeholder"].format(loc)
        field = self.selenium.get_webelement(xpath_lookup)
        self.selenium.driver.execute_script("arguments[0].click()", field)
        field.send_keys(value)
        xpath_value = self.select_xpath("placeholder_lookup", value)
        self.selenium.click_element(xpath_value)

    def _get_namespace_prefix(self, name):
        """ This is a helper function to capture the randa namespace prefix of the target org """
        parts = name.split('__')
        if parts[-1] == 'c':
            parts = parts[:-1]
        if len(parts) > 1:
            return parts[0] + '__'
        else:
            return ''

    def get_randa_namespace_prefix(self):
        """ Returns the randa namespace value if the target org is a managed org else returns blank value """
        if not hasattr(self.cumulusci, '_describe_result'):
            self.cumulusci._describe_result = self.cumulusci.sf.describe()
        objects = self.cumulusci._describe_result['sobjects']
        level_object = [o for o in objects if o['label'] == 'Application Review'][0]
        return self._get_namespace_prefix(level_object['name'])

    def remove_leading_zeroes_datetime(self,date_format,date_value):
        """This converts the given raw date value which is in string format to date format
            and then removes the leading zeros in the month,date, and hour Eg: input date format "%Y-%m-%d"
        """
        raw_date_value = datetime.datetime.strptime(str(date_value), date_format)
        date_info = '{dt.month}/{dt.day}/{dt.year}'.format(dt = raw_date_value)
        return date_info

    def convert_time_to_UTC_timezone(self, my_time,time_format):
        """ Converts the given datetime to UTC timezone
            my_time should be in the format %Y-%m-%d %H:%M:%S.
            It then returns value back in format passed in(ex. %Y-%m-%d) for test that check to see if
            date contains date value(ex. should contain <date from db>  <converted date>). Arguments required:
            time(ex. current date in format of %Y-%m-%d %H:%M:%S), format expected in return(ex.%Y-%m-%d)
        """
        my_time_format = datetime.strptime(my_time, "%Y-%m-%d %H:%M:%S")
        my_time_local = pytz.timezone("America/Los_Angeles").localize(my_time_format, is_dst=None)

        my_time_utc = my_time_local.astimezone(pytz.utc)
        return datetime.strftime(my_time_utc, time_format)

    def click_form_edit_button(self):
        """Clicks on Edit button on a record's form"""

        locator = K12_lex_locators["edit_button"]
        self.selenium.wait_until_page_contains_element(locator)
        self.salesforce._jsclick(locator)

    def check_and_dismiss_in_app_guidance(self,prompt_header,button_text):
        """Checks on page if in-app guidance is present by checking the in-app guidance prompt header text.
           If present then it will click the 'Got It' button to dismiss and continue with test. Use this keyword
           after going to any page that will be displaying the in-app guidance(currently only on the Application Review page).
           Arguments required: Prompt header text and button text"""

        locator_prompt = K12_lex_locators["in_app_guidance_prompt"].format(prompt_header)
        locator_button = K12_lex_locators["in_app_guidance_got_it_button"].format(button_text)

        time.sleep(5)
        if not self._check_if_element_exists(locator_prompt):
            return
        else:
            for i in range(3):
                i += 1
                self.selenium.wait_until_element_is_visible(locator_button)
                self.salesforce._jsclick(locator_button)
                time.sleep(1) # This is needed to give time for prompt to close.
                if not self._check_if_element_exists(locator_prompt):
                    break

    def pick_start_date(self):
        """Clicks on either End or Start date field depending on argument passed in and then clicks on Today
           to populate the date field with today's date.
        """
        locator_is_open = K12_lex_locators["date_picker_is_open"]
        locator_today = K12_lex_locators["date_picker_value"]
        locator = K12_lex_locators["date_picker_field"]

        self.selenium.set_focus_to_element(locator)
        self.salesforce._jsclick(locator)
        self.selenium.wait_until_element_is_visible(locator_is_open)
        self.selenium.set_focus_to_element(locator_today)
        self.selenium.get_webelement(locator_today).click()

    def go_to_tab(self, value):
        """ Navigates to the given tab name in salesforce so it can log into community
            :param value can be custom objects contact name/Walk-In/Appointment of the tab
        """
        locator = K12_lex_locators["tab"].format(value)
        self.selenium.page_should_contain_element(
            locator,
            message=f"'{value}' contact tab with locator '{locator}' is not available on the page")
        self.selenium.click_element(locator)

    def _scroll_into_view(self,locator):
        """Workaround for fixing scroll into view error caused by latest version of Chromdriver. Use whenever srolling element into view"""
        element = self.selenium.get_webelement(locator)
        self.selenium.driver.execute_script("arguments[0].scrollIntoView({behavior: 'auto', block: 'center', inline: 'center'})", element)