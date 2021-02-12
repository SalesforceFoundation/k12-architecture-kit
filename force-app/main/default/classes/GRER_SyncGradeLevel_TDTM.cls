/*
Copyright (c) 2019, Salesforce.org
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
* @date 2019
* @group Grade Enrollments
* @group-content ../../ApexDocContent/GradeEnrollments.htm
* @description This class matches the Contact's Current Grade Level picklist value
* to the Grade Level set on the Grade Enrollment record when that record's status is “Current.”
* Also, it Ensure a Contact's Current Grade Level field is updated to 'Not Applicable' when
* there are no Grade Enrollment Records with Status of "Current".
*/
global with sharing class GRER_SyncGradeLevel_TDTM extends hed.TDTM_Runnable {
    /*******************************************************************************************************
    * @description Matches the Contact's Current Grade Level picklist value to the Grade Level set on the Grade Enrollment record.
    * @param listNew the list of Course Enrollments from trigger new.
    * @param listOld the list of Coursen Enrollments from trigger old.
    * @param triggerAction which trigger event (BeforeInsert, AfterInsert, etc.).
    * @param objResult the describe for Course Enrollments.
    * @return dmlWrapper
    ********************************************************************************************************/
    global override DmlWrapper run(List<SObject> listNew, List<SObject> listOld,
        hed.TDTM_Runnable.Action triggerAction, Schema.DescribeSObjectResult objResult) {
            
        //Declare and initiate dmlWrapper
        DmlWrapper dmlWrapper = new DmlWrapper();

        // A set of Contact Ids related to Grade Enrollments
        Set<Id> relatedContactIds = new Set<Id>();

        // A set of Current Grade Enrollment Ids
        Set<Id> currentGradeEnrolIds = new Set<Id>();

        // Turn off After Update for CON_CurrentGradeLevel_TDTM
        GRER_SyncGradeLevel_TDTM.turnOffGradeEnrollmentCreation();

        //After INSERT
        if (triggerAction == hed.TDTM_Runnable.Action.AfterInsert) {
            if (listNew != null && listNew.size() > 0) {
                List<Grade_Enrollment__c> newGradeEnrols = (List<Grade_Enrollment__c>)listNew;
                selectGradeEnrolAndContactsToUpdate(newGradeEnrols, NULL, NULL, dmlWrapper, triggerAction);
            }
        }

        // After UPDATE
        if (triggerAction == hed.TDTM_Runnable.Action.AfterUpdate) {
            Map<ID, Grade_Enrollment__c> contactIdToOldGradeEnrolls = new Map<ID, Grade_Enrollment__c>();
            if (listOld != NULL) {
                contactIdToOldGradeEnrolls = new Map<ID, Grade_Enrollment__c>((List<Grade_Enrollment__c>)listOld);
            }
            if (listNew != null && listNew.size() > 0) {
                List<Grade_Enrollment__c> newGradeEnrols = (List<Grade_Enrollment__c>)listNew;
                selectGradeEnrolAndContactsToUpdate(newGradeEnrols, NULL, contactIdToOldGradeEnrolls, dmlWrapper, triggerAction);
            }
        }

        // After DELETE
        if (triggerAction == hed.TDTM_Runnable.Action.AfterDelete) {
            Map<ID, Grade_Enrollment__c> contactIdToOldGradeEnrolls = new Map<ID, Grade_Enrollment__c>();
            if (listOld != NULL) {
                contactIdToOldGradeEnrolls = new Map<ID, Grade_Enrollment__c>((List<Grade_Enrollment__c>)listOld);
            }
            if (contactIdToOldGradeEnrolls != NULL && contactIdToOldGradeEnrolls.size() > 0) {
                selectGradeEnrolAndContactsToUpdate(NULL, listOld, contactIdToOldGradeEnrolls, dmlWrapper, triggerAction);
            }
        }
        // Set the recursion flags to false for next transaction
        TDTM_ProcessControl.setRecursionFlag(TDTM_ProcessControl.registeredTrigger.GRER_SyncGradeLevel_TDTM_After_Insert, false);
        TDTM_ProcessControl.setRecursionFlag(TDTM_ProcessControl.registeredTrigger.GRER_SyncGradeLevel_TDTM_After_Update, false);
        TDTM_ProcessControl.setRecursionFlag(TDTM_ProcessControl.registeredTrigger.GRER_SyncGradeLevel_TDTM_After_Delete, false);

        return dmlWrapper;
    }

    /*******************************************************************************************************
    * @description Creates a contactToGradeEnroll map for Update and delete trigger to hold the Contact and
    * its list of Current Grade Enrollments AND a map currentGradeEnrolToRelatedCon of grade enrollment id
    * to related contact id.
    * @param newGradeEnrols The list of Grade Enrollments from trigger new.
    * @param oldGradeEnrols The list of Grade Enrollments from trigger old.
    * @param idToOldGradeEnrols A map of Id to Grade Enrollments.
    * @param dmlWrapper dmlWrapper
    * @param triggerAction The trigger event (AfterInsert, AfterUpdate, AfterDelete).
    * @return Null
    ********************************************************************************************************/
    private void selectGradeEnrolAndContactsToUpdate(List<Grade_Enrollment__c> newGradeEnrols, List<Grade_Enrollment__c> oldGradeEnrols,
                                                     Map<ID, Grade_Enrollment__c> idToOldGradeEnrols, DmlWrapper dmlWrapper,
                                                     hed.TDTM_Runnable.Action triggerAction) {
        Map<Id, Id> currentGradeEnrolToRelatedCon = new Map<Id, Id>();

        //A set of related Contact Ids that had its Grade Enrollments changed from a stauts of 'Current'
        Set<Id> contactsIdsFormer = new Set<Id>();

        //A Map to capture Contacts and their related Grade Enrollments
        Map<ID, List<Grade_Enrollment__c>> contactToGradeEnroll = new Map<ID, List<Grade_Enrollment__c>>();
        List<Grade_Enrollment__c> gradeEnrollInContext = new List<Grade_Enrollment__c>();
        if (newGradeEnrols != NULL && oldGradeEnrols == NULL) {
            gradeEnrollInContext.addAll(newGradeEnrols);
        } else {
            gradeEnrollInContext.addAll(oldGradeEnrols);
        }
 
        for (Integer i = 0; i < gradeEnrollInContext.size(); i++) {
            Grade_Enrollment__c gradeEnrol = gradeEnrollInContext[i];
            /* If Grade Enrollment's Status is changed from Current OR
               if Grade Enrollment with status Current is deleted add
               to contactToGradeEnroll map. Else if, Grade Enrollment Status
               is/changed to 'Current' then add to currentGradeEnrolToRelatedCon map.
            */
            if ((idToOldGradeEnrols != NULL
                && idToOldGradeEnrols.get(gradeEnrol.ID).Status__c == 'Current'
                && gradeEnrol.Status__c != 'Current') || (oldGradeEnrols != NULL && gradeEnrol.Status__c == 'Current')) {
                    //Collect Ids of related contacts
                    contactsIdsFormer.add(gradeEnrol.Contact__c);
                    if (contactToGradeEnroll.containsKey(gradeEnrol.Contact__c)) {
                        contactToGradeEnroll.get(gradeEnrol.Contact__c).add(gradeEnrol);
                    } else {
                        contactToGradeEnroll.put(gradeEnrol.Contact__c, new List<Grade_Enrollment__c>{gradeEnrol});
                    }
            } else if (gradeEnrol.Status__c != NULL
                       && gradeEnrol.Status__c == 'Current') {
                currentGradeEnrolToRelatedCon.put(gradeEnrol.Id, gradeEnrol.Contact__c);
            }
        }
        if (currentGradeEnrolToRelatedCon != NULL) {
            updateGradeErollmentOrContact(currentGradeEnrolToRelatedCon, NULL, NULL, dmlWrapper, triggerAction);
        }
        if (contactsIdsFormer != NULL && contactsIdsFormer.size() > 0 && contactToGradeEnroll != NULL && contactToGradeEnroll.size() > 0) {
            updateGradeErollmentOrContact(NULL, contactToGradeEnroll, contactsIdsFormer, dmlWrapper, triggerAction);
        }
    }

    /***********************************************************************************************************************
    * @description This method sets the Current Grade Level on the Contact and Updates any other Grade Enrollments to Former
    * @param gradeLevelToContact A map of Grade Enrollment Id to its related Contact
    * @param contactIdToGradeEnroll A map of Contact Id to a list of its related Grade Enrollments
    * @param contactIdsFormer Contact Ids of all Grade Enrollments whose status changed from Current
    * @param dmlWrapper dmlWrapper
    * @param triggerAction triggerAction The trigger event (AfterInsert, AfterUpdate, AfterDelete).
    *************************************************************************************************************************/
    private void updateGradeErollmentOrContact(Map<Id, Id> gradeLevelToContact, Map<ID, List<Grade_Enrollment__c>> contactIdToGradeEnroll,
                                               Set<Id> contactIdsFormer, DmlWrapper dmlWrapper, hed.TDTM_Runnable.Action triggerAction) {

        Set<Id> contactIdsToCheck = new Set<Id>();
        if (contactIdsFormer != NULL) {
            contactIdsToCheck.addAll(contactIdsFormer);
        } else if (gradeLevelToContact != NULL) {
            contactIdsToCheck.addAll(gradeLevelToContact.values());
        }
        //Query and loop through related contacts and their grade enrollment
        List<Contact> contactsToUpdate = new List<Contact>();
        //A map of Contact Id to its Current Grade Level
        Map<Id, String> contactIdToCurrentGradeLevel = new Map<Id, String>();
        List<Grade_Enrollment__c> gradeEnrolsToUpdate = new List<Grade_Enrollment__c>();
        //A list to show errors on Grade Enrollment records
        List<Grade_Enrollment__c> gradeEnrolsErrorRecords = new List<Grade_Enrollment__c>();

        for (Contact relatedContact :   [SELECT Id,
                                         Current_Grade_Level__c,
                                         (SELECT Id,
                                          Status__c, Contact__c,
                                          Grade_Level__c
                                          FROM Grade_Enrollments__r
                                          WHERE Status__c = 'Current')
                                          FROM Contact
                                          WHERE Id IN :contactIdsToCheck]) {
            // Set the Current Grade Level on Contact and update the other Grade Enrollments to Former                        
            if (gradeLevelToContact != NULL && contactIdToGradeEnroll == NULL && contactIdsFormer == NULL) {          
                for (Grade_Enrollment__c gradeErol : relatedContact.Grade_Enrollments__r) {
                    if (gradeLevelToContact.keySet().contains(gradeErol.Id)) {
                        relatedContact.Current_Grade_Level__c = gradeErol.Grade_Level__c;
                        contactsToUpdate.add(relatedContact);
                    } else {
                        gradeErol.Status__c = 'Former';
                        gradeEnrolsToUpdate.add(gradeErol);
                    }
                }
            } /* When Grade Level's Status is changed from 'Current' OR Grade Level with Status Current is deleted
               * If there are no more Current Grade Enrollments then mark the Current Grade Level on the Contact as 'Not Applicable'
               * If there is only 1 Current Grade Enrollment then update the related Contact's Current Grade level to match Grade Enrollment's Current Grade level
               * If there are more than 1 Current Grade Enrollments then show an error on the records that have Grade levels matching with Contact's Current Grade Level
               */
            else if (gradeLevelToContact == NULL && contactIdToGradeEnroll != NULL && contactIdsFormer != NULL) {
                contactIdToCurrentGradeLevel.put(relatedContact.Id, relatedContact.Current_Grade_Level__c);
                if (relatedContact.Grade_Enrollments__r.size() == 0) {
                    if (relatedContact.Current_Grade_Level__c != 'NotApplicable') {
                        relatedContact.Current_Grade_Level__c = 'NotApplicable';
                        contactsToUpdate.add(relatedContact);
                    }
                } else if (relatedContact.Grade_Enrollments__r.size() == 1) {
                    if (relatedContact.Current_Grade_Level__c != relatedContact.Grade_Enrollments__r[0].Grade_Level__c) {
                        relatedContact.Current_Grade_Level__c = relatedContact.Grade_Enrollments__r[0].Grade_Level__c;
                        contactsToUpdate.add(relatedContact);
                    }
                } else {
                    gradeEnrolsErrorRecords.addAll(contactIdToGradeEnroll.get(relatedContact.Id));
                }
            }
        }
        // Show error on only those Grade Enrollments that have matching Grade Level on the related Contact
        if (gradeEnrolsErrorRecords != NULL && gradeEnrolsErrorRecords.size() > 0) {
            for (Grade_Enrollment__c eachEnroll : gradeEnrolsErrorRecords) {
                if (!contactIdToCurrentGradeLevel.isEmpty() && eachEnroll.Grade_Level__c ==  contactIdToCurrentGradeLevel.get(eachEnroll.Contact__c)) {
                    eachEnroll.addError(Label.MultipleCurrentGradeEnrollmentsError);
                }
            }
        }

         // Set the flags to true to prevent recursion
        if (triggerAction == hed.TDTM_Runnable.Action.AfterInsert) {
            TDTM_ProcessControl.setRecursionFlag(TDTM_ProcessControl.registeredTrigger.GRER_SyncGradeLevel_TDTM_After_Insert, true);
        }
        if (triggerAction == hed.TDTM_Runnable.Action.AfterUpdate) {
            TDTM_ProcessControl.setRecursionFlag(TDTM_ProcessControl.registeredTrigger.GRER_SyncGradeLevel_TDTM_After_Update, true);
        }
        if (triggerAction == hed.TDTM_Runnable.Action.AfterDelete) {
            TDTM_ProcessControl.setRecursionFlag(TDTM_ProcessControl.registeredTrigger.GRER_SyncGradeLevel_TDTM_After_Delete, true);
        }

        //Add to update lists to dmlWrapper
        if (contactsToUpdate != NULL) {
            dmlWrapper.objectsToUpdate.addAll((List<SObject>)contactsToUpdate);
        }
        if (gradeEnrolsToUpdate != NULL) {
            dmlWrapper.objectsToUpdate.addAll((List<SObject>)gradeEnrolsToUpdate);
        }
    }
    /*************************************************************************************************
    @description This method will turn the  CON_CurrentGradeLevel_TDTM_createGradeEnrollments to true
    *************************************************************************************************/
    public static void turnOffGradeEnrollmentCreation() {
        TDTM_ProcessControl.setRecursionFlag(TDTM_ProcessControl.registeredTrigger.CON_CurrentGradeLevel_TDTM_createGradeEnrollments, true);
    }
}