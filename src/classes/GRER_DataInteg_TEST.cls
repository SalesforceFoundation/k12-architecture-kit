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
* @description Tests for GRER_SyncGradeLevel_TDTM class*/
@isTest
private class GRER_DataInteg_TEST {
    
    @testSetup
    static void setup() {
        //Insert EDA Trigger Handlers
        List<hed.TDTM_Global_API.TdtmToken> tokens = hed.TDTM_Global_API.getTdtmConfig();
        tokens.add(new hed.TDTM_Global_API.TdtmToken('GRER_DataInteg_TDTM', 'Grade_Enrollment__c', 'BeforeUpdate;BeforeInsert', 1.00));

        hed.TDTM_Global_API.setTdtmConfig(tokens);

        //Insert K12 trigger handlers
        STG_InstallScript.setK12kitDefaultTriggerHandlers();
    }

    /*********************************************************************************************************
    *****************************************FUNCTIONAL TESTS*************************************************
    **********************************************************************************************************/

    /*********************************************************************************************************
    * @description Tests to verify that changing the Educational Institution on an Education History record
    * with no related Grade Enrollments updates without an error.
    *********************************************************************************************************/
    // @isTest
    // public static void updateEducationHistoryWithoutGradeEnrollments() {
    //     EDUHIS_DataInteg_TEST.setup();

    //     hed__Hierarchy_Settings__c hs = hed.UTIL_CustomSettings_API.getSettings();
    //     String adminRecordType = hs.hed__Administrative_Account_Record_Type__c;

    //     List<Account> accountsList = new List<Account>();
    //     Account firstAccount = new Account(RecordTypeId = adminRecordType, Name = 'Test Account 1');
    //     Account secondAccount = new Account(RecordTypeId = adminRecordType, Name = 'Test Account 2');
    //     accountsList.add(firstAccount);
    //     accountsList.add(secondAccount);

    //     insert accountsList;

    //     Contact testContact = new Contact(LastName = 'Testerson');
    //     insert testContact;

    //     List<hed__Education_History__c> educationHistoryList = new List<hed__Education_History__c>();
    //     for (Integer i = 0; i < 5; i++){
    //         hed__Education_History__c eduHist = new hed__Education_History__c(hed__Contact__c = testContact.Id,
    //                                                                           hed__Account__c = firstAccount.Id
    //                                                                          );
    //         educationHistoryList.add(eduHist);
    //     }
       
    //     insert educationHistoryList;

    //     for (hed__Education_History__c eduHist : educationHistoryList){
    //         eduHist.hed__Account__c = secondAccount.Id;
    //     }

    //     Test.startTest();
    //     update educationHistoryList;
    //     Test.stopTest();

    //     for (hed__Education_History__c eduHist : educationHistoryList){
    //         System.assertEquals(secondAccount.Id, eduHist.hed__Account__c, 'Educational Institution should update for Education History with no Grade Enrollments');
    //     }
    // }

    // /*********************************************************************************************************
    // * @description Tests to verify that changing the Educational Institution on an Education History record
    // * with related Grade Enrollments associated with matching Institutions updates without an error.
    // *********************************************************************************************************/
    // @isTest
    // public static void updateEducationHistoryWithGradeEnrollmentsMatching() {
    //     EDUHIS_DataInteg_TEST.setup();

    //     hed__Hierarchy_Settings__c hs = hed.UTIL_CustomSettings_API.getSettings();
    //     String adminRecordType = hs.hed__Administrative_Account_Record_Type__c;

    //     List<Account> accountsList = new List<Account>();
    //     List<Grade_Enrollment__c> gradeEnrollmentsList = new List<Grade_Enrollment__c>();

    //     Account firstAccount = new Account(RecordTypeId = adminRecordType, Name = 'Test Account 1');
    //     Account secondAccount = new Account(RecordTypeId = adminRecordType, Name = 'Test Account 2');
    //     accountsList.add(firstAccount);
    //     accountsList.add(secondAccount);

    //     insert accountsList;

    //     Contact testContact = new Contact(LastName = 'Testerson');
    //     insert testContact;

    //     List<hed__Education_History__c> educationHistoryList = new List<hed__Education_History__c>();
    //     for (Integer i = 0; i < 5; i++){
    //         hed__Education_History__c eduHist = new hed__Education_History__c(hed__Contact__c = testContact.Id,
    //                                                                           hed__Account__c = firstAccount.Id
    //                                                                          );
    //         educationHistoryList.add(eduHist);
    //     }
       
    //     insert educationHistoryList;

    //     for (hed__Education_History__c eduHist : educationHistoryList){
    //         eduHist.hed__Account__c = secondAccount.Id;

    //         Grade_Enrollment__c gradeEnroll = new Grade_Enrollment__c(Contact__c = testContact.Id,
    //                                                                   Educational_Institution__c = secondAccount.Id,
    //                                                                   Grade_Level__c = 'Eighth Grade'
    //                                                                  );

    //         gradeEnrollmentsList.add(gradeEnroll);
    //     }

    //     insert gradeEnrollmentsList;

