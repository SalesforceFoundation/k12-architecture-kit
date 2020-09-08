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
    global override DmlWrapper run(List<SObject> newList, List<SObject> oldList,
        hed.TDTM_Runnable.Action triggerAction, Schema.DescribeSObjectResult objResult) {

        DmlWrapper dmlWrapper = new DmlWrapper();

        if (newList == null || newList.isEmpty() == true){
            return dmlWrapper;
        }

        if (triggerAction == hed.TDTM_Runnable.Action.BeforeInsert) {
            this.handleBeforeInsert(newList);
        }

        if (triggerAction == hed.TDTM_Runnable.Action.BeforeUpdate) {
            this.handleBeforeUpdate(newList, oldList);
        }

        return dmlWrapper;
    }

    @TestVisible
    private void handleBeforeInsert(List<SObject> newSObjectsList){
        Map<Id, Contact> newContactsById = new Map<Id, Contact>((List<Contact>)newSObjectsList);

    }

    @TestVisible
    private void handleBeforeUpdate(List<SObject> newSObjectsList, List<SObject> oldSObjectsList){

    }
}