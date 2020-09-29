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

    /**********************************************************************************************************
    * @description Setup configuration for all tests cases.  Loads EDA and K12 triggers.
    **********************************************************************************************************/ 
    @testSetup
    private static void testSetup() {
        //Insert EDA Trigger Handlers
        List<hed.TDTM_Global_API.TdtmToken> edaTokens = hed.TDTM_Global_API.getDefaultTdtmConfig();
        hed.TDTM_Global_API.setTdtmConfig(edaTokens);

        //Insert K12 trigger handlers
        STG_InstallScript.setK12kitDefaultTriggerHandlers();
    }

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
        Database.SaveResult[] results = Database.update(educationHistoryList, false);
        Test.stopTest();

        for (Database.SaveResult sr : results){
            System.assertEquals(true, sr.isSuccess(), 'Education History update should succeed.');
            System.assertEquals(true, sr.getErrors().isEmpty(), 'Update for Education History should have no errors.');
        }

        List<hed__Education_History__c> educationHistoryResultsList = [SELECT Id,
                                                                              hed__Account__c
                                                                       FROM hed__Education_History__c
                                                                       WHERE Id IN: educationHistoryList];

        for (hed__Education_History__c eduHist : educationHistoryResultsList){
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
        Database.SaveResult[] results = Database.update(educationHistoryList, false);
        Test.stopTest();

        for (Database.SaveResult sr : results){
            System.assertEquals(true, sr.isSuccess(), 'Education History update should succeed.');
            System.assertEquals(true, sr.getErrors().isEmpty(), 'Update for Education History should have no errors.');
        }

        List<hed__Education_History__c> educationHistoryResultsList = [SELECT Id,
                                                                              hed__Account__c
                                                                       FROM hed__Education_History__c
                                                                       WHERE Id IN: educationHistoryList];

        for (hed__Education_History__c eduHist : educationHistoryResultsList){
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
            Grade_Enrollment__c gradeEnrollMatching = new Grade_Enrollment__c(Contact__c = testContact.Id,
                                                                              Educational_Institution__c = firstAccount.Id,
                                                                              Grade_Level__c = 'Eighth Grade',
                                                                              Education_History__c = eduHist.Id);

            Grade_Enrollment__c gradeEnrollNull = new Grade_Enrollment__c(Contact__c = testContact.Id,
                                                                          Educational_Institution__c = null,
                                                                          Grade_Level__c = 'Eighth Grade',
                                                                          Education_History__c = eduHist.Id);

            gradeEnrollmentsList.add(gradeEnrollMatching);
            gradeEnrollmentsList.add(gradeEnrollNull);

            eduHist.hed__Account__c = firstAccount.Id;
        }

        insert gradeEnrollmentsList;

        Test.startTest();
        Database.SaveResult[] results = Database.update(educationHistoryList, false);
        Test.stopTest();

        for (Database.SaveResult sr : results){
            System.assertEquals(true, sr.isSuccess(), 'Education History update should succeed.');
            System.assertEquals(true, sr.getErrors().isEmpty(), 'Update for Education History should have no errors.');
        }

        List<hed__Education_History__c> educationHistoryResultsList = [SELECT Id,
                                                                              hed__Account__c
                                                                       FROM hed__Education_History__c
                                                                       WHERE Id IN: educationHistoryList];

        for (hed__Education_History__c eduHist : educationHistoryResultsList){
            System.assertEquals(firstAccount.Id, eduHist.hed__Account__c, 'Matching Educational Institution should update for Education History with Grade Enrollment.');
        }
    }

    /*********************************************************************************************************
    * @description Tests to verify that changing the Educational Institution on an Education History record
    * to a value that does not match the value specified on the related Grade Enrollment
    *********************************************************************************************************/
    @isTest
    public static void updateEducationHistoryWithGradeEnrollmentsMisMatching() {
        EDUHIS_DataInteg_TEST.disableGradeEnrollDataIntegTrigger();

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
            Grade_Enrollment__c gradeEnrollMatch = new Grade_Enrollment__c(Contact__c = testContact.Id,
                                                                              Educational_Institution__c = secondAccount.Id,
                                                                              Grade_Level__c = 'Eighth Grade',
                                                                              Education_History__c = eduHist.Id);

            Grade_Enrollment__c gradeEnrollMismatch = new Grade_Enrollment__c(Contact__c = testContact.Id,
                                                                              Educational_Institution__c = firstAccount.Id,
                                                                              Grade_Level__c = 'Eighth Grade',
                                                                              Education_History__c = eduHist.Id);

            gradeEnrollmentsList.add(gradeEnrollMatch);
            gradeEnrollmentsList.add(gradeEnrollMismatch);

            eduHist.hed__Account__c = secondAccount.Id;
        }

        insert gradeEnrollmentsList;

        Test.startTest();
        Database.SaveResult[] results = Database.update(educationHistoryList, false);
        Test.stopTest();

        for (Database.SaveResult sr : results){
            System.assertEquals(false, sr.isSuccess(), 'Education History update should fail.');
            for (Database.Error err : sr.getErrors()){
                System.assertEquals(Label.EduHisInstitutionMismatch, err.getMessage(), 'Updating Education History with mismatched Institution should display error message.');
            }
        }

        List<hed__Education_History__c> educationHistoryResultsList = [SELECT Id,
                                                                              hed__Account__c
                                                                       FROM hed__Education_History__c
                                                                       WHERE Id IN: educationHistoryList];

        for (hed__Education_History__c eduHist : educationHistoryResultsList){
            System.assertEquals(firstAccount.Id, eduHist.hed__Account__c, 'Educational Institution on Education History should not update.');
        }
    }
    /*********************************************************************************************************
    * @description Tests to verify that clearing the Educational Institution on an Education History record
    * with a related Grade Enrollment updates even when the Grade Enrollment institution field is not blank.
    *********************************************************************************************************/
    @isTest
    public static void updateEducationHistoryWithGradeEnrollmentBlankInstitutionOnEducationHistory() {        
        EDUHIS_DataInteg_TEST.disableGradeEnrollDataIntegTrigger();
        
        hed__Hierarchy_Settings__c hs = hed.UTIL_CustomSettings_API.getSettings();
        String adminRecordType = hs.hed__Administrative_Account_Record_Type__c;

        List<Grade_Enrollment__c> gradeEnrollmentsList = new List<Grade_Enrollment__c>();
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
            Grade_Enrollment__c gradeEnroll1 = new Grade_Enrollment__c(Contact__c = testContact.Id,
                                                                      Educational_Institution__c = firstAccount.Id,
                                                                      Grade_Level__c = 'Eighth Grade',
                                                                      Education_History__c = eduHist.Id
                                                                     );

            Grade_Enrollment__c gradeEnroll2 = new Grade_Enrollment__c(Contact__c = testContact.Id,
                                                                      Educational_Institution__c = secondAccount.Id,
                                                                      Grade_Level__c = 'Eighth Grade',
                                                                      Education_History__c = eduHist.Id
                                                                     );

            gradeEnrollmentsList.add(gradeEnroll1);
            gradeEnrollmentsList.add(gradeEnroll2);

            eduHist.hed__Account__c = null;
        }

        insert gradeEnrollmentsList;

        Test.startTest();
        Database.SaveResult[] results = Database.update(educationHistoryList, false);
        Test.stopTest();

        for (Database.SaveResult sr : results){
            System.assertEquals(true, sr.isSuccess(), 'Education History update should succeed.');
            System.assertEquals(true, sr.getErrors().isEmpty(), 'Updating Education History with mismatched Institution for null value should not display error message.');
        }

        List<hed__Education_History__c> educationHistoryResultsList = [SELECT Id,
                                                                              hed__Account__c
                                                                       FROM hed__Education_History__c
                                                                       WHERE Id IN: educationHistoryList];

        for (hed__Education_History__c eduHist : educationHistoryResultsList){
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
            for (Integer i = 0; i < 5; i++){
                Grade_Enrollment__c gradeEnroll = new Grade_Enrollment__c(Contact__c = testContact.Id,
                                                                        Educational_Institution__c = null,
                                                                        Grade_Level__c = 'Eighth Grade',
                                                                        Education_History__c = eduHist.Id
                                                                        );

                gradeEnrollmentsList.add(gradeEnroll);
            }
            eduHist.hed__Account__c = secondAccount.Id;
        }

        insert gradeEnrollmentsList;

        Test.startTest();
        Database.SaveResult[] results = Database.update(educationHistoryList, false);
        Test.stopTest();

        for (Database.SaveResult sr : results){
            System.assertEquals(true, sr.isSuccess(), 'Education History update should succeed.');
            System.assertEquals(true, sr.getErrors().isEmpty(), 'Updating Education History with mismatched Institution for null value should not display error message.');
        }

        List<hed__Education_History__c> educationHistoryResultsList = [SELECT Id,
                                                                              hed__Account__c
                                                                       FROM hed__Education_History__c
                                                                       WHERE Id IN: educationHistoryList];

        for (hed__Education_History__c eduHist : educationHistoryResultsList){
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
            for (Integer i = 0; i < 5; i++){
                Grade_Enrollment__c gradeEnroll = new Grade_Enrollment__c(Contact__c = testContact.Id,
                                                                          Educational_Institution__c = null,
                                                                          Grade_Level__c = 'Eighth Grade',
                                                                          Education_History__c = eduHist.Id);
                gradeEnrollmentsList.add(gradeEnroll);
            }
            eduHist.hed__Account__c = null;
        }

        insert gradeEnrollmentsList;

        Test.startTest();
        Database.SaveResult[] results = Database.update(educationHistoryList, false);
        Test.stopTest();

        for (Database.SaveResult sr : results){
            System.assertEquals(true, sr.isSuccess(), 'Education History update should succeed.');
            System.assertEquals(true, sr.getErrors().isEmpty(), 'Updating Education History with mismatched Institution for null value should not display error message.');
        }

        List<hed__Education_History__c> educationHistoryResultsList = [SELECT Id,
                                                                              hed__Account__c
                                                                       FROM hed__Education_History__c
                                                                       WHERE Id IN: educationHistoryList];

        for (hed__Education_History__c eduHist : educationHistoryResultsList){
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
        EDUHIS_DataInteg_TEST.disableGradeEnrollDataIntegTrigger();

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
            for (Integer i = 0; i < 5; i++){
                Grade_Enrollment__c gradeEnrollMatching = new Grade_Enrollment__c(Contact__c = testContact.Id,
                                                                                  Educational_Institution__c = secondAccount.Id,
                                                                                  Grade_Level__c = 'Eighth Grade',
                                                                                  Education_History__c = eduHist.Id);
                gradeEnrollmentsList.add(gradeEnrollMatching);
            }

            Grade_Enrollment__c gradeEnrollNull = new Grade_Enrollment__c(Contact__c = testContact.Id,
                                                                          Educational_Institution__c = null,
                                                                          Grade_Level__c = 'Eighth Grade',
                                                                          Education_History__c = eduHist.Id);

            gradeEnrollmentsList.add(gradeEnrollNull);
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
        List<hed__Education_History__c> eduHistoryWithErrorsList = new List<hed__Education_History__c>();
        eduHistoryWithErrorsList = eduHisTdtm.checkForGradeEnrollmentEducationalInstitutionMismatch(newSObjectsList, oldSObjectsList);
        Test.stopTest();

        ApexPages.Message[] errorMessages = ApexPages.getMessages();
        System.assertEquals(true, errorMessages.isEmpty(), 'Matching Educational Institutions should not result in error.'); 
        System.assertEquals(true, eduHistoryWithErrorsList.isEmpty(), 'There should be no Education History records with errors.');
    }

    /*********************************************************************************************************
    * @description Test to verify that method checkForGradeEnrollmentEducationalInstitutionMismatch() 
    * displays and error message when the Edcuational Institution on an Education History record 
    * is updated to a value that does not match the Institution specified on the related Grade Enrollment.
    *********************************************************************************************************/
    @isTest 
    private static void checkForMismatchFound(){

        EDUHIS_DataInteg_TEST.disableGradeEnrollDataIntegTrigger();

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
                                                                              Educational_Institution__c = secondAccount.Id,
                                                                              Grade_Level__c = 'Eighth Grade',
                                                                              Education_History__c = eduHist.Id);

            Grade_Enrollment__c gradeEnrollMatching2 = new Grade_Enrollment__c(Contact__c = testContact.Id,
                                                                                  Educational_Institution__c = secondAccount.Id,
                                                                                  Grade_Level__c = 'Eighth Grade',
                                                                                  Education_History__c = eduHist.Id);

            Grade_Enrollment__c gradeEnrollNull = new Grade_Enrollment__c(Contact__c = testContact.Id,
                                                                          Educational_Institution__c = null,
                                                                          Grade_Level__c = 'Eighth Grade',
                                                                          Education_History__c = eduHist.Id);

            gradeEnrollmentsList.add(gradeEnrollMatching);
            gradeEnrollmentsList.add(gradeEnrollMatching2);
            gradeEnrollmentsList.add(gradeEnrollNull);
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
        List<hed__Education_History__c> eduHistoryWithErrorsList = new List<hed__Education_History__c>();
        eduHistoryWithErrorsList = eduHisTdtm.checkForGradeEnrollmentEducationalInstitutionMismatch(newSObjectsList, oldSObjectsList); 
        Test.stopTest();

        ApexPages.Message[] errorMessages = ApexPages.getMessages();
        System.assertEquals(false, errorMessages.isEmpty(), 'Mismatching Educational Institutions should result in error.'); 
        System.assertEquals(5, eduHistoryWithErrorsList.size(), 'All 5 Education History records should be associated with an error.');
        
        for (ApexPages.Message msg : errorMessages){
            System.assertEquals(Label.EduHisInstitutionMismatch, msg.getSummary(), 'Mis-matching values for Education Institution on Education History and Grade Enrollment should display a mismatched Institution error.');
        }    
    }

    /*********************************************************************************************************
    * @description Test to verify that method checkForGradeEnrollmentEducationalInstitutionMismatch() 
    * successfully processes an update to the Educational Institution on an Education History record when it
    * is set to null, regardless of the values specified for the Institution on related Grade Enrollments.
    *********************************************************************************************************/
    @isTest 
    private static void checkForMismatchNullEduHistInstitution(){
        EDUHIS_DataInteg_TEST.disableGradeEnrollDataIntegTrigger();

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
            Grade_Enrollment__c gradeEnroll1 = new Grade_Enrollment__c(Contact__c = testContact.Id,
                                                                      Educational_Institution__c = firstAccount.Id,
                                                                      Grade_Level__c = 'Eighth Grade',
                                                                      Education_History__c = eduHist.Id);

            Grade_Enrollment__c gradeEnroll2 = new Grade_Enrollment__c(Contact__c = testContact.Id,
                                                                     Educational_Institution__c = firstAccount.Id,
                                                                     Grade_Level__c = 'Eighth Grade',
                                                                     Education_History__c = eduHist.Id);

            Grade_Enrollment__c gradeEnrollNull = new Grade_Enrollment__c(Contact__c = testContact.Id,
                                                                          Educational_Institution__c = null,
                                                                          Grade_Level__c = 'Eighth Grade',
                                                                          Education_History__c = eduHist.Id);
            gradeEnrollmentsList.add(gradeEnroll1);
            gradeEnrollmentsList.add(gradeEnroll2);
            gradeEnrollmentsList.add(gradeEnrollNull);
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
        List<hed__Education_History__c> eduHistoryWithErrorsList = new List<hed__Education_History__c>();
        eduHistoryWithErrorsList = eduHisTdtm.checkForGradeEnrollmentEducationalInstitutionMismatch(newSObjectsList, oldSObjectsList);
        Test.stopTest();

        ApexPages.Message[] errorMessages = ApexPages.getMessages();
        System.assertEquals(true, errorMessages.isEmpty(), 'Mismatching Educational Institutions with null values should not result in error.'); 
        System.assertEquals(true, eduHistoryWithErrorsList.isEmpty(), 'None of the Education History records should be associated with an error.');
    }

    /*********************************************************************************************************
    * @description Test to verify that method run() successfully processes an update to the Edcuational 
    * Institution on an Education History record when it matches the value specified for the related Grade 
    * Enrollment record.
    *********************************************************************************************************/
    @isTest 
    private static void runWithUpdateMatching(){
        EDUHIS_DataInteg_TEST.disableGradeEnrollDataIntegTrigger();

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
                                                                              hed__Account__c = secondAccount.Id);
            educationHistoryList.add(eduHist);
        }
       
        insert educationHistoryList;

        for (hed__Education_History__c eduHist : educationHistoryList){
            for (Integer i = 0; i < 5; i++){
                Grade_Enrollment__c gradeEnrollMatching = new Grade_Enrollment__c(Contact__c = testContact.Id,
                                                                               Educational_Institution__c = secondAccount.Id,
                                                                               Grade_Level__c = 'Eighth Grade',
                                                                               Education_History__c = eduHist.Id);
                gradeEnrollmentsList.add(gradeEnrollMatching);
            }
            
            Grade_Enrollment__c gradeEnrollNull = new Grade_Enrollment__c(Contact__c = testContact.Id,
                                                                          Educational_Institution__c = null,
                                                                          Grade_Level__c = 'Eighth Grade',
                                                                          Education_History__c = eduHist.Id);

            gradeEnrollmentsList.add(gradeEnrollNull);
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
        eduHisTdtm.run(newSObjectsList, oldSObjectsList, triggerAction, objResult);
        Test.stopTest();

        ApexPages.Message[] errorMessages = ApexPages.getMessages();
        System.assertEquals(true, errorMessages.isEmpty(), 'Updates with matching Education Institution for Education History and Grade Enrollment should not display an error.'); 

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
    * @description Test to verify that method run() displays an error when an update to the Edcuational 
    * Institution on an Education History record does not match the value specified for the related Grade 
    * Enrollment record.
    *********************************************************************************************************/
    @isTest 
    private static void runWithNoUpdateMismatching(){

        EDUHIS_DataInteg_TEST.disableGradeEnrollDataIntegTrigger();

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
            Grade_Enrollment__c gradeEnrollMatching = new Grade_Enrollment__c(Contact__c = testContact.Id,
                                                                              Educational_Institution__c = secondAccount.Id,
                                                                              Grade_Level__c = 'Eighth Grade',
                                                                              Education_History__c = eduHist.Id);

            Grade_Enrollment__c gradeEnrollMatching2 = new Grade_Enrollment__c(Contact__c = testContact.Id,
                                                                                 Educational_Institution__c = secondAccount.Id,
                                                                                 Grade_Level__c = 'Eighth Grade',
                                                                                 Education_History__c = eduHist.Id);

            Grade_Enrollment__c gradeEnrollNull = new Grade_Enrollment__c(Contact__c = testContact.Id,
                                                                          Educational_Institution__c = null,
                                                                          Grade_Level__c = 'Eighth Grade',
                                                                          Education_History__c = eduHist.Id);
            gradeEnrollmentsList.add(gradeEnrollMatching);
            gradeEnrollmentsList.add(gradeEnrollMatching2);
            gradeEnrollmentsList.add(gradeEnrollNull);
        }

        insert gradeEnrollmentsList;

        for (hed__Education_History__c newEdHist : educationHistoryList){
            hed__Education_History__c oldEdHist = newEdHist.clone(true);
            oldSObjectsList.add((SObject)oldEdHist);

            newEdHist.hed__Account__c = firstAccount.Id;
            newSObjectsList.add((SObject)newEdHist);
        }

        EDUHIS_DataInteg_TDTM eduHisTdtm = new EDUHIS_DataInteg_TDTM();
        Test.startTest();
        eduHisTdtm.run(newSObjectsList, oldSObjectsList, triggerAction, objResult);
        Test.stopTest();

        ApexPages.Message[] errorMessages = ApexPages.getMessages();
        System.assertEquals(false, errorMessages.isEmpty(), 'Mismatching Educational Institutions should result in error.'); 
        
        for (ApexPages.Message msg : errorMessages){
            System.assertEquals(Label.EduHisInstitutionMismatch, msg.getSummary(), 'Mis-matching values for Education Institution on Education History and Grade Enrollment should display error message.');
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

        EDUHIS_DataInteg_TDTM eduHisTdtm = new EDUHIS_DataInteg_TDTM();

        Test.startTest();
        System.assertEquals(null, eduHisTdtm.run(null, null, triggerAction, objResult), 'Execution caused by null lists should return null.');
        Test.stopTest();

        ApexPages.Message[] errorMessages = ApexPages.getMessages();
        System.assertEquals(true, errorMessages.isEmpty(), 'Execution of rung with null lists should not result in errors.'); 
    }

    /**********************************************************************************************************
    * @description Disables the Grade Enrollments Data Integrity triggers to prevent conflicts and allow 
    * thorough testing of Education History trigger functionality.
    **********************************************************************************************************/
    private static void disableGradeEnrollDataIntegTrigger(){
        for (hed.TDTM_Global_API.TdtmToken tdtmToken : hed.TDTM_Global_API.getTdtmConfig()){
            if (tdtmToken.className == UTIL_Namespace.StrTokenNSPrefixDotNotation('GRER_DataInteg_TDTM')){
                tdtmToken.active = false;
            }
        }
    }
}