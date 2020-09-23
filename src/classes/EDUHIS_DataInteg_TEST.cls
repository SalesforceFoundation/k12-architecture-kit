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
* @group Grade Enrollments
* @group-content ../../ApexDocContent/GradeEnrollments.htm
* @description Test class for EDUHIS_DataInteg_TDTM class to ensure that updates to the Educational 
* Institution on an Education History record with a related Grade Enrollment only occurs if the 
* institutions on both records match. */
@isTest
private class EDUHIS_DataInteg_TEST {

    /*********************************************************************************************************
    *****************************************FUNCTIONAL TESTS*************************************************
    **********************************************************************************************************/

    /*********************************************************************************************************
    * @description Tests to verify that updating an Education History record with no change to the 
    * Educational Institution field does not execute.
    *********************************************************************************************************/
    @isTest
    public static void updateEducationHistoryNoInstitutionChange() {
        hed__Hierarchy_Settings__c hs = hed.UTIL_CustomSettings_API.getSettings();
        String adminRecordType = hs.hed__Administrative_Account_Record_Type__c;

        List<Account> accountsList = new List<Account>();
        Account firstAccount = new Account(RecordTypeId = adminRecordType, Name = 'Test Account 1');
        Account secondAccount = new Account(RecordTypeId = adminRecordType, Name = 'Test Account 2');
        accountsList.add(firstAccount);
        accountsList.add(secondAccount);

        insert accountsList;

        Contact testContact = new Contact(LastName = 'Testerson');
        insert testContact;

        List<hed__Education_History__c> educationHistoryList = new List<hed__Education_History__c>();
        for (Integer i = 0; i < 5; i++){
            hed__Education_History__c eduHist = new hed__Education_History__c(hed__Contact__c = testContact.Id,
                                                                              hed__Account__c = firstAccount.Id
                                                                             );
            educationHistoryList.add(eduHist);
        }
       
        insert educationHistoryList;

        Test.startTest();
        update educationHistoryList;
        Test.stopTest();

        for (hed__Education_History__c eduHist : educationHistoryList){
            System.assertEquals(firstAccount.Id, eduHist.hed__Account__c, 'Educational Institution should not change for Education History.');
        }
    }


    /*********************************************************************************************************
    * @description Tests to verify that changing the Educational Institution on an Education History record
    * with no related Grade Enrollment updates without an error.
    *********************************************************************************************************/
    @isTest
    public static void updateEducationHistoryWithoutGradeEnrollment() {
        hed__Hierarchy_Settings__c hs = hed.UTIL_CustomSettings_API.getSettings();
        String adminRecordType = hs.hed__Administrative_Account_Record_Type__c;

        List<Account> accountsList = new List<Account>();
        Account firstAccount = new Account(RecordTypeId = adminRecordType, Name = 'Test Account 1');
        Account secondAccount = new Account(RecordTypeId = adminRecordType, Name = 'Test Account 2');
        accountsList.add(firstAccount);
        accountsList.add(secondAccount);

        insert accountsList;

        Contact testContact = new Contact(LastName = 'Testerson');
        insert testContact;

        List<hed__Education_History__c> educationHistoryList = new List<hed__Education_History__c>();
        for (Integer i = 0; i < 5; i++){
            hed__Education_History__c eduHist = new hed__Education_History__c(hed__Contact__c = testContact.Id,
                                                                              hed__Account__c = firstAccount.Id
                                                                             );
            educationHistoryList.add(eduHist);
        }
       
        insert educationHistoryList;

        for (hed__Education_History__c eduHist : educationHistoryList){
            eduHist.hed__Account__c = secondAccount.Id;
        }

        Test.startTest();
        update educationHistoryList;
        Test.stopTest();

        for (hed__Education_History__c eduHist : educationHistoryList){
            System.assertEquals(secondAccount.Id, eduHist.hed__Account__c, 'Educational Institution should update for Education History with no Grade Enrollments');
        }
    }

