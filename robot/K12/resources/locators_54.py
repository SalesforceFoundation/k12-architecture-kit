"""Locators for spring '22"""

K12_lex_locators = {
    "app_launcher": {
        "button": "//div[@class='slds-icon-waffle']",
        "search_bar": "//div/input[@type='search' and @placeholder='Search apps and items...']",
        "search_return_term": "//div//lightning-formatted-rich-text[contains(@class,'al-menu-item')]/span/p/b[text()='{}']",
        "view_all_button": "//button[text()='View All']",
    },

    "eda_settings": {
        "household_account": "//span[text()='Household Account']",
        "administrative_name_format": "//span[text()='{!LastName} Administrative Account']",
    },
   
}