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
* @group Grade Enrollment
* @group-content ../../ApexDocContent/GradeEnrollment.htm
* @description Whenever a Grade Enrollment is created or updated with an associated Education History related to an 
* Educational Institution, the record is not saved if the 'Educational Institution' fields on both the Education History
* and Grade Enrollment records are populated and do not match.
*/
global with sharing class GRER_DataInteg_TDTM extends hed.TDTM_Runnable {
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

        if (triggerAction == hed.TDTM_Runnable.Action.AfterInsert){
            this.handleAfterInsert(newList);
        }

        if (triggerAction == hed.TDTM_Runnable.Action.BeforeUpdate) {
            this.handleBeforeUpdate(newList, oldList);
        }

        return dmlWrapper;
    }

    /**********************************************************************************************************************
    * @description Handles the logic associated with an After Insert trigger action.
    * @param  newSObjectsList A list of SObjects to be inserted.
    **********************************************************************************************************************/
    @TestVisible
    private void handleAfterInsert(List<SObject> newSObjectsList){
        Map<Id, Grade_Enrollment__c> newGradeEnrollmentsById = new Map<Id, Grade_Enrollment__c>((List<Grade_Enrollment__c>)newSObjectsList);

        List<Grade_Enrollment__c> gradeEnrollmentsToInsert = [SELECT Id,
                                                                     Educational_Institution__c,
                                                                     Education_History__r.hed__Account__c  
                                                              FROM Grade_Enrollment__c
                                                              WHERE Id IN :newGradeEnrollmentsById.keySet()];


        for (Grade_Enrollment__c gradeEnroll : gradeEnrollmentsToInsert){
            Grade_Enrollment__c gradeEnrollToInsertInContext = newGradeEnrollmentsById.get(gradeEnroll.Id);
            Id accountIdOnRelatedEduHist = gradeEnroll.Education_History__r.hed__Account__c;

            if (this.isEducationalInstitutionFieldsPopulated(gradeEnrollToInsertInContext, accountIdOnRelatedEduHist) && 
                    this.hasInstitutionMismatch(gradeEnrollToInsertInContext, accountIdOnRelatedEduHist)){
                        
                gradeEnrollToInsertInContext.addError(Label.GrErInstitutionMismatch);
            }
        }
    }

    /**********************************************************************************************************************
    * @description Handles the logic associated with a Before Update trigger action.
    * @param  newSObjectsList List of SObjects in updated state.
    * @param  oldSObjectsList List of SObjects in state before update.
    **********************************************************************************************************************/
    @TestVisible
    private void handleBeforeUpdate(List<SObject> newSObjectsList, List<SObject> oldSObjectsList){
        Map<Id, Grade_Enrollment__c> oldGradeEnrollmentsById = new Map<Id, Grade_Enrollment__c>((List<Grade_Enrollment__c>)oldSObjectsList);
        Map<Id,Grade_Enrollment__c> newGradeEnrollmentsById = new Map<Id,Grade_Enrollment__c>((List<Grade_Enrollment__c>)newSObjectsList);

        List<Grade_Enrollment__c> gradeEnrollmentsToUpdate = [SELECT Id,
                                                                     Educational_Institution__c,
                                                                     Education_History__r.hed__Account__c  
                                                              FROM Grade_Enrollment__c
                                                              WHERE Id IN :newGradeEnrollmentsById.keySet()];

        for (Grade_Enrollment__c gradeEnroll : gradeEnrollmentsToUpdate){
            Id institutionIdOnGradeEnroll = gradeEnroll.Education_History__r.hed__Account__c;

            Grade_Enrollment__c updatedGradeEnrollInContext = newGradeEnrollmentsById.get(gradeEnroll.Id);
            Grade_Enrollment__c oldGradeEnroll = oldGradeEnrollmentsById.get(gradeEnroll.Id);

            if (updatedGradeEnrollInContext.Educational_Institution__c != oldGradeEnroll.Educational_Institution__c && 
                    this.isEducationalInstitutionFieldsPopulated(updatedGradeEnrollInContext, institutionIdOnGradeEnroll) &&
                    this.hasInstitutionMismatch(updatedGradeEnrollInContext, institutionIdOnGradeEnroll)){
                    
                updatedGradeEnrollInContext.addError(Label.GrErInstitutionMismatch);
            }               
        }
    }

    /**********************************************************************************************************************
    * @description Determines whether the Educational Institution fields on a Grade Enrollment and associated Educational
    * History record are populated.
    * @param gradeEnrollment The updated Grade Enrollment record to evaluate.
    * @param educationHistoryInstitutionId The Id of the Institution specified on the Education History record associated with the Grade Enrollment.
    * @return True if the Educational Institution fields on both records are populated, False otherwise.
    **********************************************************************************************************************/
    @TestVisible 
    private Boolean isEducationalInstitutionFieldsPopulated(Grade_Enrollment__c gradeEnrollment, Id educationHistoryInstitutionId){
        return String.isNotBlank(gradeEnrollment.Educational_Institution__c) && String.isNotBlank(educationHistoryInstitutionId);
    }

    /**********************************************************************************************************************
    * @description Determines whether the Educational Institution specified on the Education History record matches the
    * one specified on the related Grade Enrollment record.
    * @param  gradeEnrollment The Grade Enrollment record to evaluate.
    * @param educationHistoryInstitutionId The Id of the Institution specified on the Education History record associated with the Grade Enrollment.
    * @return True if the Educational Institution fields for both records match, False otherwise.
    **********************************************************************************************************************/
    @TestVisible
    private Boolean hasInstitutionMismatch(Grade_Enrollment__c gradeEnrollment, Id educationHistoryInstitutionId){
        return gradeEnrollment.Educational_Institution__c != educationHistoryInstitutionId;
    } 
}