    /*********************************************************************************************************
    * @description Tests to verify that changing the Educational Institution on an Education History record
    * to match the value specified on the related Grade Enrollment updates without an error.
    *********************************************************************************************************/
    @isTest
    public static void updateEducationHistoryWithGradeEnrollmentsMatching() {
        hed__Hierarchy_Settings__c hs = hed.UTIL_CustomSettings_API.getSettings();
        String adminRecordType = hs.hed__Administrative_Account_Record_Type__c;

        List<Grade_Enrollment__c> gradeEnrollmentsList = new List<Grade_Enrollment__c>();

        Account firstAccount = new Account(RecordTypeId = adminRecordType, Name = 'Test Account 1');
        insert firstAccount;

        Contact testContact = new Contact(LastName = 'Testerson');
        insert testContact;

        List<hed__Education_History__c> educationHistoryList = new List<hed__Education_History__c>();
        for (Integer i = 0; i < 5; i++){
            hed__Education_History__c eduHist = new hed__Education_History__c(hed__Contact__c = testContact.Id,
                                                                              hed__Account__c = null
                                                                             );
            educationHistoryList.add(eduHist);
        }
       
        insert educationHistoryList;

        for (hed__Education_History__c eduHist : educationHistoryList){
            Grade_Enrollment__c gradeEnroll = new Grade_Enrollment__c(Contact__c = testContact.Id,
                                                                      Educational_Institution__c = firstAccount.Id,
                                                                      Grade_Level__c = 'Eighth Grade'
                                                                     );

            gradeEnrollmentsList.add(gradeEnroll);
            eduHist.hed__Account__c = firstAccount.Id;
        }

        insert gradeEnrollmentsList;

        Test.startTest();
        update educationHistoryList;
        Test.stopTest();

        for (hed__Education_History__c eduHist : educationHistoryList){
            System.assertEquals(firstAccount.Id, eduHist.hed__Account__c, 'Matching Educational Institution should update for Education History with Grade Enrollment.');
        }
    }

