/*
    Copyright (c) 2020, Salesforce.org
    All rights reserved.
    
    Redistribution and use in source and binary forms, with or without
    modification, are permitted provided that the following conditions are met:
    
    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of Salesforce.org nor the names of
      its contributors may be used to endorse or promote products derived
      from this software without specific prior written permission.
 
    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
    "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
    LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
    FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
    COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
    INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
    BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
    LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
    CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
    LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
    ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
    POSSIBILITY OF SUCH DAMAGE.
*/
/**
* @author Salesforce.org
* @date 2020
* @group Contact
* @group-content ../../ApexDocContent/Contact.htm
* @description Whenever a Contact is created with 'Current Grade Level'or updated with 'Current Grade Level' this class
* creates a Grade Enrollment record with status 'Current' and assigns the 'Grade Level' on the Contact OR 
* updates the 'Grade Level' on the matching record to Current.
*/
global with sharing class CON_CurrentGradeLevel_TDTM extends hed.TDTM_Runnable {
    /**********************************************************************************************************************
    * @description Whenever a Contact is created with 'Current Grade Level'or updated with 'Current Grade Level' this class
    * creates a Grade Enrollment record with status 'Current' and assigns the 'Grade Level' on the Contact OR
    * updates the 'Grade Level' on the matching record to Current.
    * @param listNew the list of Course Enrollments from trigger new.
    * @param listOld the list of Coursen Enrollments from trigger old.
    * @param triggerAction which trigger event (AfterInsert, AfterUpdate, etc.).
    * @param objResult the describe for Contact.
    * @return dmlWrapper
    ************************************************************************************************************************/
    global override DmlWrapper run(List<SObject> listNew, List<SObject> listOld,
        hed.TDTM_Runnable.Action triggerAction, Schema.DescribeSObjectResult objResult) {

        //Declare and initiate dmlWrapper
        DmlWrapper dmlWrapper = new DmlWrapper();

        //After INSERT
        if (triggerAction == hed.TDTM_Runnable.Action.AfterInsert &&
            !TDTM_ProcessControl.getRecursionFlag(TDTM_ProcessControl.registeredTrigger.CON_CurrentGradeLevel_TDTM_After_Insert)) {
            if (listNew != null && listNew.size() > 0) {
                Map<Id, Contact> allIdsToNewContacts = new Map<Id, Contact>((List<Contact>)listNew);
                createGradeEnrollments(allIdsToNewContacts, NULL, dmlWrapper);
                TDTM_ProcessControl.setRecursionFlag(TDTM_ProcessControl.registeredTrigger.CON_CurrentGradeLevel_TDTM_After_Insert, true);
            }
        }
        //After UPDATE
        if (triggerAction == hed.TDTM_Runnable.Action.AfterUpdate &&
            !TDTM_ProcessControl.getRecursionFlag(TDTM_ProcessControl.registeredTrigger.CON_CurrentGradeLevel_TDTM_After_Update)) {
            if (listOld != NULL && listNew != NULL &&  listNew.size() > 0 &&  listOld.size() > 0) {
                Map<Id, Contact> allIdsToOldContacts = new Map<Id, Contact>((List<Contact>)listOld);
                Map<Id, Contact> allIdsToNewContacts = new Map<Id, Contact>((List<Contact>)listNew);
                if (!TDTM_ProcessControl.getRecursionFlag(TDTM_ProcessControl.registeredTrigger.CON_CurrentGradeLevel_TDTM_createGradeEnrollments)) {
                    createGradeEnrollments(allIdsToNewContacts, allIdsToOldContacts, dmlWrapper);
                }    
                updateGradeEnrollments(allIdsToNewContacts, allIdsToOldContacts, dmlWrapper);
                TDTM_ProcessControl.setRecursionFlag(TDTM_ProcessControl.registeredTrigger.CON_CurrentGradeLevel_TDTM_After_Update, true);
            }
        }

        // Set the recursion flags to false for next transaction
        TDTM_ProcessControl.setRecursionFlag(TDTM_ProcessControl.registeredTrigger.CON_CurrentGradeLevel_TDTM_After_Insert, false);
        TDTM_ProcessControl.setRecursionFlag(TDTM_ProcessControl.registeredTrigger.CON_CurrentGradeLevel_TDTM_After_Update, false);
        TDTM_ProcessControl.setRecursionFlag(TDTM_ProcessControl.registeredTrigger.CON_CurrentGradeLevel_TDTM_createGradeEnrollments, false);

        return dmlWrapper;
    }
    /*******************************************************************************************************
    * @description This method creates Grade Enrollment records whenever a Contact with a Current Grade Level
    * is inserted OR Contact's Current Grade Level is changed.
    * @param allIdsToContacts A Map of Id to all new Contact Records
    * @param allIdsToContactsOld A Map of Id to all old Contact Records
    * @param dmlWrapper
    ********************************************************************************************************/
    private void createGradeEnrollments(Map<Id, Contact> allIdsToContacts, Map<Id, Contact> allIdsToContactsOld, dmlWrapper dmlWrapper) {
        List<Grade_Enrollment__c> gradeEnrollmentsToInsert = new List<Grade_Enrollment__c>();
        for (Contact eachContact : [SELECT Id, Current_Grade_Level__c FROM Contact WHERE (((Current_Grade_Level__c != NULL) AND (Current_Grade_Level__c != 'NotApplicable')
                                                                                         AND (Current_Grade_Level__c != '--None--') AND (Current_Grade_Level__c != ''))
                                                                                         AND Id IN :allIdsToContacts.keySet())]) {
            if (eachContact != NULL && ((allIdsToContactsOld == NULL) || (allIdsToContactsOld != NULL && allIdsToContactsOld.get(eachContact.Id) != NULL
                    && eachContact.Current_Grade_Level__c != allIdsToContactsOld.get(eachContact.Id).Current_Grade_Level__c))) {
                Grade_Enrollment__c gradeEnrollment = new Grade_Enrollment__c();
                gradeEnrollment.Contact__c = eachContact.Id;
                gradeEnrollment.Status__c = 'Current';
                gradeEnrollment.Grade_Level__c = eachContact.Current_Grade_Level__c;
                gradeEnrollmentsToInsert.add(gradeEnrollment);
            }
        }
        if (gradeEnrollmentsToInsert != NULL && gradeEnrollmentsToInsert.size() > 0) {
            dmlWrapper.objectsToInsert.addAll((List<SObject>)gradeEnrollmentsToInsert);
        }
    }
    /*******************************************************************************************************
    * @description This method updates all the Grade Enrollments with Status 'Current' to 'Former' when its
    * related Contact's Current Grade Level changes to 'Not Applicable'.
    * @param allIdsToContacts A Map of Id to all new Contact Records
    * @param allIdsToContactsOld A Map of Id to all old Contact Records
    * @param dmlWrapper
    ********************************************************************************************************/
    private void updateGradeEnrollments(Map<Id, Contact> allIdsToContacts, Map<Id, Contact> allIdsToContactsOld, dmlWrapper dmlWrapper) {
        List<Grade_Enrollment__c> gradeEnrollmentsToUpdate = new List<Grade_Enrollment__c>();
        for (Contact eachContact: [SELECT Id, Current_Grade_Level__c, (SELECT Id, Status__c FROM Grade_Enrollments__r WHERE Status__c = 'Current')
                                   FROM Contact WHERE Current_Grade_Level__c = 'NotApplicable' AND Id IN :allIdsToContacts.keySet()]) {
            if (eachContact != NULL && allIdsToContactsOld != NULL && allIdsToContactsOld.get(eachContact.Id) != NULL &&
                allIdsToContactsOld.get(eachContact.Id).Current_Grade_Level__c != eachContact.Current_Grade_Level__c) {
                for (Grade_Enrollment__c eachGE : eachContact.Grade_Enrollments__r) {
                    eachGE.Status__c = 'Former';
                    gradeEnrollmentsToUpdate.add(eachGE);
                }
            }
        }
        if (gradeEnrollmentsToUpdate != NULL && gradeEnrollmentsToUpdate.size() > 0) {
            dmlWrapper.objectsToUpdate.addAll((List<SObject>)gradeEnrollmentsToUpdate);
        }
    }
}