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
    * Account, the new Educational Institution is compared with the Institution specified on the related Grade
    * Enrollment.  If a mismatch is found, an error message is displayed.  Note that blank values for the Educational 
    * Institution are not included in the comparison.
    * @param newList The list of Education History records from trigger new.
    * @param oldList The list of Education History records from trigger old.
    * @param triggerAction The associated trigger event (AfterInsert, AfterUpdate, etc.).
    * @param objResult The describe for Education History.
    * @return dmlWrapper
    ************************************************************************************************************************/
    global override hed.TDTM_Runnable.DmlWrapper run(List<SObject> newList, List<SObject> oldList,
        hed.TDTM_Runnable.Action triggerAction, Schema.DescribeSObjectResult objResult) {

        hed.TDTM_Runnable.DmlWrapper dmlWrapper = new hed.TDTM_Runnable.DmlWrapper();

        if (newList == null || newList.isEmpty() == true){
            return dmlWrapper;
        }

        if (triggerAction == hed.TDTM_Runnable.Action.BeforeInsert){
            this.checkEducationalInstitutionAgainstEducationHistory(newList);
        }

        if (triggerAction == hed.TDTM_Runnable.Action.BeforeUpdate) {
            this.checkEducationalInstitutionAgainstEducationHistory(newList, oldList);
        }

        return dmlWrapper;
    }

    /**********************************************************************************************************************
    * @description Verifies that the Educational Institution specified on a Grade Enrollment record matches the value set
    * on the associated Education History record before insertion.
    * @param  newSObjectsList List of SObjects to insert.
    **********************************************************************************************************************/
    @TestVisible
    private void checkEducationalInstitutionAgainstEducationHistory(List<SObject> newSObjectsList){
        List<Grade_Enrollment__c> gradeEnrollmentsToInsertList = (List<Grade_Enrollment__c>)newSObjectsList;
        Map<Id, hed__Education_History__c> relatedEducationHistoryByGradeEnrollmentId = this.mapEducationHistoryByGradeEnrollment(gradeEnrollmentsToInsertList);

        for (Grade_Enrollment__c gradeEnroll : gradeEnrollmentsToInsertList){
            if (String.isBlank(gradeEnroll.Educational_Institution__c) == true || 
                    relatedEducationHistoryByGradeEnrollmentId.containsKey(gradeEnroll.Education_History__c) == false){
                continue;
            }

            if (this.hasInstitutionMismatch(gradeEnroll, relatedEducationHistoryByGradeEnrollmentId.get(gradeEnroll.Education_History__c))){
                gradeEnroll.addError(Label.GrErInstitutionMismatch);
            }     
        }
    }

    /**********************************************************************************************************************
    * @description Verifies that a change to the Educational Institution specified on a Grade Enrollment record matches 
    * the value set on the associated Education History record before update.
    * @param  newSObjectsList List of SObjects to update.
    * @param  oldSObjectsList List of SObjects to update in state prior to update.
    **********************************************************************************************************************/
    @TestVisible
    private void checkEducationalInstitutionAgainstEducationHistory(List<SObject> newSObjectsList, List<SObject> oldSObjectsList){
        Map<Id, Grade_Enrollment__c> oldGradeEnrollmentsById = new Map<Id, Grade_Enrollment__c>((List<Grade_Enrollment__c>)oldSObjectsList);
        Map<Id,Grade_Enrollment__c> newGradeEnrollmentsById = new Map<Id,Grade_Enrollment__c>((List<Grade_Enrollment__c>)newSObjectsList);
        Map<Id, hed__Education_History__c> relatedEducationHistoryByGradeEnrollmentId = this.mapEducationHistoryByGradeEnrollment(newGradeEnrollmentsById.values());

        for (Grade_Enrollment__c gradeEnroll : newGradeEnrollmentsById.values()){
            if (String.isBlank(gradeEnroll.Educational_Institution__c) == true || 
                    relatedEducationHistoryByGradeEnrollmentId.containsKey(gradeEnroll.Education_History__c) == false){
                continue;
            }

            Grade_Enrollment__c oldGradeEnroll = oldGradeEnrollmentsById.get(gradeEnroll.Id);

            if (gradeEnroll.Educational_Institution__c != oldGradeEnroll.Educational_Institution__c){
                if (this.hasInstitutionMismatch(gradeEnroll, relatedEducationHistoryByGradeEnrollmentId.get(gradeEnroll.Education_History__c))){
                    gradeEnroll.addError(Label.GrErInstitutionMismatch);
                }               
            }
        }
    }

    /**********************************************************************************************************************
     * @description Helper method to map Education History records related to a list of Grade Enrollments.
     * @param gradeEnrollmentsList The Grade Enrollments with Education History records to map.
     * @return A map of related Education History records by Grade Enrollment Id.
     **********************************************************************************************************************/ 
    @TestVisible
    private Map<Id, hed__Education_History__c> mapEducationHistoryByGradeEnrollment (List<Grade_Enrollment__c> gradeEnrollmentsList){
        Map<Id, hed__Education_History__c> educationHistoryByGradeEnrollmentId = new Map<Id, hed__Education_History__c>();
        Set<Id> relatedEduHistoryIdSet = new Set<Id>();

        for (Grade_Enrollment__c gradeEnroll : gradeEnrollmentsList){
            relatedEduHistoryIdSet.add(gradeEnroll.Education_History__c);
        }

        Map<Id, hed__Education_History__c> relatedEducationHistoryById = new  Map<Id, hed__Education_History__c>([SELECT Id, 
                                                                                                                         hed__Account__c
                                                                                                                 FROM hed__Education_History__c
                                                                                                                 WHERE Id IN :relatedEduHistoryIdSet]);

        for (Grade_Enrollment__c gradeEnroll : gradeEnrollmentsList){
            if (relatedEducationHistoryById.containsKey(gradeEnroll.Education_History__c)){
                educationHistoryByGradeEnrollmentId.put(gradeEnroll.Id, relatedEducationHistoryById.get(gradeEnroll.Education_History__c));
            }
        }

        return educationHistoryByGradeEnrollmentId;
    }

    /**********************************************************************************************************************
    * @description Determines whether the Educational Institution specified on the Education History record matches the
    * one specified on the related Grade Enrollment record.
    * @param  gradeEnrollment The Grade Enrollment record to evaluate.
    * @param educationHistory The Education History record associated with the Grade Enrollment.
    * @return True if the Educational Institution fields for both records match, False otherwise.
    **********************************************************************************************************************/
    @TestVisible
    private Boolean hasInstitutionMismatch(Grade_Enrollment__c gradeEnrollment, hed__Education_History__c educationHistory){
        return gradeEnrollment.Educational_Institution__c != educationHistory.hed__Account__c;
    } 
}