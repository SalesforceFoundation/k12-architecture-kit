*** Settings ***

Resource        cumulusci/robotframework/Salesforce.robot
Library         DateTime
Library         K12.py
Library         cumulusci.robotframework.PageObjects
Library         Process


*** Variables ***
${PRINT_PACKAGE}        true
${UPDATE_COMMUNITY_TIMEZONE}    true
${GET_COMMUNITY_URL}    true
${COMMUNITY_URL}

*** Keywords ***
Capture Screenshot and Delete Records and Close Browser
    [Documentation]         Captures screenshot if a test fails, deletes session records and closes the browser
    Run Keyword If Any Tests Failed      Capture Page Screenshot
    Close Browser
    Delete Session Records

API Get ID
    [Documentation]         Returns the ID of a record identified by the given field_name and
    ...                     field_value input for a specific object

    [Arguments]             ${obj_name}  &{fields}
    @{records} =            Salesforce Query        ${obj_name}
    ...                         select=Id
    ...                         &{fields}
    &{Id} =                 Get From List           ${records}      0
    [return]                ${Id}[Id]