    //     Test.startTest();
    //     update educationHistoryList;
    //     Test.stopTest();

    //     for (hed__Education_History__c eduHist : educationHistoryList){
    //         System.assertEquals(secondAccount.Id, eduHist.hed__Account__c, 'Educational Institution should update for Education History with no Grade Enrollments');
    //     }
    // }

    // /*********************************************************************************************************
    // * @description Tests to verify that changing the Educational Institution on an Education History record
    // * with related Grade Enrollments associated with mis-matching Institutions does not update and displays an error.
    // *********************************************************************************************************/
    // @isTest
    // public static void updateEducationHistoryWithGradeEnrollmentsMismatching() {
    //     EDUHIS_DataInteg_TEST.setup();
    //     hed__Hierarchy_Settings__c hs = hed.UTIL_CustomSettings_API.getSettings();
    //     String adminRecordType = hs.hed__Administrative_Account_Record_Type__c;

    //     List<Account> accountsList = new List<Account>();
    //     List<Grade_Enrollment__c> gradeEnrollmentsList = new List<Grade_Enrollment__c>();

    //     Account firstAccount = new Account(RecordTypeId = adminRecordType, Name = 'Test Account 1');
    //     Account secondAccount = new Account(RecordTypeId = adminRecordType, Name = 'Test Account 2');
    //     accountsList.add(firstAccount);
    //     accountsList.add(secondAccount);

    //     insert accountsList;

    //     Contact testContact = new Contact(LastName = 'Testerson');
    //     insert testContact;

    //     List<hed__Education_History__c> educationHistoryList = new List<hed__Education_History__c>();
    //     for (Integer i = 0; i < 5; i++){
    //         hed__Education_History__c eduHist = new hed__Education_History__c(hed__Contact__c = testContact.Id,
    //                                                                           hed__Account__c = firstAccount.Id
    //                                                                          );
    //         educationHistoryList.add(eduHist);
    //     }
       
    //     insert educationHistoryList;

    //     for (hed__Education_History__c eduHist : educationHistoryList){
    //         Grade_Enrollment__c gradeEnroll = new Grade_Enrollment__c(Contact__c = testContact.Id,
    //                                                                   Educational_Institution__c = firstAccount.Id,
    //                                                                   Grade_Level__c = 'Eighth Grade',
    //                                                                   Education_History__c = eduHist.Id
    //                                                                  );

    //         gradeEnrollmentsList.add(gradeEnroll);
    //         eduHist.hed__Account__c = secondAccount.Id;
    //     }

    //     insert gradeEnrollmentsList;

    //     Test.startTest();
    //     Database.SaveResult[] results = Database.update(educationHistoryList, false);
    //     Test.stopTest();

    //     for(Database.SaveResult sr : results){
    //         System.assertEquals(false, sr.isSuccess(), 'Update on Education History with mismatching Institutions should fail.');
    //         for (Database.Error err : sr.getErrors()){
    //             System.assertEquals(Label.EduHisInstitutionMismatch, err.getMessage(), 'Error message should display for mismatching Educational Institutions.');
    //         }
    //     }
    // }

    // /*********************************************************************************************************
    // * @description Tests to verify that clearing the Educational Institution on an Education History record
    // * with related Grade Enrollments associated with different Institutions does update.
    // *********************************************************************************************************/
    // @isTest
    // public static void updateEducationHistoryWithGradeEnrollmentsBlankInstitutionOnEducationHistory() {
    //     EDUHIS_DataInteg_TEST.setup();
    //     hed__Hierarchy_Settings__c hs = hed.UTIL_CustomSettings_API.getSettings();
    //     String adminRecordType = hs.hed__Administrative_Account_Record_Type__c;

    //     List<Account> accountsList = new List<Account>();
    //     List<Grade_Enrollment__c> gradeEnrollmentsList = new List<Grade_Enrollment__c>();

    //     Account firstAccount = new Account(RecordTypeId = adminRecordType, Name = 'Test Account 1');
    //     Account secondAccount = new Account(RecordTypeId = adminRecordType, Name = 'Test Account 2');
    //     accountsList.add(firstAccount);
    //     accountsList.add(secondAccount);

    //     insert accountsList;

    //     Contact testContact = new Contact(LastName = 'Testerson');
    //     insert testContact;

    //     List<hed__Education_History__c> educationHistoryList = new List<hed__Education_History__c>();
    //     for (Integer i = 0; i < 5; i++){
    //         hed__Education_History__c eduHist = new hed__Education_History__c(hed__Contact__c = testContact.Id,
    //                                                                           hed__Account__c = firstAccount.Id
    //                                                                          );
    //         educationHistoryList.add(eduHist);
    //     }
       
    //     insert educationHistoryList;

    //     for (hed__Education_History__c eduHist : educationHistoryList){
    //         Grade_Enrollment__c gradeEnroll = new Grade_Enrollment__c(Contact__c = testContact.Id,
    //                                                                   Educational_Institution__c = firstAccount.Id,
    //                                                                   Grade_Level__c = 'Eighth Grade',
    //                                                                   Education_History__c = eduHist.Id
    //                                                                  );

