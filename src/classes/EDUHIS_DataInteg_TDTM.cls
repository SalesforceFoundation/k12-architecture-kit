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
* @description Whenever the Educational Institution field on an Education History record is updated with a non-null
* value, it is compared to the non-null value specified for the 'Educational Institution' field on the related Grade
* Enrollment record.  The update will be processed only if the Educational Institution fields are a match, otherwise, 
* an error message will be displayed.
*/
global with sharing class EDUHIS_DataInteg_TDTM extends hed.TDTM_Runnable {
    /**********************************************************************************************************************
    * @description Whenever an Educational History record is updated with a change to the assocaited Educational Institution 
    * Account, the new Educational Institution is compared with the Institution specified on the related Grade Enrollment
    * record.  If there is a mis-match, the update is blocked an an error message displayed. Note that blank values for 
    * the Educational Institution are not included in the comparison.
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

        if (triggerAction == hed.TDTM_Runnable.Action.BeforeUpdate) {
            this.checkForGradeEnrollmentEducationalInstitutionMismatch(newList, oldList);
        }

        return dmlWrapper;
    }

    /**********************************************************************************************************************
    * @description Determines whether the updated non-blank value for the Educational Institution Account on an Education 
    * History record matches the non-blank Educational Institution value specified on the related Grade Enrollment record.
    * @param  newSObjectsList List of SObjects in updated state.
    * @param  oldSObjectsList List of SObjects in state before update.
    **********************************************************************************************************************/
    @TestVisible
    private void checkForGradeEnrollmentEducationalInstitutionMismatch(List<SObject> newSObjectsList, List<SObject> oldSObjectsList){
        Map<Id, hed__Education_History__c> newEdHistById = new Map<Id, hed__Education_History__c>((List<hed__Education_History__c>)newSObjectsList);
        Map<Id, hed__Education_History__c> oldEdHistById = new Map<Id, hed__Education_History__c>((List<hed__Education_History__c>)oldSObjectsList);
        Map<Id, Grade_Enrollment__c> gradeEnrollmentByEduHistId = new Map<Id, Grade_Enrollment__c>();

        List<Grade_Enrollment__c> relatedGradeEnrollmentsList = ([SELECT Id,
                                                                         Educational_Institution__c,
                                                                         Education_History__c,
                                                                         Contact__c
                                                                 FROM Grade_Enrollment__c
                                                                 WHERE Education_History__c IN :newEdHistById.keySet()]);

        for(Grade_Enrollment__c gradeEnroll : relatedGradeEnrollmentsList){
            gradeEnrollmentByEduHistId.put(gradeEnroll.Education_History__c, gradeEnroll);
        }
        
        for (hed__Education_History__c eduHist : newEdHistById.values()){
            if (String.isBlank(eduHist.hed__Account__c) == true || 
                    gradeEnrollmentByEduHistId.containsKey(eduHist.Id) == false ||
                    String.isBlank(gradeEnrollmentByEduHistId.get(eduHist.Id).Educational_Institution__c)){
                continue;
            }

            hed__Education_History__c oldEduHist = oldEdHistById.get(eduHist.Id);

            if (eduHist.hed__Account__c != oldEduHist.hed__Account__c){
                if (eduHist.hed__Account__c != gradeEnrollmentByEduHistId.get(eduHist.Id).Educational_Institution__c){
                    eduHist.addError(Label.EduHisInstitutionMismatch);
                }
            }
        }
    }
}