    /*********************************************************************************************************
    * @description Tests to verify that changing the Educational Institution on an Education History record
    * to a value that does not match the value specified on the related Grade Enrollment
    *********************************************************************************************************/
    @isTest
    public static void updateEducationHistoryWithGradeEnrollmentsMisMatching() {
        hed__Hierarchy_Settings__c hs = hed.UTIL_CustomSettings_API.getSettings();
        String adminRecordType = hs.hed__Administrative_Account_Record_Type__c;

        List<Account> accountsList = new List<Account>();
        List<Grade_Enrollment__c> gradeEnrollmentsList = new List<Grade_Enrollment__c>();

        Account firstAccount = new Account(RecordTypeId = adminRecordType, Name = 'Test Account 1');
        Account secondAccount = new Account(RecordTypeId = adminRecordType, Name = 'Test Account 2');
        accountsList.add(firstAccount);
        accountsList.add(secondAccount);

        insert accountsList;

        Contact testContact = new Contact(LastName = 'Testerson');
        insert testContact;

        List<hed__Education_History__c> educationHistoryList = new List<hed__Education_History__c>();
        for (Integer i = 0; i < 5; i++){
            hed__Education_History__c eduHist = new hed__Education_History__c(hed__Contact__c = testContact.Id,
                                                                              hed__Account__c = firstAccount.Id
                                                                             );
            educationHistoryList.add(eduHist);
        }
       
        insert educationHistoryList;

        for (hed__Education_History__c eduHist : educationHistoryList){
            eduHist.hed__Account__c = secondAccount.Id;

            Grade_Enrollment__c gradeEnroll = new Grade_Enrollment__c(Contact__c = testContact.Id,
                                                                      Educational_Institution__c = firstAccount.Id,
                                                                      Grade_Level__c = 'Eighth Grade'
                                                                     );

            gradeEnrollmentsList.add(gradeEnroll);
            eduHist.hed__Account__c = secondAccount.Id;
        }

        insert gradeEnrollmentsList;

        Test.startTest();
        Database.SaveResult[] results = Database.update(educationHistoryList, false);
        Test.stopTest();

        for (Database.SaveResult sr : results){
            for (Database.Error err : sr.getErrors()){
                System.assertEquals(Label.EduHisInstitutionMismatch, err.getMessage(), 'Inserting Education History with mismatched Institution should display error message.');
            }
        }
    }
    /*********************************************************************************************************
    * @description Tests to verify that clearing the Educational Institution on an Education History record
    * with a related Grade Enrollment updates even when the Grade Enrollment institution field is not blank.
    *********************************************************************************************************/
    @isTest
    public static void updateEducationHistoryWithGradeEnrollmentBlankInstitutionOnEducationHistory() {        
        hed__Hierarchy_Settings__c hs = hed.UTIL_CustomSettings_API.getSettings();
        String adminRecordType = hs.hed__Administrative_Account_Record_Type__c;

        List<Grade_Enrollment__c> gradeEnrollmentsList = new List<Grade_Enrollment__c>();

        Account firstAccount = new Account(RecordTypeId = adminRecordType, Name = 'Test Account 1');
        insert firstAccount;

        Contact testContact = new Contact(LastName = 'Testerson');
        insert testContact;

        List<hed__Education_History__c> educationHistoryList = new List<hed__Education_History__c>();
        for (Integer i = 0; i < 5; i++){
            hed__Education_History__c eduHist = new hed__Education_History__c(hed__Contact__c = testContact.Id,
                                                                              hed__Account__c = firstAccount.Id
                                                                             );
            educationHistoryList.add(eduHist);
        }
       
        insert educationHistoryList;

        for (hed__Education_History__c eduHist : educationHistoryList){
            Grade_Enrollment__c gradeEnroll = new Grade_Enrollment__c(Contact__c = testContact.Id,
                                                                      Educational_Institution__c = firstAccount.Id,
                                                                      Grade_Level__c = 'Eighth Grade',
                                                                      Education_History__c = eduHist.Id
                                                                     );

            gradeEnrollmentsList.add(gradeEnroll);
            eduHist.hed__Account__c = null;
        }

        insert gradeEnrollmentsList;

        Test.startTest();
        Database.SaveResult[] results = Database.update(educationHistoryList, false);
        Test.stopTest();
               
        for (hed__Education_History__c eduHist : educationHistoryList){
            System.assertEquals(true, String.isBlank(eduHist.hed__Account__c), 'Educational Institution on Education History should update to blank value.');
        } 
    }

    /*********************************************************************************************************
    * @description Tests to verify that changing the Educational Institution on an Education History record
    * with a related Grade Enrollment specified with a blank value for Institution does update.
    *********************************************************************************************************/
    @isTest
    public static void updateEducationHistoryWithGradeEnrollmentBlankInstitutionOnGradeEnrollment() {        
        hed__Hierarchy_Settings__c hs = hed.UTIL_CustomSettings_API.getSettings();
        String adminRecordType = hs.hed__Administrative_Account_Record_Type__c;

        List<Account> accountsList = new List<Account>();
        List<Grade_Enrollment__c> gradeEnrollmentsList = new List<Grade_Enrollment__c>();

        Account firstAccount = new Account(RecordTypeId = adminRecordType, Name = 'Test Account 1');
        Account secondAccount = new Account(RecordTypeId = adminRecordType, Name = 'Test Account 2');
        accountsList.add(firstAccount);
        accountsList.add(secondAccount);

        insert accountsList;

        Contact testContact = new Contact(LastName = 'Testerson');
        insert testContact;

        List<hed__Education_History__c> educationHistoryList = new List<hed__Education_History__c>();
        for (Integer i = 0; i < 5; i++){
            hed__Education_History__c eduHist = new hed__Education_History__c(hed__Contact__c = testContact.Id,
                                                                              hed__Account__c = firstAccount.Id
                                                                             );
            educationHistoryList.add(eduHist);
        }
       
        insert educationHistoryList;

        for (hed__Education_History__c eduHist : educationHistoryList){
            Grade_Enrollment__c gradeEnroll = new Grade_Enrollment__c(Contact__c = testContact.Id,
                                                                      Educational_Institution__c = null,
                                                                      Grade_Level__c = 'Eighth Grade',
                                                                      Education_History__c = eduHist.Id
                                                                     );

            gradeEnrollmentsList.add(gradeEnroll);
            eduHist.hed__Account__c = secondAccount.Id;
        }

        insert gradeEnrollmentsList;

        Test.startTest();
        Database.SaveResult[] results = Database.update(educationHistoryList, false);
        Test.stopTest();
               
        for (hed__Education_History__c eduHist : educationHistoryList){
            System.assertEquals(secondAccount.Id, eduHist.hed__Account__c, 'Educational Institution on Education History should update with blank institution on associated grade enrollment.');
        } 
    }

