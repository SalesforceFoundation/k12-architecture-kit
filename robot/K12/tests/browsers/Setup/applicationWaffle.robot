*** Settings ***
Documentation
...    Application review owner can be changed and new owner can submit a recommendation
Resource        robot/K12/resources/K12.robot

Library         cumulusci.robotframework.PageObjects
Library         DateTime
Suite Setup     Open test browser
Suite Teardown  close browser

*** Test Cases ***
Verify that K-12 Architecture Kit exists
    [tags]  Test case: T-5227526
    [Documentation]     Verify the K-12 Architecture Kit exists in launcher
    Select app launcher         K-12 Architecture Kit

Verify the K-12 Architecture Kit settings
    [tags]  Test case: T-5227552
    [Documentation]     Verify the K-12 Settings are as exepected
    Go to education cloud settings
    Verify household settings
    ${student_type} =     API Get ID            RecordType
    ...                                         sObjectType=Contact
    ...                                         Name=Student
    Should Start With      ${student_type}      012
    ${student_type} =     API Get ID            RecordType
    ...                                         sObjectType=Contact
    ...                                         Name=Faculty/Staff
    Should Start With      ${student_type}      012
    ${student_type} =     API Get ID            RecordType
    ...                                         sObjectType=Contact
    ...                                         Name=Guardian
    Should Start With      ${student_type}      012   
    ${course_connection_type} =     API Get ID  RecordType
    ...                                         sObjectType=hed__Course_Enrollment__c
    ...                                         Name=Student
    Should Start With      ${student_type}      012   
    ${course_connection_type} =     API Get ID  RecordType
    ...                                         sObjectType=hed__Course_Enrollment__c
    ...                                         Name=Default
    Should Start With      ${student_type}      012  
    ${course_connection_type} =     API Get ID  RecordType
    ...                                         sObjectType=hed__Course_Enrollment__c
    ...                                         Name=Teacher
    Should Start With      ${student_type}      012                  