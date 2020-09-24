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
        List<Grade_Enrollment__c> gradeEnrollmentsWithErrorsList = new List<Grade_Enrollment__c>();

        if (newList == null || newList.isEmpty() == true){
            return null;
        }

        if (triggerAction == hed.TDTM_Runnable.Action.AfterInsert){
            gradeEnrollmentsWithErrorsList = this.handleAfterInsert(newList);
            return null;
        }

        if (triggerAction == hed.TDTM_Runnable.Action.BeforeUpdate) {
            gradeEnrollmentsWithErrorsList = this.handleBeforeUpdate(newList, oldList);
            return null;
        }

        return null;
    }

    /**********************************************************************************************************************
    * @description Handles the logic associated with an After Insert trigger action.
    * @param  newSObjectsList A list of SObjects to be inserted.
    * @return A list of Grade Enrollment records with errors.
    **********************************************************************************************************************/
    @TestVisible
    private List<Grade_Enrollment__c> handleAfterInsert(List<SObject> newSObjectsList){
        List<Grade_Enrollment__c> gradeEnrollmentsWithErrorsList = new List<Grade_Enrollment__c>();
        gradeEnrollmentsWithErrorsList = this.checkEducationalInstitutionAgainstEducationHistory(newSObjectsList);

        return gradeEnrollmentsWithErrorsList;
    }

    /**********************************************************************************************************************
    * @description Handles the logic associated with a Before Update trigger action.
    * @param  newSObjectsList List of SObjects in updated state.
    * @param  oldSObjectsList List of SObjects in state before update.
    * @return A list of Grade Enrollment records with errors.
    **********************************************************************************************************************/
    @TestVisible
    private List<Grade_Enrollment__c> handleBeforeUpdate(List<SObject> newSObjectsList, List<SObject> oldSObjectsList){
        Map<Id,Grade_Enrollment__c> newGradeEnrollmentsById = new Map<Id,Grade_Enrollment__c>((List<Grade_Enrollment__c>)newSObjectsList);
        Map<Id,Grade_Enrollment__c> oldGradeEnrollmentsById = new Map<Id,Grade_Enrollment__c>((List<Grade_Enrollment__c>)oldSObjectsList);

        List<Grade_Enrollment__c> gradeEnrollmentsWithErrorsList = new List<Grade_Enrollment__c>();
        gradeEnrollmentsWithErrorsList = this.checkEducationalInstitutionAgainstEducationHistory(newSObjectsList, oldSObjectsList);
        return gradeEnrollmentsWithErrorsList;
    }

    /**********************************************************************************************************************
    * @description Verifies that the Educational Institution specified on a Grade Enrollment record matches the value set
    * on the associated Education History record before insertion.
    * @param  newSObjectsList List of SObjects to insert.
    * @return A list of Grade Enrollment records with errors.
    **********************************************************************************************************************/
    @TestVisible
    private List<Grade_Enrollment__c> checkEducationalInstitutionAgainstEducationHistory(List<SObject> newSObjectsList){
        Map<Id, Grade_Enrollment__c> gradeEnrollmentsById = new Map<Id, Grade_Enrollment__c>((List<Grade_Enrollment__c>)newSObjectsList);

        Set<Id> relevantGradeEnrollIdsSet = new Set<Id>();
        List<Grade_Enrollment__c> gradeEnrollmentsWithErrorsList = new List<Grade_Enrollment__c>();

        for (Grade_Enrollment__c gradeEnroll : gradeEnrollmentsById.values()){
            if (String.isBlank(gradeEnroll.Educational_Institution__c) == true){
                continue;
            }
            relevantGradeEnrollIdsSet.add(gradeEnroll.Id);
        }

        List<Grade_Enrollment__c> relevantGradeEnrollmentsList = [SELECT Id, 
                                                                         Education_History__c,
                                                                         Education_History__r.hed__Account__c,
                                                                         Educational_Institution__c
                                                                  FROM Grade_Enrollment__c
                                                                  WHERE Educational_Institution__c != null 
                                                                  AND Education_History__r.hed__Account__c != null
                                                                  AND Id IN :relevantGradeEnrollIdsSet];

        for (Grade_Enrollment__c gradeEnroll : relevantGradeEnrollmentsList){
            Grade_Enrollment__c gradeEnrollInContext = gradeEnrollmentsById.get(gradeEnroll.Id);

            if (gradeEnrollInContext.Educational_Institution__c == gradeEnroll.Education_History__r.hed__Account__c){
                continue;
            }

            gradeEnrollmentsWithErrorsList.add(gradeEnrollInContext);
            gradeEnrollInContext.addError(Label.GrErInstitutionMismatch);
        }

        return gradeEnrollmentsWithErrorsList;
    }

    /**********************************************************************************************************************
    * @description Verifies that a change to the Educational Institution specified on a Grade Enrollment record matches 
    * the value set on the associated Education History record before update.
    * @param  newSObjectsList List of SObjects to update.
    * @param  oldSObjectsList List of SObjects to update in state prior to update.
    * @return A list of Grade Enrollment records with errors.
    **********************************************************************************************************************/
    @TestVisible
    private List<Grade_Enrollment__c> checkEducationalInstitutionAgainstEducationHistory(List<SObject> newSObjectsList, List<SObject> oldSObjectsList){
        Map<Id, Grade_Enrollment__c> oldGradeEnrollmentsById = new Map<Id, Grade_Enrollment__c>((List<Grade_Enrollment__c>)oldSObjectsList);
        Map<Id,Grade_Enrollment__c> newGradeEnrollmentsById = new Map<Id,Grade_Enrollment__c>((List<Grade_Enrollment__c>)newSObjectsList);

        List<Grade_Enrollment__c> gradeEnrollmentsWithErrorsList = new List<Grade_Enrollment__c>();
        Set<Id> relevantGradeEnrollIdsSet = new Set<Id>();
        
        for (Grade_Enrollment__c gradeEnroll : newGradeEnrollmentsById.values()){
            Grade_Enrollment__c oldGradeEnroll = oldGradeEnrollmentsById.get(gradeEnroll.Id);

            if (String.isBlank(gradeEnroll.Educational_Institution__c)  == true || gradeEnroll.Educational_Institution__c == oldGradeEnroll.Educational_Institution__c){
                continue;
            }
            relevantGradeEnrollIdsSet.add(gradeEnroll.Id);
        }

        List<Grade_Enrollment__c> relevantGradeEnrollmentsList = [SELECT Id, 
                                                                         Education_History__c,
                                                                         Education_History__r.hed__Account__c,
                                                                         Educational_Institution__c
                                                                  FROM Grade_Enrollment__c
                                                                  WHERE Educational_Institution__c != null 
                                                                  AND Education_History__r.hed__Account__c != null
                                                                  AND Id IN :relevantGradeEnrollIdsSet];

        for (Grade_Enrollment__c gradeEnroll : relevantGradeEnrollmentsList){

            Grade_Enrollment__c gradeEnrollInContext = newGradeEnrollmentsById.get(gradeEnroll.Id);

            if (gradeEnroll.Educational_Institution__c == gradeEnrollInContext.Education_History__r.hed__Account__c){
                continue;
            }

            gradeEnrollmentsWithErrorsList.add(gradeEnrollInContext);
            gradeEnrollInContext.addError(Label.GrErInstitutionMismatch);
        }

        return gradeEnrollmentsWithErrorsList;
    }
}