    /*********************************************************************************************************
    * @description Tests to verify that clearing the Educational Institution on an Education History record
    * with a related Grade Enrollment specified with a blank value for Institution does update.
    *********************************************************************************************************/
    @isTest
    public static void updateEducationHistoryWithGradeEnrollmentBlankInstitutionOnBoth() {        
        hed__Hierarchy_Settings__c hs = hed.UTIL_CustomSettings_API.getSettings();
        String adminRecordType = hs.hed__Administrative_Account_Record_Type__c;

        List<Grade_Enrollment__c> gradeEnrollmentsList = new List<Grade_Enrollment__c>();

        Account firstAccount = new Account(RecordTypeId = adminRecordType, Name = 'Test Account 1');
        insert firstAccount;

        Contact testContact = new Contact(LastName = 'Testerson');
        insert testContact;

        List<hed__Education_History__c> educationHistoryList = new List<hed__Education_History__c>();
        for (Integer i = 0; i < 5; i++){
            hed__Education_History__c eduHist = new hed__Education_History__c(hed__Contact__c = testContact.Id,
                                                                              hed__Account__c = firstAccount.Id
                                                                             );
            educationHistoryList.add(eduHist);
        }
       
        insert educationHistoryList;

        for (hed__Education_History__c eduHist : educationHistoryList){
            Grade_Enrollment__c gradeEnroll = new Grade_Enrollment__c(Contact__c = testContact.Id,
                                                                      Educational_Institution__c = null,
                                                                      Grade_Level__c = 'Eighth Grade',
                                                                      Education_History__c = eduHist.Id
                                                                     );

            gradeEnrollmentsList.add(gradeEnroll);
            eduHist.hed__Account__c = null;
        }

        insert gradeEnrollmentsList;

        Test.startTest();
        Database.SaveResult[] results = Database.update(educationHistoryList, false);
        Test.stopTest();
               
        for (hed__Education_History__c eduHist : educationHistoryList){
            System.assertEquals(true, String.isBlank(eduHist.hed__Account__c), 'Educational Institution on Education History should clear with blank institution on associated grade enrollment.');
        } 
    }

    /*********************************************************************************************************
    ***********************************************UNIT TESTS*************************************************
    **********************************************************************************************************/

