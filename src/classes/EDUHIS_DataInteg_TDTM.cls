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
    * @description Whenever a Contact is created with 'Current Grade Level'or updated with 'Current Grade Level' this class
    * creates a Grade Enrollment record with status 'Current' and assigns the 'Grade Level' on the Contact OR
    * updates the 'Grade Level' on the matching record to Current.
    * @param listNew the list of Course Enrollments from trigger new.
    * @param listOld the list of Coursen Enrollments from trigger old.
    * @param triggerAction which trigger event (AfterInsert, AfterUpdate, etc.).
    * @param objResult the describe for Contact.
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

    @TestVisible
    private void handleBeforeUpdate(List<SObject> newSObjectsList, List<SObject> oldSObjectsList){
        Map<Id, hed__Education_History__c> newEdHistById = new Map<Id, hed__Education_History__c>((List<hed__Education_History__c>)newSObjectsList);
        Map<Id, hed__Education_History__c> oldEdHistById = new Map<Id, hed__Education_History__c>((List<hed__Education_History__c>)oldSObjectsList);
        Map<Id, List<Grade_Enrollment__c>> relatedGradeEnrollmentsListByEduHistory = new Map<Id, List<Grade_Enrollment__c>>();
        List<hed__Education_History__c> eduHistoryToVerifyList = new List<hed__Education_History__c>();

        System.debug('MK DEBUG: newEdHistById: ' + newEdHistById);
        System.debug('MK DEBUG: oldEdHistById: ' + oldEdHistById);

        for (hed__Education_History__c eduHist : [SELECT Id,
                                                         Name,
                                                         hed__Account__c,
                                                         (SELECT Contact__c, Educational_Institution__c, Educational_Institution__r.Name 
                                                         FROM Grade_Enrollments__r)
                                                  FROM hed__Education_History__c
                                                  WHERE Id IN :newEdHistById.keySet()]){
                                                      // does this need to be oldEdHistById.keySet()

                System.debug('MK DEBUG: NEW eduHist.Account: ' + eduHist.hed__Account__c);
                System.debug('MK DEBUG: OLD eduHist.Account: ' + oldEdHistById.get(eduHist.Id).hed__Account__c);


            if (this.hasChildRecords(eduHist) && this.hasInstitutionMismatch(eduHist.Grade_Enrollments__r, newEdHistById.get(eduHist.Id))){
                hed__Education_History__c eduHistInContext = newEdHistById.get(eduHist.Id);
                eduHistInContext.addError(Label.EduHisInstitutionMismatch);
            }

            // if (!eduHist.Grade_Enrollments__r.isEmpty()){

            //     System.debug('MK DEBUG: eduHist.Grade_Enrollments__r: ' + eduHist.Grade_Enrollments__r);

            //     if (this.hasInstitutionMismatch(eduHist) == true){
            //         System.debug('MK DEBUG: mismatch found!');
            //         newEdHistById.get(eduHist.Id).addError(Label.EduHisInstitutionMismatch);
            //     }
            // }
        }

        // for (Grade_Enrollment__c grEnroll : gradeEnrollmentsList){
        //     gradeEnrollmentToInsertByEduHistory.put(grEnroll.Education_History__c, grEnroll);
        // }

        // for (hed__Education_History__c edHist : newEdHistById.values()){
        //     hed__Education_History__c oldEdHist = oldEdHistById.get(edHist.Id);

        //     if (edHist.hed__Account__c != null &&  edHist.hed__Account__c != oldEdHist.hed__Account__c ){
        //         Grade_Enrollment__c associatedGradeEnroll = gradeEnrollmentToInsertByEduHistory.get(edHist.Id);
        //         if (edHist.hed__Account__c != associatedGradeEnroll.Educational_Institution__c){
        //             edHist.addError(Label.EduHisInstitutionMismatch);
        //         }
        //     }
        // }
    }

    @testVisible
    private Boolean hasChildRecords(hed__Education_History__c educationHistory) {
        
        return ( educationHistory.Grade_Enrollments__r.isEmpty() == FALSE ); 
    
    }

    private Boolean hasInstitutionMismatch(List<Grade_Enrollment__c> gradeEnrollmentsList, hed__Education_History__c educationHistoryToUpdate){
        System.debug('MK DEBUG: NEW educationHistoryToUpdate Account: ' + educationHistoryToUpdate.hed__Account__c);
        System.debug('MK DEBUG: educationHistoryToUpdate.Grade_Enrollments__r record count: ' + educationHistoryToUpdate.Grade_Enrollments__r.size());

        if (!gradeEnrollmentsList.isEmpty()){
            for (Grade_Enrollment__c grEnroll : gradeEnrollmentsList){
                System.debug('MK DEBUG: grade enrollment account: ' + grEnroll.Educational_Institution__c);
                if (grEnroll.Educational_Institution__c != null && grEnroll.Educational_Institution__c != educationHistoryToUpdate.hed__Account__c){
                    System.debug('MK DEBUG: mismatch found');
                    return true;
                }
            }
        }
        
        return false;
    }

    /**
     * @description Helper method to map Grade Enrollment records related to the same Education History record by Education History Id.
     * @param  gradeEnrollmentsList The list of Grade Enrollment records to map.
     * @return A map containing lists of related Grade Enrollment records sorted by Education History Id.
     */
    private Map<Id, List<Grade_Enrollment__c>> mapGradeEnrollmentsByEducationHistory(List<Grade_Enrollment__c> gradeEnrollmentsList){
        Map<Id, List<Grade_Enrollment__c>> gradeEnrollmentsListByEduHistoryId = new Map<Id, List<Grade_Enrollment__c>>();
        List<Grade_Enrollment__c> relatedGradeEnrollmentsList;

        for (Grade_Enrollment__c grEnroll : gradeEnrollmentsList){
            if (gradeEnrollmentsListByEduHistoryId.containsKey(grEnroll.Education_History__c)){
                relatedGradeEnrollmentsList = gradeEnrollmentsListByEduHistoryId.get(grEnroll.Education_History__c);
            } else {
                relatedGradeEnrollmentsList = new List<Grade_Enrollment__c>();
            }

            relatedGradeEnrollmentsList.add(grEnroll);
            gradeEnrollmentsListByEduHistoryId.put(grEnroll.Education_History__c, relatedGradeEnrollmentsList);
        }

        return gradeEnrollmentsListByEduHistoryId;
    }
}