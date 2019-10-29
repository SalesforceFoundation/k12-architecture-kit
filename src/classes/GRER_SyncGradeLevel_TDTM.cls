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
* @description This class matches the Contact's Current Grade Level picklist value to the Grade Level set on the Grade Enrollment record when that record's status is “Current.”
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

        //Declare and initiate set of related contact ids
        Set<Id> relatedContactIds = new Set<Id>();

        //Declare and initiate set of current grade enrollment ids
        Set<Id> currentGradeEnrolIds = new Set<Id>();
        
        //Declare and initiate lists to update
        List<Contact> contactsToUpdate = new List<Contact>();
        List<Grade_Enrollment__c> gradeEnrolsToUpdate = new List<Grade_Enrollment__c>();

        //After INSERT and After UPDATE
        if(triggerAction == hed.TDTM_Runnable.Action.AfterInsert 
            || triggerAction == hed.TDTM_Runnable.Action.AfterUpdate) {
            if (listNew != null && listNew.size() > 0) {
                for (Integer i = 0; i < listNew.size(); i++) {
                    Grade_Enrollment__c gradeErol = (Grade_Enrollment__c)listNew[i];
                    if (gradeErol.Status__c != null 
                        && gradeErol.Status__c == 'Current') {
                        //Collect Ids of related contacts
                        relatedContactIds.add(gradeErol.Contact__c);
                        currentGradeEnrolIds.add(gradeErol.Id);
                    }
                }
            }

            //Query and loop through related contacts and their grade enrollment
            for (Contact relatedContact :   [SELECT Id,
                                           		    Current_Grade_Level__c,
                                            	    (SELECT Id, 
                                                    	    Status__c,
                                                 		    Grade_Level__c
                                            	    FROM Grade_Enrollments__r
                                            	    WHERE Status__c = 'Current') 
                                            FROM Contact
                                            WHERE Id in :relatedContactIds]) {
                for (Grade_Enrollment__c gradeErol : relatedContact.Grade_Enrollments__r) {
                    if (currentGradeEnrolIds.contains(gradeErol.Id)) {
                        relatedContact.Current_Grade_Level__c = gradeErol.Grade_Level__c;
                        contactsToUpdate.add(relatedContact);
                    } else {
                    	gradeErol.Status__c = 'Former';
                    	gradeEnrolsToUpdate.add(gradeErol);    
                    }
                }
            }  
        }

        //Add toupdate lists to dmlWrapper
        dmlWrapper.objectsToUpdate.addAll((List<SObject>)contactsToUpdate);
        dmlWrapper.objectsToUpdate.addAll((List<SObject>)gradeEnrolsToUpdate);

        return dmlWrapper;
    }
}