    //         gradeEnrollmentsList.add(gradeEnroll);
    //         eduHist.hed__Account__c = null;
    //     }

    //     insert gradeEnrollmentsList;

    //     Test.startTest();
    //     Database.SaveResult[] results = Database.update(educationHistoryList, false);
    //     Test.stopTest();
               
    //     for (hed__Education_History__c eduHist : educationHistoryList){
    //         System.assertEquals(true, String.isBlank(eduHist.hed__Account__c), 'Educational Institution on Education History should update to blank value.');
    //     } 
    // }

    // /*********************************************************************************************************
    // * @description Tests to verify that changing the Educational Institution on an Education History record
    // * with related Grade Enrollments associated with blank values for Institution does update.
    // *********************************************************************************************************/
    // @isTest
    // public static void updateEducationHistoryWithGradeEnrollmentsBlankInstitutionOnGradeEnrollment() {
    //     EDUHIS_DataInteg_TEST.setup();
    //     hed__Hierarchy_Settings__c hs = hed.UTIL_CustomSettings_API.getSettings();
    //     String adminRecordType = hs.hed__Administrative_Account_Record_Type__c;

    //     List<Account> accountsList = new List<Account>();
    //     List<Grade_Enrollment__c> gradeEnrollmentsList = new List<Grade_Enrollment__c>();

    //     Account firstAccount = new Account(RecordTypeId = adminRecordType, Name = 'Test Account 1');
    //     Account secondAccount = new Account(RecordTypeId = adminRecordType, Name = 'Test Account 2');
    //     accountsList.add(firstAccount);
    //     accountsList.add(secondAccount);

    //     insert accountsList;

    //     Contact testContact = new Contact(LastName = 'Testerson');
    //     insert testContact;

    //     List<hed__Education_History__c> educationHistoryList = new List<hed__Education_History__c>();
    //     for (Integer i = 0; i < 5; i++){
    //         hed__Education_History__c eduHist = new hed__Education_History__c(hed__Contact__c = testContact.Id,
    //                                                                           hed__Account__c = firstAccount.Id
    //                                                                          );
    //         educationHistoryList.add(eduHist);
    //     }
       
    //     insert educationHistoryList;

    //     for (hed__Education_History__c eduHist : educationHistoryList){
    //         Grade_Enrollment__c gradeEnroll = new Grade_Enrollment__c(Contact__c = testContact.Id,
    //                                                                   Educational_Institution__c = null,
    //                                                                   Grade_Level__c = 'Eighth Grade',
    //                                                                   Education_History__c = eduHist.Id
    //                                                                  );

    //         gradeEnrollmentsList.add(gradeEnroll);
    //         eduHist.hed__Account__c = secondAccount.Id;
    //     }

    //     insert gradeEnrollmentsList;

    //     Test.startTest();
    //     Database.SaveResult[] results = Database.update(educationHistoryList, false);
    //     Test.stopTest();
               
    //     for (hed__Education_History__c eduHist : educationHistoryList){
    //         System.assertEquals(secondAccount.Id, eduHist.hed__Account__c, 'Educational Institution on Education History should update with blank institution on associated grade enrollment.');
    //     } 
    // }

    // /*********************************************************************************************************
    // * @description Tests to verify that clearing the Educational Institution on an Education History record
    // * with related Grade Enrollments associated with blank values for Institution does update.
    // *********************************************************************************************************/
    // @isTest
    // public static void updateEducationHistoryWithGradeEnrollmentsBlankInstitutionOnBoth() {
    //     EDUHIS_DataInteg_TEST.setup();
    //     hed__Hierarchy_Settings__c hs = hed.UTIL_CustomSettings_API.getSettings();
    //     String adminRecordType = hs.hed__Administrative_Account_Record_Type__c;

    //     List<Account> accountsList = new List<Account>();
    //     List<Grade_Enrollment__c> gradeEnrollmentsList = new List<Grade_Enrollment__c>();

    //     Account firstAccount = new Account(RecordTypeId = adminRecordType, Name = 'Test Account 1');
    //     Account secondAccount = new Account(RecordTypeId = adminRecordType, Name = 'Test Account 2');
    //     accountsList.add(firstAccount);
    //     accountsList.add(secondAccount);

    //     insert accountsList;

    //     Contact testContact = new Contact(LastName = 'Testerson');
    //     insert testContact;

    //     List<hed__Education_History__c> educationHistoryList = new List<hed__Education_History__c>();
    //     for (Integer i = 0; i < 5; i++){
    //         hed__Education_History__c eduHist = new hed__Education_History__c(hed__Contact__c = testContact.Id,
    //                                                                           hed__Account__c = firstAccount.Id
    //                                                                          );
    //         educationHistoryList.add(eduHist);
    //     }
       
    //     insert educationHistoryList;

    //     for (hed__Education_History__c eduHist : educationHistoryList){
    //         Grade_Enrollment__c gradeEnroll = new Grade_Enrollment__c(Contact__c = testContact.Id,
    //                                                                   Educational_Institution__c = null,
    //                                                                   Grade_Level__c = 'Eighth Grade',
    //                                                                   Education_History__c = eduHist.Id
    //                                                                  );