    /*********************************************************************************************************
    * @description Test to verify that method checkForGradeEnrollmentEducationalInstitutionMismatch() 
    * successfully processes an update to the Edcuational Institution on an Education History record when it
    * matches the value for the Institution specified on the related Grade Enrollment.
    *********************************************************************************************************/
    @isTest 
    private static void checkForMismatchNotFound(){
        hed__Hierarchy_Settings__c hs = hed.UTIL_CustomSettings_API.getSettings();
        String adminRecordType = hs.hed__Administrative_Account_Record_Type__c;

        List<SObject> newSObjectsList = new List<SObject>();
        List<SObject> oldSObjectsList = new List<SObject>();

        List<Account> accountsList = new List<Account>();
        List<Grade_Enrollment__c> gradeEnrollmentsList = new List<Grade_Enrollment__c>();

        Account firstAccount = new Account(RecordTypeId = adminRecordType, Name = 'Test Account 1');
        Account secondAccount = new Account(RecordTypeId = adminRecordType, Name = 'Test Account 2');
        accountsList.add(firstAccount);
        accountsList.add(secondAccount);

        insert accountsList;

        Contact testContact = new Contact(LastName = 'Testerson');
        insert testContact;

        List<hed__Education_History__c> educationHistoryList = new List<hed__Education_History__c>();
        for (Integer i = 0; i < 5; i++){
            hed__Education_History__c eduHist = new hed__Education_History__c(hed__Contact__c = testContact.Id,
                                                                              hed__Account__c = secondAccount.Id
                                                                             );
            educationHistoryList.add(eduHist);
        }
       
        insert educationHistoryList;

        for (hed__Education_History__c eduHist : educationHistoryList){
            Grade_Enrollment__c gradeEnroll = new Grade_Enrollment__c(Contact__c = testContact.Id,
                                                                      Educational_Institution__c = secondAccount.Id,
                                                                      Grade_Level__c = 'Eighth Grade',
                                                                      Education_History__c = eduHist.Id
                                                                     );

            gradeEnrollmentsList.add(gradeEnroll);
        }

        insert gradeEnrollmentsList;

        for (hed__Education_History__c newEdHist : educationHistoryList){
            newSObjectsList.add((SObject)newEdHist);

            hed__Education_History__c oldEdHist = newEdHist.clone(true);
            oldEdHist.hed__Account__c = firstAccount.Id;
            oldSObjectsList.add((SObject)oldEdHist);
        }

        EDUHIS_DataInteg_TDTM eduHisTdtm = new EDUHIS_DataInteg_TDTM();

        Test.startTest();
        List<DmlException> exceptionsList = new List<DmlException>();

        try{
            eduHisTdtm.checkForGradeEnrollmentEducationalInstitutionMismatch(newSObjectsList, oldSObjectsList);
        } catch (DmlException e){
            exceptionsList.add(e);
        }
        Test.stopTest();

        System.assertEquals(true, exceptionsList.isEmpty(), 'Matching Education Institution for Education History and Grade Enrollment should not display an error.');
    }

    /*********************************************************************************************************
    * @description Test to verify that method checkForGradeEnrollmentEducationalInstitutionMismatch() 
    * displays and error message when the Edcuational Institution on an Education History record 
    * is updated to a value that does not match the Institution specified on the related Grade Enrollment.
    *********************************************************************************************************/
    @isTest 
    private static void checkForMismatchFound(){
        hed__Hierarchy_Settings__c hs = hed.UTIL_CustomSettings_API.getSettings();
        String adminRecordType = hs.hed__Administrative_Account_Record_Type__c;

        List<SObject> newSObjectsList = new List<SObject>();
        List<SObject> oldSObjectsList = new List<SObject>();

        List<Account> accountsList = new List<Account>();
        List<Grade_Enrollment__c> gradeEnrollmentsList = new List<Grade_Enrollment__c>();

        Account firstAccount = new Account(RecordTypeId = adminRecordType, Name = 'Test Account 1');
        Account secondAccount = new Account(RecordTypeId = adminRecordType, Name = 'Test Account 2');
        accountsList.add(firstAccount);
        accountsList.add(secondAccount);

        insert accountsList;

        Contact testContact = new Contact(LastName = 'Testerson');
        insert testContact;

        List<hed__Education_History__c> educationHistoryList = new List<hed__Education_History__c>();
        for (Integer i = 0; i < 5; i++){
            hed__Education_History__c eduHist = new hed__Education_History__c(hed__Contact__c = testContact.Id,
                                                                              hed__Account__c = secondAccount.Id
                                                                             );
            educationHistoryList.add(eduHist);
        }
       
        insert educationHistoryList;

        for (hed__Education_History__c eduHist : educationHistoryList){
            Grade_Enrollment__c gradeEnrollMatching = new Grade_Enrollment__c(Contact__c = testContact.Id,
                                                                              Educational_Institution__c = firstAccount.Id,
                                                                              Grade_Level__c = 'Eighth Grade',
                                                                              Education_History__c = eduHist.Id);

            Grade_Enrollment__c gradeEnrollMishMatching = new Grade_Enrollment__c(Contact__c = testContact.Id,
                                                                                  Educational_Institution__c = secondAccount.Id,
                                                                                  Grade_Level__c = 'Eighth Grade',
                                                                                  Education_History__c = eduHist.Id);

            gradeEnrollmentsList.add(gradeEnrollMatching);
            gradeEnrollmentsList.add(gradeEnrollMishMatching);
        }

        insert gradeEnrollmentsList;

        for (hed__Education_History__c oldEdHist : educationHistoryList){
            oldSObjectsList.add((SObject)oldEdHist);

            hed__Education_History__c newEdHist = oldEdHist.clone(true);
            newEdHist.hed__Account__c = firstAccount.Id;
            newSObjectsList.add((SObject)newEdHist);
        }

        EDUHIS_DataInteg_TDTM eduHisTdtm = new EDUHIS_DataInteg_TDTM();

        Test.startTest();
        eduHisTdtm.checkForGradeEnrollmentEducationalInstitutionMismatch(newSObjectsList, oldSObjectsList); // does not throw exception because not in trigger context
        Test.stopTest();

        ApexPages.Message[] errorMessages = ApexPages.getMessages();
        System.assertEquals(true, errorMessages.isEmpty() == false, 'Mismatching Educational Institutions should result in error.'); 
        
        for (ApexPages.Message msg : errorMessages){
            System.assertEquals(Label.EduHisInstitutionMismatch, msg.getSummary(), 'Mis-matching values for Education Institution on Education History and Grade Enrollment should display error message.');
        }    
    }

