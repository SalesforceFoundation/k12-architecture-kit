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

#Depricated keyword 'Verify final decision status and color' can be found at commit id: fb1078c01bb951a97312861e3acf41f1b40eefd3


Capture Screenshot and Delete Records and Close Browser
    [Documentation]         Captures screenshot if a test fails, deletes session records and closes the browser
    Run Keyword If Any Tests Failed      Capture Page Screenshot
    Close Browser
    Delete Session Records

API Create Application
    [Documentation]     Returns the name of application name created from this API.
    ...                 Required fields: Applicant name, program name, and term name(ex. Fall 2021)

    [Arguments]         ${applicant_name}  ${program_name}   ${term_name}  &{fields}

    ${applicant}        API Get ID  Contact   Name=${applicant_name}
    ${applying_to}      API Get ID  Account   Name=${program_name}
    ${term}             API Get ID  hed__Term__c    Name=${term_name}

    ${application_id}   Salesforce Insert   hed__Application__c
    ...                  hed__Applicant__c=${applicant}
    ...                  hed__Term__c=${term}
    ...                  hed__Applying_To__c=${applying_to}
    ...                  &{fields}

   &{application}       Salesforce Get    hed__Application__c  ${application_id}
   [return]             &{application}

API Create Application Review
    [Documentation]     Returns the name of an application review record created from this API.
    [Arguments]         ${application_name}       &{fields}
    ${ns} =    Get randa namespace prefix
    ${application_id} =      API Get ID     hed__Application__c     Name=${application_name}
    ${application_review_id} =      Salesforce Insert       ${ns}Application_Review__c
    ...                             ${ns}Application__c=${application_id}
    ...                             &{fields}
    &{application_review} =   Salesforce Get    ${ns}Application_Review__c     ${application_review_id}
    [return]            &{application_review}

API Get ID
    [Documentation]         Returns the ID of a record identified by the given field_name and
    ...                     field_value input for a specific object

    [Arguments]             ${obj_name}  &{fields}
    @{records} =            Salesforce Query        ${obj_name}
    ...                         select=Id
    ...                         &{fields}
    &{Id} =                 Get From List           ${records}      0
    [return]                ${Id}[Id]

API Create Contact
    [Documentation]         Returns Contact record created by API
    ${first_name} =         Get fake data   first_name
    ${last_name} =          Get fake data   last_name
    ${contact_id} =         Salesforce Insert   Contact
    ...                     FirstName=${first_name}
    ...                     LastName=${last_name}
    &{Contact} =            Salesforce Get    Contact       ${contact_id}
    [return]                &{Contact}

API Create Queue
    [Documentation]         Returns Group record created by API
    [Arguments]             ${group_name}                 &{fields}
    ${queue_id} =           Salesforce Insert   Group
    ...                     Name=${group_name}
    ...                     Type=Queue
    &{queue} =              Salesforce Get    Group       ${queue_id}
    [return]                &{queue}

API Create Account
    [Documentation]       Returns Account record created by API. Required argument: Program name(ex. B.S. Computer Science)

    [Arguments]           ${program}
    ${rt_id} =            Get Record Type Id     Account     Academic_Program
    ${account_id} =       Salesforce Insert  Account
    ...                   Name=${program}
    ...                   RecordTypeId=${rt_id}
    &{account} =          Salesforce Get  Account  ${account_id}
    [return]              &{account}