    //         gradeEnrollmentsList.add(gradeEnroll);
    //         eduHist.hed__Account__c = null;
    //     }

    //     insert gradeEnrollmentsList;

    //     Test.startTest();
    //     Database.SaveResult[] results = Database.update(educationHistoryList, false);
    //     Test.stopTest();
               
    //     for (hed__Education_History__c eduHist : educationHistoryList){
    //         System.assertEquals(true, String.isBlank(eduHist.hed__Account__c), 'Educational Institution on Education History should clear with blank institution on associated grade enrollment.');
    //     } 
    // }

    // /*********************************************************************************************************
    // ***********************************************UNIT TESTS*************************************************
    // **********************************************************************************************************/
    
    // /*********************************************************************************************************
    // * @description Test to verify that method hasInstitutionMismatch() returns true when an Education History
    // * record is related to Grade Enrollment records with mismatching Educational Insttitutions.
    // *********************************************************************************************************/
    // @isTest 
    // private static void hasInstitutionMismatchTrue(){
    //     hed__Hierarchy_Settings__c hs = hed.UTIL_CustomSettings_API.getSettings();
    //     String adminRecordType = hs.hed__Administrative_Account_Record_Type__c;

    //     List<Account> accountsList = new List<Account>();
    //     List<Grade_Enrollment__c> gradeEnrollmentsList = new List<Grade_Enrollment__c>();

    //     Account firstAccount = new Account(RecordTypeId = adminRecordType, Name = 'Test Account 1');
    //     Account secondAccount = new Account(RecordTypeId = adminRecordType, Name = 'Test Account 2');
    //     accountsList.add(firstAccount);
    //     accountsList.add(secondAccount);

    //     insert accountsList;

    //     Contact testContact = new Contact(LastName = 'Testerson');
    //     insert testContact;

    //     List<hed__Education_History__c> educationHistoryList = new List<hed__Education_History__c>();
    //     for (Integer i = 0; i < 5; i++){
    //         hed__Education_History__c eduHist = new hed__Education_History__c(hed__Contact__c = testContact.Id,
    //                                                                           hed__Account__c = firstAccount.Id
    //                                                                          );
    //         educationHistoryList.add(eduHist);
    //     }
       
    //     insert educationHistoryList;

    //     for (hed__Education_History__c eduHist : educationHistoryList){
    //         Grade_Enrollment__c gradeEnroll = new Grade_Enrollment__c(Contact__c = testContact.Id,
    //                                                                   Educational_Institution__c = secondAccount.Id,
    //                                                                   Grade_Level__c = 'Eighth Grade',
    //                                                                   Education_History__c = eduHist.Id
    //                                                                  );

    //         gradeEnrollmentsList.add(gradeEnroll);
    //     }

    //     insert gradeEnrollmentsList;

    //     List<hed__Education_History__c> educationHistoryResultsList = [SELECT Id,
    //                                                                           Name,
    //                                                                           hed__Account__c,
    //                                                                           (SELECT Contact__c, Educational_Institution__c 
    //                                                                           FROM Grade_Enrollments__r)
    //                                                                    FROM hed__Education_History__c
    //                                                                    WHERE Id IN :educationHistoryList];

    //     Test.startTest();
    //     EDUHIS_DataInteg_TDTM eduHisTdtm = new EDUHIS_DataInteg_TDTM();
    //     for (hed__Education_History__c eduHist : educationHistoryResultsList){
    //         System.assertEquals(true, eduHisTdtm.hasInstitutionMismatch(eduHist, eduHist.hed__Account__c), 'Education History record should be associated with Grade Enrollments with mismatching institutions.');
    //     }
    //     Test.stopTest();
    // }

    // /*********************************************************************************************************
    // * @description Test to verify that method hasInstitutionMismatch() returns false when an Education History
    // * record is related to Grade Enrollment records with matching Educational Insttitutions.
    // *********************************************************************************************************/
    // @isTest 
    // private static void hasInstitutionMismatchFalse(){
    //     hed__Hierarchy_Settings__c hs = hed.UTIL_CustomSettings_API.getSettings();
    //     String adminRecordType = hs.hed__Administrative_Account_Record_Type__c;
    //     List<Grade_Enrollment__c> gradeEnrollmentsList = new List<Grade_Enrollment__c>();

    //     Account firstAccount = new Account(RecordTypeId = adminRecordType, Name = 'Test Account 1');
    //     insert firstAccount;

    //     Contact testContact = new Contact(LastName = 'Testerson');
    //     insert testContact;

    //     List<hed__Education_History__c> educationHistoryList = new List<hed__Education_History__c>();
    //     for (Integer i = 0; i < 5; i++){
    //         hed__Education_History__c eduHist = new hed__Education_History__c(hed__Contact__c = testContact.Id,
    //                                                                           hed__Account__c = firstAccount.Id
    //                                                                          );
    //         educationHistoryList.add(eduHist);
    //     }
       
