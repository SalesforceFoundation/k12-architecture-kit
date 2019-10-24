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
        //Declare and initate dmlWrapper    
        DmlWrapper dmlWrapper = new DmlWrapper();
        
        //Set of related contact ids
        Set<Id> setRelatedContactIds = new Set<Id>();
        //If listNew not empty
        if (listNew != null && listNew.size() > 0) {
            for (Integer i = 0; i < listNew.size(); i++) {
                Grade_Enrollment__c gradeErol = (Grade_Enrollment__c)listNew[i];
                
                //BEFORE INSERT AND BEFORE UPDATE
                if(triggerAction == hed.TDTM_Runnable.Action.BeforeInsert 
                || triggerAction == hed.TDTM_Runnable.Action.BeforeUpdate) {
                    //Update the current grade level with current grade enrollment
                    if(gradeErol.Status__c != null 
                    && gradeErol.Status__c == 'Current') {
                        gradeErol.Contact__r.Current_Grade_Level__c = gradeErol.Grade_Level__c;
                    }
                    //Collect Ids of related contacts
                    setRelatedContactIds.add(gradeErol.Contact__c);
                }
            }
        }
        
        //Query and loop through related contacts and their grade enrollment
        for (Contact relatedContact : [SELECT Id, 
                                            (SELECT Id, 
                                                    Status__c 
                                            FROM Grade_Enrollments__r
                                            WHERE Status__c = 'Current') 
                                        FROM Contact
                                        WHERE Id in :setRelatedContactIds]) {
            for (Grade_Enrollment__c gradeErol : relatedContact.Grade_Enrollments__r) {
                system.debug(gradeErol);
            }  
        }

        
        return dmlWrapper;
    }
}