Update application status
    [Documentation]         Goes to an application, clicks Edit button, and updates the status
    ...                     using the following parameters application status(Ex. 'Admit)

    [Arguments]                               ${application_status}
    Click form edit button
    Current page should be                    EditApplication            hed__Application__c
    Update application status value           ${application_status}
    Click save button

API update application review record
     [Documentation]        Updates the Admissions Recommendation to Admit and the End date value for an application review
     ...                    record used in a test to bypass doing it via the UI. Argument required: application review id.     ...

     [Arguments]                    ${application_review_id}
     ${end_date} =                  Get current date    result_format=%Y-%m-%dT%H:%M:%S
     ${ns} =                        Get randa namespace prefix
     Salesforce Update              ${ns}Application_Review__c      ${application_review_id}
     ...                            ${ns}Admissions_Recommendation__c=Admit
     ...                            ${ns}End__c=${end_date}

API Get start end date fields from db
    [Documentation]         Does a Get call to grab the application_review__c record.
    ...                     Then it takes the End__c and Start__c values and creates a suite variable for them to be used
    ...                     in any test case that wants to compare the Start__c and End__c values form the db
    ...                     instead of comparing with the UI. Lastly it creates a variable ${convert}

    [Arguments]     ${Application_Review_Id}

   ${ns} =    Get randa namespace prefix
   Wait Until Loading Is Complete
   &{application_review_updated} =       Salesforce Get     ${ns}Application_Review__c        ${Application_Review_Id}
   ${end_date_from_db} =                Set variable      ${application_review_updated}[${ns}End__c]
   ${start_date_from_db} =              Set variable       ${application_review_updated}[${ns}Start__c]
   Set suite variable                   ${END_DATE_FROM_DB}
   Set suite variable                   ${START_DATE_FROM_DB}

API create action plan template
    [Documentation]         Creates a new action plan template and returns the id of the action plan template version which is
    ...                     needed for other APIs that will create the action plan template items and action plans.
    ...                     In order to create action plan items and then add items to an action plan and lastly to add
    ...                     action plan to an application this API will need to be run first.
    ...                     Arguments required: true or false. This indicates if action plan template will allow for ad hoc items.

    [Arguments]         ${is_ad_hoc}

    ${action_plan_template_name} =          Generate Random String

    ${apt_id} =                             Salesforce Insert  ActionPlanTemplate
    ...                                     Name=${action_plan_template_name}
    ...                                     ActionPlanType=Industries
    ...                                     TargetEntityType=hed__Application__c
    ...                                     IsAdHocItemCreationEnabled=${is_ad_hoc}
    &{action_plan_template} =               Salesforce Get  ActionPlanTemplate  ${apt_id}
    ${apt_version_id} =                     API Get ID        ActionPlanTemplateVersion
    ...                                     ActionPlanTemplate.Name=${action_plan_template_name}
    &{action_plan_template_version} =       Salesforce Get  ActionPlanTemplateVersion       ${apt_version_id}
    [return]                                &{action_plan_template_version}

API create action plan template item
    [Documentation]     This API follows API create action plan template. It will insert an action plan item to the
    ...                 action plan template using the action plan template version id. Required arguments:
    ...                 action plan template version id(from API Create Action Plan Template), name of checklist item
    ...                 required(true or false), item type(Task or DocumentChecklistItem).
    [Arguments]     ${apt_version_id}   ${item_name}  ${required_true_false}  ${item_type}

    ${apt_template_item_id} =               Salesforce Insert   ActionPlanTemplateItem
    ...                                     ActionPlanTemplateVersionId=${apt_version_id}
    ...                                     ItemEntityType=${item_type}
    ...                                     Name=${item_name}
    ...                                     IsRequired=${required_true_false}


    ${item_entity} =                        Run keyword if     '${item_type}'=='DocumentChecklistItem'
    ...                                     Set variable    DocumentChecklistItem.Name
    ...                                     ELSE    Set variable    Task.Subject
    ${apt_template_item_value_id} =         Salesforce Insert   ActionPlanTemplateItemValue
    ...                                     ActionPlanTemplateItemId=${apt_template_item_id}
    ...                                     IsActive=true
    ...                                     Name=Name
    ...                                     ItemEntityFieldName=${item_entity}
    ...                                     ValueLiteral=${item_name}

API publish action plan template
    [Documentation]         This API will run when template is ready to be published. API Create Action Plan Template
    ...                     needs to be executed first before executing this API.
    [Arguments]     ${apt_version_id}
    Salesforce Update                       ActionPlanTemplateVersion    ${apt_version_id}    Status=Final

API add action plan to application
    [Documentation]         This API will add add an action plan to an application using the action plan template created
    ...                     from API Create Action Plan Template. Arguments required: acton plan name(can be anything),
    ...                     application id, start date.
    [Arguments]                  ${action_plan_name}  ${apt_version_id}   ${application_id}      ${start_date}
    ${action_plan_id} =                     Salesforce Insert   ActionPlan
    ...                                     Name=${action_plan_name}
    ...                                     ActionPlanTemplateVersionId=${apt_version_id}
    ...                                     ActionPlanState=Not Started
    ...                                     ActionPlanType=Industries
    ...                                     IsUsingHolidayHours=true
    ...                                     TargetId=${application_id}
    ...                                     StartDate=${start_date}

API add document to document checklist item
    [Documentation]         This API needs to be run after API Create Action Plan Template and API add action plan to application
    ...                     has been executed. If you want to add a document to a document checklist item then you can run this API.
    ...                     Arguments required: Name of document checklist item that you want to add document to, file name(currently 3 files are available:
    ...                     Automation_doc.docx,Automation_pdf.pdf,and Automation_png.png)
    [Arguments]     ${item_name}        ${file_name}
    ${document_checklist_item_id} =         API Get ID  DocumentChecklistItem
    ...                                     Name=${item_name}

    ${content_document_link_id} =           API Get ID  ContentDocument
    ...                                     Title=${file_name}

    Salesforce Insert                       ContentDocumentLink
    ...                                     LinkedEntityId=${document_checklist_item_id}
    ...                                     ContentDocumentId=${content_document_link_id}
    ...                                     Visibility=AllUsers
    ...                                     ShareType=I
    ...                                     ShareType=I

Change Object Permissions
    [Documentation]  Adds or removes the Create, Read, Edit and Delete permissions for the specified object on the specified permission set.
    ...              Keyword reference from NPSP: https://github.com/SalesforceFoundation/NPSP/blob/525dcd80d2dfcb837e24875959f47e8898427163/robot/Cumulus/resources/NPSP.robot

    [Arguments]  ${action}  ${objectapiname}  ${permset}

    ${ns} =    Get randa namespace prefix

    ${removeobjperms} =  Catenate  SEPARATOR=\n
    ...  ObjectPermissions objperm;
    ...  objperm = [SELECT Id, PermissionsRead, PermissionsEdit, PermissionsCreate, PermissionsDelete FROM ObjectPermissions
    ...  WHERE parentId IN ( SELECT id FROM permissionset WHERE PermissionSet.Name = '${permset}')
    ...  AND SobjectType='${ns}${objectapiname}'];
    ...  objperm.PermissionsRead = false;
    ...  objperm.PermissionsEdit = false;
    ...  objperm.PermissionsCreate = false;
    ...  objperm.PermissionsDelete = false;
    ...  update objperm;

    ${addobjperms} =  Catenate  SEPARATOR=\n
    ...  String permid = [SELECT id FROM permissionset WHERE PermissionSet.Name = '${permset}'].id;
    ...  ObjectPermissions objperm = New ObjectPermissions(PermissionsRead = true, PermissionsEdit = true, PermissionsCreate = false,
    ...  PermissionsDelete = false, ParentId = permid, SobjectType='${ns}${objectapiname}');
    ...  insert objperm;

    Run Keyword if  "${action}" == "remove"
    ...             Run Task  execute_anon
    ...             apex= ${removeobjperms}

    Run Keyword if  "${action}" == "add"
    ...             Run Task  execute_anon
    ...             apex= ${addobjperms}

Go to community via app launcher
    [Documentation]             Returns url from Community with no user logged in.
    Wait Until Loading Is Complete
    Select app launcher         ReviewerCommunity
    Switch window               NEW
    ${url} =                    Get location
    Set global variable         ${COMMUNITY_URL}      ${url}
    [return]                    ${COMMUNITY_URL}

Go to community via contact page
    [Documentation]             Go to the given CONTACT_ID detail page and log in to community as
    ...                         that user. If the login fails because the community is not
    ...                         published properly, republish it and call the keyword again
    [Arguments]                 ${contact_id}

    Go to record home           ${contact_id}
    ${contact_name} =           API Get Name Based on Id      Contact     Id      ${contact_id}
    Go to tab                   ${contact_name}
    Current page should be      Detail      Contact
    Login to community as user
    ${url} =                    Get location
    Set global variable         ${COMMUNITY_URL}      ${url}
    [return]

Update student locale in community
    [Documentation]             The student timezone needs to be updated only once per run. Global
    ...                         variable UPDATE_COMMUNITY_TIMEZONE denotes if the timezone was
    ...                         already updated. If the variable is true, then update the student
    ...                         timezeone to the value passed in the argument.
    ...                         Timezone parameter needs to be passed in the correct format:
    ...                         ex. America/Los_Angeles
    [Arguments]                 ${timezone}

    IF                          '${UPDATE_COMMUNITY_TIMEZONE.lower()}' == 'true'
            ${student1_user_id} =   API get id      User        Name=Marla Gianni
            API update records      User        ${student1_user_id}     LocaleSidKey=${timezone}
            Set global variable     ${UPDATE_COMMUNITY_TIMEZONE}        false
    END

API Update Records
    [Documentation]         Updates the record based on the Id,field_name & field_value.
    [Arguments]             ${obj_name}    ${id}   &{fields}
    ${record} =             Salesforce Update  ${obj_name}   ${id}
    ...                     &{fields}
    @{records} =            Salesforce Query      ${obj_name}
    ...                         select=Id
    &{Id} =                 Get From List  ${records}  0
    [Return]                &{Id}

API Get Name Based on Id
    [Documentation]         Returns the Name of a record identified by the given field_name and
    ...                     field_value input for a specific object
    [Arguments]             ${obj_name}    ${field_name}     ${field_value}
    @{records} =            Salesforce Query      ${obj_name}
    ...                         select=Name
    ...                         ${field_name}=${field_value}
    &{Name} =               Get From List  ${records}  0
    [return]                ${Name}[Name]