    //     insert educationHistoryList;

    //     for (hed__Education_History__c eduHist : educationHistoryList){
    //         Grade_Enrollment__c gradeEnroll = new Grade_Enrollment__c(Contact__c = testContact.Id,
    //                                                                   Educational_Institution__c = firstAccount.Id,
    //                                                                   Grade_Level__c = 'Eighth Grade',
    //                                                                   Education_History__c = eduHist.Id
    //                                                                  );

    //         gradeEnrollmentsList.add(gradeEnroll);
    //     }

    //     insert gradeEnrollmentsList;

    //     List<hed__Education_History__c> educationHistoryResultsList = [SELECT Id,
    //                                                                           Name,
    //                                                                           hed__Account__c,
    //                                                                           (SELECT Contact__c, Educational_Institution__c 
    //                                                                           FROM Grade_Enrollments__r)
    //                                                                    FROM hed__Education_History__c
    //                                                                    WHERE Id IN :educationHistoryList];

    //     Test.startTest();
    //     EDUHIS_DataInteg_TDTM eduHisTdtm = new EDUHIS_DataInteg_TDTM();
    //     for (hed__Education_History__c eduHist : educationHistoryResultsList){
    //         System.assertEquals(false, eduHisTdtm.hasInstitutionMismatch(eduHist, eduHist.hed__Account__c), 'Education History record should not be associated with Grade Enrollments with mismatching institutions.');
    //     }
    //     Test.stopTest();
    // }

    // /*********************************************************************************************************
    // * @description Test to verify that method hasChildRecords() returns true when an Education History
    // * record is related to Grade Enrollment records.
    // *********************************************************************************************************/
    // @isTest 
    // private static void hasChildRecordsTrue(){
    //     hed__Hierarchy_Settings__c hs = hed.UTIL_CustomSettings_API.getSettings();
    //     String adminRecordType = hs.hed__Administrative_Account_Record_Type__c;
    //     List<Grade_Enrollment__c> gradeEnrollmentsList = new List<Grade_Enrollment__c>();

    //     Account firstAccount = new Account(RecordTypeId = adminRecordType, Name = 'Test Account 1');
    //     insert firstAccount;

    //     Contact testContact = new Contact(LastName = 'Testerson');
    //     insert testContact;

    //     List<hed__Education_History__c> educationHistoryList = new List<hed__Education_History__c>();
    //     for (Integer i = 0; i < 5; i++){
    //         hed__Education_History__c eduHist = new hed__Education_History__c(hed__Contact__c = testContact.Id,
    //                                                                           hed__Account__c = firstAccount.Id
    //                                                                          );
    //         educationHistoryList.add(eduHist);
    //     }
       
    //     insert educationHistoryList;

    //     for (hed__Education_History__c eduHist : educationHistoryList){
    //         Grade_Enrollment__c gradeEnroll = new Grade_Enrollment__c(Contact__c = testContact.Id,
    //                                                                   Educational_Institution__c = firstAccount.Id,
    //                                                                   Grade_Level__c = 'Eighth Grade',
    //                                                                   Education_History__c = eduHist.Id
    //                                                                  );

    //         gradeEnrollmentsList.add(gradeEnroll);
    //     }

    //     insert gradeEnrollmentsList;

    //     List<hed__Education_History__c> educationHistoryResultsList = [SELECT Id,
    //                                                                           Name,
    //                                                                           hed__Account__c,
    //                                                                           (SELECT Contact__c, Educational_Institution__c 
    //                                                                           FROM Grade_Enrollments__r)
    //                                                                    FROM hed__Education_History__c
    //                                                                    WHERE Id IN :educationHistoryList];

    //     Test.startTest();
    //     EDUHIS_DataInteg_TDTM eduHisTdtm = new EDUHIS_DataInteg_TDTM();
    //     for (hed__Education_History__c eduHist : educationHistoryResultsList){
    //         System.assertEquals(true, eduHisTdtm.hasChildRecords(eduHist), 'Education History record should associated with child Grade Enrollments records.');
    //     }
    //     Test.stopTest();
    // }

    // /*********************************************************************************************************
    // * @description Test to verify that method hasChildRecords() returns false when an Education History
    // * record is not related to any Grade Enrollment records.
    // *********************************************************************************************************/
    // @isTest 
    // private static void hasChildRecordsFalse(){
    //     hed__Hierarchy_Settings__c hs = hed.UTIL_CustomSettings_API.getSettings();
    //     String adminRecordType = hs.hed__Administrative_Account_Record_Type__c;

    //     Account firstAccount = new Account(RecordTypeId = adminRecordType, Name = 'Test Account 1');
    //     insert firstAccount;

    //     Contact testContact = new Contact(LastName = 'Testerson');
    //     insert testContact;

    //     List<hed__Education_History__c> educationHistoryList = new List<hed__Education_History__c>();
    //     for (Integer i = 0; i < 5; i++){
    //         hed__Education_History__c eduHist = new hed__Education_History__c(hed__Contact__c = testContact.Id,
    //                                                                           hed__Account__c = firstAccount.Id
    //                                                                          );
    //         educationHistoryList.add(eduHist);
    //     }
       