    /*********************************************************************************************************
    * @description Test to verify that method checkForGradeEnrollmentEducationalInstitutionMismatch() 
    * successfully processes an update to the Educational Institution on an Education History record when it
    * matches the value for the Institution specified on the related Grade Enrollment.
    *********************************************************************************************************/
    @isTest 
    private static void checkForMismatchNullEduHistInstitution(){
        hed__Hierarchy_Settings__c hs = hed.UTIL_CustomSettings_API.getSettings();
        String adminRecordType = hs.hed__Administrative_Account_Record_Type__c;

        List<SObject> newSObjectsList = new List<SObject>();
        List<SObject> oldSObjectsList = new List<SObject>();

        List<Account> accountsList = new List<Account>();
        List<Grade_Enrollment__c> gradeEnrollmentsList = new List<Grade_Enrollment__c>();

        Account firstAccount = new Account(RecordTypeId = adminRecordType, Name = 'Test Account 1');
        Account secondAccount = new Account(RecordTypeId = adminRecordType, Name = 'Test Account 2');
        accountsList.add(firstAccount);
        accountsList.add(secondAccount);

        insert accountsList;

        Contact testContact = new Contact(LastName = 'Testerson');
        insert testContact;

        List<hed__Education_History__c> educationHistoryList = new List<hed__Education_History__c>();
        for (Integer i = 0; i < 5; i++){
            hed__Education_History__c eduHist = new hed__Education_History__c(hed__Contact__c = testContact.Id,
                                                                              hed__Account__c = firstAccount.Id
                                                                             );
            educationHistoryList.add(eduHist);
        }
       
        insert educationHistoryList;

        for (hed__Education_History__c eduHist : educationHistoryList){
            Grade_Enrollment__c gradeEnroll = new Grade_Enrollment__c(Contact__c = testContact.Id,
                                                                      Educational_Institution__c = firstAccount.Id,
                                                                      Grade_Level__c = 'Eighth Grade',
                                                                      Education_History__c = eduHist.Id
                                                                     );

            gradeEnrollmentsList.add(gradeEnroll);
        }

        insert gradeEnrollmentsList;

        for (hed__Education_History__c oldEdHist : educationHistoryList){
            oldSObjectsList.add((SObject)oldEdHist);

            hed__Education_History__c newEdHist = oldEdHist.clone(true);
            newEdHist.hed__Account__c = null;
            newSObjectsList.add((SObject)newEdHist);
        }

        EDUHIS_DataInteg_TDTM eduHisTdtm = new EDUHIS_DataInteg_TDTM();

        Test.startTest();
        List<DmlException> exceptionsList = new List<DmlException>();

        try{
            eduHisTdtm.checkForGradeEnrollmentEducationalInstitutionMismatch(newSObjectsList, oldSObjectsList);
        } catch (DmlException e){
            exceptionsList.add(e);
        }
        Test.stopTest();

        System.assertEquals(true, exceptionsList.isEmpty(), 'Blank Education Institution on Education History should not display an error even if Institution on Grade Enrollment is populated.');
    }
    
