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
* @group Education History
* @group-content ../../ApexDocContent/EducationHistory.htm
* @description Whenever a Grade Enrollment is created or updated with an associated Education History related to an 
* Educational Institution, the record is not saved if the 'Educational Institution' field on both the Education History
* and Grade Enrollment records are populated and do not match.
*/
global with sharing class EDUHIS_DataInteg_TDTM extends hed.TDTM_Runnable {
    /**********************************************************************************************************************
    * @description Whenever an Educational History record is updated with a change to the assocaited Educational Institution 
    * Account, the new Educational Institution is compared with each Institution associated with all the related Grade
    * Enrollments.  If any of the Educational Institutions associated with the related Grade Enrollment records do not match
    * the updated Institution specified on the Educational History record, the updated is blocked an an error message is
    * displayed.  Note that blank values for the Educational Institution are not included in the comparison.
    * @param newList the list of Education History records from trigger new.
    * @param oldList the list of Education History records from trigger old.
    * @param triggerAction which trigger event (AfterInsert, AfterUpdate, etc.).
    * @param objResult the describe for Education History.
    * @return dmlWrapper
    ************************************************************************************************************************/
    global override hed.TDTM_Runnable.DmlWrapper run(List<SObject> newList, List<SObject> oldList,
        hed.TDTM_Runnable.Action triggerAction, Schema.DescribeSObjectResult objResult) {

        hed.TDTM_Runnable.DmlWrapper dmlWrapper = new hed.TDTM_Runnable.DmlWrapper();

        if (newList == null || newList.isEmpty() == true){
            return dmlWrapper;
        }

        if (triggerAction == hed.TDTM_Runnable.Action.BeforeUpdate) {
            this.handleBeforeUpdate(newList, oldList);
        }

        return dmlWrapper;
    }

    /**********************************************************************************************************************
    * @description Handles the logic associated with a Before Update trigger action.
    * @param  newSObjectsList newSObjectsList description
    * @param  oldSObjectsList oldSObjectsList description
    **********************************************************************************************************************/
    @TestVisible
    private void handleBeforeUpdate(List<SObject> newSObjectsList, List<SObject> oldSObjectsList){
        Map<Id, hed__Education_History__c> newEdHistById = new Map<Id, hed__Education_History__c>((List<hed__Education_History__c>)newSObjectsList);
        Map<Id, hed__Education_History__c> oldEdHistById = new Map<Id, hed__Education_History__c>((List<hed__Education_History__c>)oldSObjectsList);
        Map<Id, List<Grade_Enrollment__c>> relatedGradeEnrollmentsListByEduHistory = new Map<Id, List<Grade_Enrollment__c>>();
        List<hed__Education_History__c> eduHistoryToVerifyList = new List<hed__Education_History__c>();

        for (hed__Education_History__c eduHist : [SELECT Id,
                                                         Name,
                                                         hed__Account__c,
                                                         (SELECT Contact__c, Educational_Institution__c 
                                                         FROM Grade_Enrollments__r)
                                                  FROM hed__Education_History__c
                                                  WHERE Id IN :newEdHistById.keySet()]){

            hed__Education_History__c eduHistInContext = newEdHistById.get(eduHist.Id);

            if (this.hasChildRecords(eduHist) && this.hasInstitutionMismatch(eduHist, eduHistInContext)){
                eduHistInContext.addError(Label.EduHisInstitutionMismatch);
            }
        }
    }

    /**********************************************************************************************************************
    * @description Determines whether an Education History record is associated with child records.
    * @param  educationHistory The Education History record to check for child records.
    * @return True if the Education History record is associated with child records, False otherwise.
    **********************************************************************************************************************/
    @TestVisible
    private Boolean hasChildRecords(hed__Education_History__c educationHistory) {
        return ( educationHistory.Grade_Enrollments__r.isEmpty() == FALSE ); 
    }

    /**********************************************************************************************************************
    * @description Determines whether the updated Educational Institution Account on an Education History record matches
    * the Educational Institution specified for all related child Grade Enrollment records.
    * @param  educationHistoryToUpdate The Education History record being updated.
    * @param  eduHistInContext The Education History record in its updated state.
    * @return True if there is a mismatch between the updated Educational Institution Account on the Education History record
    * and at least one of the related Grade Enrollment records; False otherwise.
    **********************************************************************************************************************/
    @TestVisible
    private Boolean hasInstitutionMismatch(hed__Education_History__c educationHistoryToUpdate, hed__Education_History__c eduHistInContext){
        if (!educationHistoryToUpdate.Grade_Enrollments__r.isEmpty()){
            for (Grade_Enrollment__c grEnroll : educationHistoryToUpdate.Grade_Enrollments__r){
                if (grEnroll.Educational_Institution__c != null && eduHistInContext.hed__Account__c != null && grEnroll.Educational_Institution__c != eduHistInContext.hed__Account__c){
                    return true;
                }
            }
        }

        return false;
    }
}