    //     insert educationHistoryList;

    //     List<hed__Education_History__c> educationHistoryResultsList = [SELECT Id,
    //                                                                           Name,
    //                                                                           hed__Account__c,
    //                                                                           (SELECT Contact__c, Educational_Institution__c 
    //                                                                           FROM Grade_Enrollments__r)
    //                                                                    FROM hed__Education_History__c
    //                                                                    WHERE Id IN :educationHistoryList];

    //     Test.startTest();
    //     EDUHIS_DataInteg_TDTM eduHisTdtm = new EDUHIS_DataInteg_TDTM();
    //     for (hed__Education_History__c eduHist : educationHistoryResultsList){
    //         System.assertEquals(false, eduHisTdtm.hasChildRecords(eduHist), 'Education History record should not be associated with child Grade Enrollments records.');
    //     }
    //     Test.stopTest();
    // }

    // /*********************************************************************************************************
    // * @description Test to verify that method handleBeforeUpdate() successfully processes an update to the Edcuational 
    // * Institution on an Education History record when it does not mismatch with any of the Institutions specified
    // * on the related Grade Enrollment records.
    // *********************************************************************************************************/
    // @isTest 
    // private static void handleBeforeUpdateWithoutMismatch(){
    //     hed__Hierarchy_Settings__c hs = hed.UTIL_CustomSettings_API.getSettings();
    //     String adminRecordType = hs.hed__Administrative_Account_Record_Type__c;

    //     List<Account> accountsList = new List<Account>();
    //     List<Grade_Enrollment__c> gradeEnrollmentsList = new List<Grade_Enrollment__c>();

    //     Account firstAccount = new Account(RecordTypeId = adminRecordType, Name = 'Test Account 1');
    //     Account secondAccount = new Account(RecordTypeId = adminRecordType, Name = 'Test Account 2');
    //     accountsList.add(firstAccount);
    //     accountsList.add(secondAccount);

    //     insert accountsList;

    //     Contact testContact = new Contact(LastName = 'Testerson');
    //     insert testContact;

    //     List<hed__Education_History__c> educationHistoryList = new List<hed__Education_History__c>();
    //     for (Integer i = 0; i < 5; i++){
    //         hed__Education_History__c eduHist = new hed__Education_History__c(hed__Contact__c = testContact.Id,
    //                                                                           hed__Account__c = secondAccount.Id
    //                                                                          );
    //         educationHistoryList.add(eduHist);
    //     }
       
    //     insert educationHistoryList;

    //     for (hed__Education_History__c eduHist : educationHistoryList){
    //         Grade_Enrollment__c gradeEnroll = new Grade_Enrollment__c(Contact__c = testContact.Id,
    //                                                                   Educational_Institution__c = secondAccount.Id,
    //                                                                   Grade_Level__c = 'Eighth Grade',
    //                                                                   Education_History__c = eduHist.Id
    //                                                                  );

    //         gradeEnrollmentsList.add(gradeEnroll);
    //     }

    //     insert gradeEnrollmentsList;

    //     List<SObject> newSObjectsList = new List<SObject>();
    //     List<SObject> oldSObjectsList = new List<SObject>();

    //     for (hed__Education_History__c newEdHist : educationHistoryList){
    //         newSObjectsList.add((SObject)newEdHist);

    //         hed__Education_History__c oldEdHist = newEdHist.clone(true);
    //         oldEdHist.hed__Account__c = firstAccount.Id;
    //         oldSObjectsList.add((SObject)oldEdHist);
    //     }

    //     EDUHIS_DataInteg_TDTM eduHisTdtm = new EDUHIS_DataInteg_TDTM();

    //     Test.startTest();
    //     try {
    //         eduHisTdtm.handleBeforeUpdate(newSObjectsList, oldSObjectsList);
    //     } catch (Exception e){
    //         System.assertEquals(null, e.getMessage(), 'Updates with matching Education Institution for Education History and Grade Enrollment should not display an error.');
    //     }
    //     Test.stopTest();

    //     List<hed__Education_History__c> eduHistoryResultsList = [SELECT Id,
    //                                                                     Name,
    //                                                                     hed__Account__c,
    //                                                                     (SELECT Contact__c, Educational_Institution__c 
    //                                                                     FROM Grade_Enrollments__r)
    //                                                             FROM hed__Education_History__c
    //                                                             WHERE Id IN :educationHistoryList];

    //     for (hed__Education_History__c eduHist : eduHistoryResultsList){
    //         System.assertEquals(secondAccount.Id, eduHist.hed__Account__c, 'Education Institution update should occur for Education History with no mismatching Grade Enrollments.');
    //     }
    // }

    // /*********************************************************************************************************
    // * @description Test to verify that method handleBeforeUpdate() does not process an update to the Edcuational 
    // * Institution on an Education History record when it does not match all Institutions specified
    // * on the related Grade Enrollment records.
    // *********************************************************************************************************/
    // @isTest 
    // private static void handleBeforeUpdateWithMismatch(){
    //     hed__Hierarchy_Settings__c hs = hed.UTIL_CustomSettings_API.getSettings();
    //     String adminRecordType = hs.hed__Administrative_Account_Record_Type__c;