    /*********************************************************************************************************
    * @description Test to verify that method run() displays an error message when an update to the Educational 
    * Institution on an Education History record does not match the Institutions specified on the related 
    * Grade Enrollment record.
    *********************************************************************************************************/
    @isTest 
    private static void runWithNoUpdate(){
        hed.TDTM_Runnable.Action triggerAction = hed.TDTM_Runnable.Action.BeforeUpdate;
        Schema.DescribeSObjectResult objResult = Schema.SObjectType.hed__Education_History__c;

        hed__Hierarchy_Settings__c hs = hed.UTIL_CustomSettings_API.getSettings();
        String adminRecordType = hs.hed__Administrative_Account_Record_Type__c;

        List<Account> accountsList = new List<Account>();
        List<Grade_Enrollment__c> gradeEnrollmentsList = new List<Grade_Enrollment__c>();
        List<SObject> newSObjectsList = new List<SObject>();
        List<SObject> oldSObjectsList = new List<SObject>();

        Account firstAccount = new Account(RecordTypeId = adminRecordType, Name = 'Test Account 1');
        Account secondAccount = new Account(RecordTypeId = adminRecordType, Name = 'Test Account 2');
        accountsList.add(firstAccount);
        accountsList.add(secondAccount);

        insert accountsList;

        Contact testContact = new Contact(LastName = 'Testerson');
        insert testContact;

        List<hed__Education_History__c> educationHistoryList = new List<hed__Education_History__c>();
        for (Integer i = 0; i < 5; i++){
            hed__Education_History__c eduHist = new hed__Education_History__c(hed__Contact__c = testContact.Id,
                                                                              hed__Account__c = firstAccount.Id
                                                                             );
            educationHistoryList.add(eduHist);
        }
       
        insert educationHistoryList;

        for (hed__Education_History__c eduHist : educationHistoryList){
            Grade_Enrollment__c gradeEnroll = new Grade_Enrollment__c(Contact__c = testContact.Id,
                                                                      Educational_Institution__c = firstAccount.Id,
                                                                      Grade_Level__c = 'Eighth Grade',
                                                                      Education_History__c = eduHist.Id
                                                                     );

            gradeEnrollmentsList.add(gradeEnroll);
        }

        insert gradeEnrollmentsList;

        for (hed__Education_History__c oldEdHist : educationHistoryList){
            oldSObjectsList.add((SObject)oldEdHist);

            hed__Education_History__c newEdHist = oldEdHist.clone(true);
            newEdHist.hed__Account__c = secondAccount.Id;
            newSObjectsList.add((SObject)newEdHist);
        }

        EDUHIS_DataInteg_TDTM eduHisTdtm = new EDUHIS_DataInteg_TDTM();

        Test.startTest();
        try {
            eduHisTdtm.run(newSObjectsList, oldSObjectsList, triggerAction, objResult);
        } catch (DmlException e){
            System.assertEquals(Label.EduHisInstitutionMismatch, e.getMessage(), 'Updates with mismatching Education Institution for Education History and Grade Enrollment should display an error.');
        }
        Test.stopTest();
    }

