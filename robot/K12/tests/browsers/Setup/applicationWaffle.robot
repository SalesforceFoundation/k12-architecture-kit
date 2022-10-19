*** Settings ***
Documentation
...    Application review owner can be changed and new owner can submit a recommendation
Resource        robot/K12/resources/K12.robot

Library         cumulusci.robotframework.PageObjects
Library         DateTime
Suite Setup     Open test browser
Suite Teardown  Remove permission and close browser

*** Test Cases ***
Verify that owner can be changed on application review and that new owner can successfully submit recommendation
    [tags]  Test case: T-3068950
    [Documentation]     Changes owner of application review to reviewer user and then logs in as reviewer and submits a recommendation.
    #Admin logs in and changes owner to a reviewer
    Select app launcher         K-12 Architecture Kit