    //     List<Account> accountsList = new List<Account>();
    //     List<Grade_Enrollment__c> gradeEnrollmentsList = new List<Grade_Enrollment__c>();

    //     Account firstAccount = new Account(RecordTypeId = adminRecordType, Name = 'Test Account 1');
    //     Account secondAccount = new Account(RecordTypeId = adminRecordType, Name = 'Test Account 2');
    //     accountsList.add(firstAccount);
    //     accountsList.add(secondAccount);

    //     insert accountsList;

    //     Contact testContact = new Contact(LastName = 'Testerson');
    //     insert testContact;

    //     List<hed__Education_History__c> educationHistoryList = new List<hed__Education_History__c>();
    //     for (Integer i = 0; i < 5; i++){
    //         hed__Education_History__c eduHist = new hed__Education_History__c(hed__Contact__c = testContact.Id,
    //                                                                           hed__Account__c = firstAccount.Id
    //                                                                          );
    //         educationHistoryList.add(eduHist);
    //     }
       
    //     insert educationHistoryList;

    //     for (hed__Education_History__c eduHist : educationHistoryList){
    //         Grade_Enrollment__c gradeEnroll = new Grade_Enrollment__c(Contact__c = testContact.Id,
    //                                                                   Educational_Institution__c = secondAccount.Id,
    //                                                                   Grade_Level__c = 'Eighth Grade',
    //                                                                   Education_History__c = eduHist.Id
    //                                                                  );

    //         gradeEnrollmentsList.add(gradeEnroll);
    //     }

    //     insert gradeEnrollmentsList;

    //     List<SObject> newSObjectsList = new List<SObject>();
    //     List<SObject> oldSObjectsList = new List<SObject>();

    //     for (hed__Education_History__c newEdHist : educationHistoryList){
    //         newSObjectsList.add((SObject)newEdHist);

    //         hed__Education_History__c oldEdHist = newEdHist.clone(true);
    //         oldEdHist.hed__Account__c = secondAccount.Id;
    //         oldSObjectsList.add((SObject)oldEdHist);
    //     }

    //     EDUHIS_DataInteg_TDTM eduHisTdtm = new EDUHIS_DataInteg_TDTM();

    //     Test.startTest();
    //     try {
    //         eduHisTdtm.handleBeforeUpdate(newSObjectsList, oldSObjectsList);
    //     } catch (Exception e){
    //         System.assertEquals(Label.EduHisInstitutionMismatch, e.getMessage(), 'Updates with mismatching Education Institution for Education History and Grade Enrollment should display an error.');
    //     }
    //     Test.stopTest();
    // }
    
    // /*********************************************************************************************************
    // * @description Test to verify that method run() displays an error message when an update to the Edcuational 
    // * Institution on an Education History record does not match all of the Institutions specified
    // * on the related Grade Enrollment records.
    // *********************************************************************************************************/
    // @isTest 
    // private static void runWithNoUpdate(){
    //     hed.TDTM_Runnable.Action triggerAction = hed.TDTM_Runnable.Action.AfterUpdate;
    //     Schema.DescribeSObjectResult objResult = Schema.SObjectType.hed__Education_History__c;

    //     hed__Hierarchy_Settings__c hs = hed.UTIL_CustomSettings_API.getSettings();
    //     String adminRecordType = hs.hed__Administrative_Account_Record_Type__c;

    //     List<Account> accountsList = new List<Account>();
    //     List<Grade_Enrollment__c> gradeEnrollmentsList = new List<Grade_Enrollment__c>();
    //     List<SObject> newSObjectsList = new List<SObject>();
    //     List<SObject> oldSObjectsList = new List<SObject>();

    //     Account firstAccount = new Account(RecordTypeId = adminRecordType, Name = 'Test Account 1');
    //     Account secondAccount = new Account(RecordTypeId = adminRecordType, Name = 'Test Account 2');
    //     accountsList.add(firstAccount);
    //     accountsList.add(secondAccount);

    //     insert accountsList;

    //     Contact testContact = new Contact(LastName = 'Testerson');
    //     insert testContact;

    //     List<hed__Education_History__c> educationHistoryList = new List<hed__Education_History__c>();
    //     for (Integer i = 0; i < 5; i++){
    //         hed__Education_History__c eduHist = new hed__Education_History__c(hed__Contact__c = testContact.Id,
    //                                                                           hed__Account__c = secondAccount.Id
    //                                                                          );
    //         educationHistoryList.add(eduHist);
    //     }
       
    //     insert educationHistoryList;

    //     for (hed__Education_History__c eduHist : educationHistoryList){
    //         Grade_Enrollment__c gradeEnroll = new Grade_Enrollment__c(Contact__c = testContact.Id,
    //                                                                   Educational_Institution__c = firstAccount.Id,
    //                                                                   Grade_Level__c = 'Eighth Grade',
    //                                                                   Education_History__c = eduHist.Id
    //                                                                  );