    /*********************************************************************************************************
    * @description Test to verify that method run() successfully processes an update to the Edcuational 
    * Institution on an Education History record when it matches the value specified for the related Grade 
    * Enrollment record.
    *********************************************************************************************************/
    @isTest 
    private static void runWithUpdate(){
        hed.TDTM_Runnable.Action triggerAction = hed.TDTM_Runnable.Action.BeforeUpdate;
        Schema.DescribeSObjectResult objResult = Schema.SObjectType.hed__Education_History__c;

        hed__Hierarchy_Settings__c hs = hed.UTIL_CustomSettings_API.getSettings();
        String adminRecordType = hs.hed__Administrative_Account_Record_Type__c;

        List<Account> accountsList = new List<Account>();
        List<Grade_Enrollment__c> gradeEnrollmentsList = new List<Grade_Enrollment__c>();
        List<SObject> newSObjectsList = new List<SObject>();
        List<SObject> oldSObjectsList = new List<SObject>();

        Account firstAccount = new Account(RecordTypeId = adminRecordType, Name = 'Test Account 1');
        Account secondAccount = new Account(RecordTypeId = adminRecordType, Name = 'Test Account 2');
        accountsList.add(firstAccount);
        accountsList.add(secondAccount);

        insert accountsList;

        Contact testContact = new Contact(LastName = 'Testerson');
        insert testContact;

        List<hed__Education_History__c> educationHistoryList = new List<hed__Education_History__c>();
        for (Integer i = 0; i < 5; i++){
            hed__Education_History__c eduHist = new hed__Education_History__c(hed__Contact__c = testContact.Id,
                                                                              hed__Account__c = secondAccount.Id
                                                                             );
            educationHistoryList.add(eduHist);
        }
       
        insert educationHistoryList;

        for (hed__Education_History__c eduHist : educationHistoryList){
            Grade_Enrollment__c gradeEnroll = new Grade_Enrollment__c(Contact__c = testContact.Id,
                                                                      Educational_Institution__c = secondAccount.Id,
                                                                      Grade_Level__c = 'Eighth Grade',
                                                                      Education_History__c = eduHist.Id
                                                                     );

            gradeEnrollmentsList.add(gradeEnroll);
        }

        insert gradeEnrollmentsList;

        for (hed__Education_History__c newEdHist : educationHistoryList){
            newSObjectsList.add((SObject)newEdHist);

            hed__Education_History__c oldEdHist = newEdHist.clone(true);
            oldEdHist.hed__Account__c = firstAccount.Id;
            oldSObjectsList.add((SObject)oldEdHist);
        }

        EDUHIS_DataInteg_TDTM eduHisTdtm = new EDUHIS_DataInteg_TDTM();

        Test.startTest();
        List<DmlException> exceptionsList = new List<DmlException>();

        try{
            eduHisTdtm.run(newSObjectsList, oldSObjectsList, triggerAction, objResult);
        } catch (DmlException e){
            exceptionsList.add(e);
        }
        Test.stopTest();

        System.assertEquals(true, exceptionsList.isEmpty(), 'Updates with matching Education Institution for Education History and Grade Enrollment should not display an error.');
       

        List<hed__Education_History__c> eduHistoryResultsList = [SELECT Id,
                                                                        Name,
                                                                        hed__Account__c,
                                                                        (SELECT Contact__c, Educational_Institution__c 
                                                                        FROM Grade_Enrollments__r)
                                                                FROM hed__Education_History__c
                                                                WHERE Id IN :educationHistoryList];

        for (hed__Education_History__c eduHist : eduHistoryResultsList){
            System.assertEquals(secondAccount.Id, eduHist.hed__Account__c, 'Education Institution update should occur for Education History with no mismatching Grade Enrollments.');
        }
    }

    /*********************************************************************************************************
    * @description Test to verify that method run() does not result in errors when null SObject lists are 
    * provided as parameters.
    *********************************************************************************************************/
    @isTest 
    private static void runWithNullLists(){
        hed.TDTM_Runnable.Action triggerAction = hed.TDTM_Runnable.Action.BeforeInsert;
        Schema.DescribeSObjectResult objResult = Schema.SObjectType.hed__Education_History__c;

        Test.startTest();
        EDUHIS_DataInteg_TDTM eduHisTdtm = new EDUHIS_DataInteg_TDTM();
        List<DmlException> exceptionsList = new List<DmlException>();

        try{
            eduHisTdtm.run(null, null, triggerAction, objResult);
        } catch (DmlException e){
            exceptionsList.add(e);
        }
        Test.stopTest();

        System.assertEquals(true, exceptionsList.isEmpty(), 'Execution caused by a null list should not display an error message.');

    }
}