    //         gradeEnrollmentsList.add(gradeEnroll);
    //     }

    //     insert gradeEnrollmentsList;

    //     for (hed__Education_History__c newEdHist : educationHistoryList){
    //         newSObjectsList.add((SObject)newEdHist);

    //         hed__Education_History__c oldEdHist = newEdHist.clone(true);
    //         oldEdHist.hed__Account__c = firstAccount.Id;
    //         oldSObjectsList.add((SObject)oldEdHist);
    //     }

    //     EDUHIS_DataInteg_TDTM eduHisTdtm = new EDUHIS_DataInteg_TDTM();

    //     Test.startTest();
    //     try {
    //         eduHisTdtm.run(newSObjectsList, oldSObjectsList, triggerAction, objResult);
    //     } catch (Exception e){
    //         System.assertEquals(Label.EduHisInstitutionMismatch, e.getMessage(), 'Updates with mismatching Education Institution for Education History and Grade Enrollment should display an error.');
    //     }
    //     Test.stopTest();
    // }

    // /*********************************************************************************************************
    // * @description Test to verify that method run() successfully processes an update to the Edcuational 
    // * Institution on an Education History record when matches the Institutions specified for all of the 
    // * related Grade Enrollment records.
    // *********************************************************************************************************/
    // @isTest 
    // private static void runWithUpdate(){
    //     hed.TDTM_Runnable.Action triggerAction = hed.TDTM_Runnable.Action.AfterUpdate;
    //     Schema.DescribeSObjectResult objResult = Schema.SObjectType.hed__Education_History__c;

    //     hed__Hierarchy_Settings__c hs = hed.UTIL_CustomSettings_API.getSettings();
    //     String adminRecordType = hs.hed__Administrative_Account_Record_Type__c;

    //     List<Account> accountsList = new List<Account>();
    //     List<Grade_Enrollment__c> gradeEnrollmentsList = new List<Grade_Enrollment__c>();
    //     List<SObject> newSObjectsList = new List<SObject>();
    //     List<SObject> oldSObjectsList = new List<SObject>();

    //     Account firstAccount = new Account(RecordTypeId = adminRecordType, Name = 'Test Account 1');
    //     Account secondAccount = new Account(RecordTypeId = adminRecordType, Name = 'Test Account 2');
    //     accountsList.add(firstAccount);
    //     accountsList.add(secondAccount);

    //     insert accountsList;

    //     Contact testContact = new Contact(LastName = 'Testerson');
    //     insert testContact;

    //     List<hed__Education_History__c> educationHistoryList = new List<hed__Education_History__c>();
    //     for (Integer i = 0; i < 5; i++){
    //         hed__Education_History__c eduHist = new hed__Education_History__c(hed__Contact__c = testContact.Id,
    //                                                                           hed__Account__c = secondAccount.Id
    //                                                                          );
    //         educationHistoryList.add(eduHist);
    //     }
       
    //     insert educationHistoryList;

    //     for (hed__Education_History__c eduHist : educationHistoryList){
    //         Grade_Enrollment__c gradeEnroll = new Grade_Enrollment__c(Contact__c = testContact.Id,
    //                                                                   Educational_Institution__c = secondAccount.Id,
    //                                                                   Grade_Level__c = 'Eighth Grade',
    //                                                                   Education_History__c = eduHist.Id
    //                                                                  );

    //         gradeEnrollmentsList.add(gradeEnroll);
    //     }

    //     insert gradeEnrollmentsList;

    //     for (hed__Education_History__c newEdHist : educationHistoryList){
    //         newSObjectsList.add((SObject)newEdHist);

    //         hed__Education_History__c oldEdHist = newEdHist.clone(true);
    //         oldEdHist.hed__Account__c = firstAccount.Id;
    //         oldSObjectsList.add((SObject)oldEdHist);
    //     }

    //     EDUHIS_DataInteg_TDTM eduHisTdtm = new EDUHIS_DataInteg_TDTM();

    //     Test.startTest();
    //     try {
    //         eduHisTdtm.run(newSObjectsList, oldSObjectsList, triggerAction, objResult);
    //     } catch (Exception e){
    //         System.assertEquals(null, e.getMessage(), 'Updates with matching Education Institution for Education History and Grade Enrollment should not display an error.');
    //     }
    //     Test.stopTest();

    //     List<hed__Education_History__c> eduHistoryResultsList = [SELECT Id,
    //                                                                     Name,
    //                                                                     hed__Account__c,
    //                                                                     (SELECT Contact__c, Educational_Institution__c 
    //                                                                     FROM Grade_Enrollments__r)
    //                                                             FROM hed__Education_History__c
    //                                                             WHERE Id IN :educationHistoryList];

    //     for (hed__Education_History__c eduHist : eduHistoryResultsList){
    //         System.assertEquals(secondAccount.Id, eduHist.hed__Account__c, 'Education Institution update should occur for Education History with no mismatching Grade Enrollments.');
    //     }
    // }
}