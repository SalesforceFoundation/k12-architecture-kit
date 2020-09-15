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
    
    /*********************************************************************************************************
    *****************************************FUNCTIONAL TESTS*************************************************
    **********************************************************************************************************/
    
    /*********************************************************************************************************
    * @description Test to verify that inserting a Grade Enrollment record with an Educational Institution
    * value matching the Educational Institution on the associated Education History record
    * proceeds without error.
    *********************************************************************************************************/
    @isTest 
    private static void insertGradeEnrollmentMatchingInstitution(){
        hed__Hierarchy_Settings__c hs = hed.UTIL_CustomSettings_API.getSettings();
        String adminRecordType = hs.hed__Administrative_Account_Record_Type__c;

        List<hed__Education_History__c> eduHistList = new List<hed__Education_History__c>();
        List<Grade_Enrollment__c> gradeEnrollmentsList = new List<Grade_Enrollment__c>();

        Account firstAccount = new Account(RecordTypeId = adminRecordType, Name = 'Test Account 1');
        insert firstAccount;

        Contact testContact = new Contact(LastName = 'Testerson');
        insert testContact;

        for (Integer i = 0; i < 5; i++){
            hed__Education_History__c testEduHist = new hed__Education_History__c(hed__Contact__c = testContact.Id,
                                                                                  hed__Account__c = firstAccount.Id);

            eduHistList.add(testEduHist);
        }

        insert eduHistList;

        for (hed__Education_History__c eduHist : eduHistList){
            Grade_Enrollment__c gradeEnroll = new Grade_Enrollment__c(Contact__c = testContact.Id,
                                                                      Educational_Institution__c = firstAccount.Id,
                                                                      Grade_Level__c = 'Eighth Grade',
                                                                      Education_History__c = eduHist.Id
                                                                     );

            gradeEnrollmentsList.add(gradeEnroll);
        }

        Test.startTest();
        insert gradeEnrollmentsList;
        Test.stopTest();

        List<Grade_Enrollment__c> gradeEnrollmentResultsList = [SELECT Id,
                                                                       Education_History__c,
                                                                       Education_History__r.hed__Account__c,
                                                                       Educational_Institution__c
                                                                FROM Grade_Enrollment__c
                                                                WHERE Id IN :gradeEnrollmentsList];

        System.assertEquals(5, gradeEnrollmentResultsList.size(), 'Five Grade Enrollment records should be successfully inserted.');

        for (Grade_Enrollment__c gradeEnroll : gradeEnrollmentResultsList){
            System.assertEquals(gradeEnroll.Education_History__r.hed__Account__c, gradeEnroll.Educational_Institution__c, 'Educational Institution on Grade Enrollment and Education History records should match.');
            System.assertEquals(true, String.isNotBlank(gradeEnroll.Educational_Institution__c), 'Educational Institution on Grade Enrollment and Education History records should be populated.');
            System.assertEquals(true, gradeEnroll.Educational_Institution__c == gradeEnroll.Education_History__r.hed__Account__c, 'Educational Institution on Grade Enrollment and Education History should be equal.');
        }
    }

    /*********************************************************************************************************
    * @description Test to verify that inserting a Grade Enrollment record with an Educational Institution
    * value that does not match the Educational Institution specified on the associated Education History 
    * record displays an error message.
    *********************************************************************************************************/
    @isTest 
    private static void insertGradeEnrollmentMismatchingInstitution(){
        hed__Hierarchy_Settings__c hs = hed.UTIL_CustomSettings_API.getSettings();
        String adminRecordType = hs.hed__Administrative_Account_Record_Type__c;

        List<hed__Education_History__c> eduHistList = new List<hed__Education_History__c>();
        List<Grade_Enrollment__c> gradeEnrollmentsList = new List<Grade_Enrollment__c>();
        List<Account> testAccountsList = new List<Account>();

        Account firstAccount = new Account(RecordTypeId = adminRecordType, Name = 'Test Account 1');
        Account secondAccount = new Account(RecordTypeId = adminRecordType, Name = 'Test Account 2');

        testAccountsList.add(firstAccount);
        testAccountsList.add(secondAccount);
        insert testAccountsList;

        Contact testContact = new Contact(LastName = 'Testerson');
        insert testContact;

        for (Integer i = 0; i < 5; i++){
            hed__Education_History__c testEduHist = new hed__Education_History__c(hed__Contact__c = testContact.Id,
                                                                                  hed__Account__c = firstAccount.Id);

            eduHistList.add(testEduHist);
        }

        insert eduHistList;

        for (hed__Education_History__c eduHist : eduHistList){
            Grade_Enrollment__c gradeEnroll = new Grade_Enrollment__c(Contact__c = testContact.Id,
                                                                      Educational_Institution__c = secondAccount.Id,
                                                                      Grade_Level__c = 'Eighth Grade',
                                                                      Education_History__c = eduHist.Id
                                                                     );

            gradeEnrollmentsList.add(gradeEnroll);
        }

        Test.startTest();
        Database.SaveResult[] results = Database.insert(gradeEnrollmentsList, false);
        Test.stopTest();

        for (Database.SaveResult sr : results){
            for (Database.Error err : sr.getErrors()){
                System.assertEquals(Label.GrErInstitutionMismatch, err.getMessage(), 'Inserting Grade Enrollment with mismatched Institution should display error message.');
            }
        }
    }

    /*********************************************************************************************************
    * @description Test to verify that inserting a Grade Enrollment record with a blank value for Educational 
    * Institution will be processed without an error even when the Educational Institution value on the 
    * associated Education History record is populated.
    *********************************************************************************************************/
    @isTest 
    private static void insertGradeEnrollmentNoInstitutionOnGradeEnrollment(){
        hed__Hierarchy_Settings__c hs = hed.UTIL_CustomSettings_API.getSettings();
        String adminRecordType = hs.hed__Administrative_Account_Record_Type__c;

        List<hed__Education_History__c> eduHistList = new List<hed__Education_History__c>();
        List<Grade_Enrollment__c> gradeEnrollmentsList = new List<Grade_Enrollment__c>();

        Account firstAccount = new Account(RecordTypeId = adminRecordType, Name = 'Test Account 1');
        insert firstAccount;

        Contact testContact = new Contact(LastName = 'Testerson');
        insert testContact;

        for (Integer i = 0; i < 5; i++){
            hed__Education_History__c testEduHist = new hed__Education_History__c(hed__Contact__c = testContact.Id,
                                                                                  hed__Account__c = firstAccount.Id);

            eduHistList.add(testEduHist);
        }

        insert eduHistList;

        for (hed__Education_History__c eduHist : eduHistList){
            Grade_Enrollment__c gradeEnroll = new Grade_Enrollment__c(Contact__c = testContact.Id,
                                                                      Educational_Institution__c = null,
                                                                      Grade_Level__c = 'Eighth Grade',
                                                                      Education_History__c = eduHist.Id
                                                                     );

            gradeEnrollmentsList.add(gradeEnroll);
        }

        Test.startTest();
        insert gradeEnrollmentsList;
        Test.stopTest();

        List<Grade_Enrollment__c> gradeEnrollmentResultsList = [SELECT Id,
                                                                       Educational_Institution__c,
                                                                       Education_History__c,
                                                                       Education_History__r.hed__Account__c
                                                                FROM Grade_Enrollment__c
                                                                WHERE Id IN :gradeEnrollmentsList];

        System.assertEquals(5, gradeEnrollmentResultsList.size(), 'Five Grade Enrollment records should be successfully inserted.');

        for (Grade_Enrollment__c gradeEnroll : gradeEnrollmentResultsList){
            System.assertEquals(true, String.isBlank(gradeEnroll.Educational_Institution__c), 'Grade Enrollment should be inserted with blank value for Institution.');
            System.assertEquals(firstAccount.Id, gradeEnroll.Education_History__r.hed__Account__c, 'Educational Institution on Education History record should be populated.');
            System.assertEquals(true, gradeEnroll.Educational_Institution__c != gradeEnroll.Education_History__r.hed__Account__c, 'Educational Institution on Grade Enrollment and Education History should not match.');
        }
    }

    /*********************************************************************************************************
    * @description Test to verify that inserting a Grade Enrollment record with a value specified for Educational 
    * Institution will be processed without an error even when the Educational Institution field on the 
    * associated Education History record is blank.
    *********************************************************************************************************/
    @isTest 
    private static void insertGradeEnrollmentNoInstitutionOnEducationHistory(){
        hed__Hierarchy_Settings__c hs = hed.UTIL_CustomSettings_API.getSettings();
        String adminRecordType = hs.hed__Administrative_Account_Record_Type__c;

        List<hed__Education_History__c> eduHistList = new List<hed__Education_History__c>();
        List<Grade_Enrollment__c> gradeEnrollmentsList = new List<Grade_Enrollment__c>();

        Account firstAccount = new Account(RecordTypeId = adminRecordType, Name = 'Test Account 1');
        insert firstAccount;

        Contact testContact = new Contact(LastName = 'Testerson');
        insert testContact;

        for (Integer i = 0; i < 5; i++){
            hed__Education_History__c testEduHist = new hed__Education_History__c(hed__Contact__c = testContact.Id,
                                                                                  hed__Account__c = null);

            eduHistList.add(testEduHist);
        }

        insert eduHistList;

        for (hed__Education_History__c eduHist : eduHistList){
            Grade_Enrollment__c gradeEnroll = new Grade_Enrollment__c(Contact__c = testContact.Id,
                                                                      Educational_Institution__c = firstAccount.Id,
                                                                      Grade_Level__c = 'Eighth Grade',
                                                                      Education_History__c = eduHist.Id
                                                                     );

            gradeEnrollmentsList.add(gradeEnroll);
        }

        Test.startTest();
        insert gradeEnrollmentsList;
        Test.stopTest();

        List<Grade_Enrollment__c> gradeEnrollmentResultsList = [SELECT Id,
                                                                       Educational_Institution__c,
                                                                       Education_History__c,
                                                                       Education_History__r.hed__Account__c
                                                                FROM Grade_Enrollment__c
                                                                WHERE Id IN :gradeEnrollmentsList];

        System.assertEquals(5, gradeEnrollmentResultsList.size(), 'Five Grade Enrollment records should be successfully inserted.');

        for (Grade_Enrollment__c gradeEnroll : gradeEnrollmentResultsList){
            System.assertEquals(true, String.isBlank(gradeEnroll.Education_History__r.hed__Account__c), 'Education History Institution field should remain blank.');
            System.assertEquals(firstAccount.Id, gradeEnroll.Educational_Institution__c, 'Grade Enrollment should be inserted with Institution field populated.');
            System.assertEquals(true, gradeEnroll.Educational_Institution__c != gradeEnroll.Education_History__r.hed__Account__c, 'Educational Institution on Grade Enrollment and Education History should not match.');
        }
    }

    /*********************************************************************************************************
    * @description Test to verify that inserting a Grade Enrollment record with a blank value specified for
    * the Educational Institution associated with an Education History that also has a blank value for 
    * Educational Institution will be processed without an error. 
    *********************************************************************************************************/
    @isTest 
    private static void insertGradeEnrollmentNoInstitutions(){
        hed__Hierarchy_Settings__c hs = hed.UTIL_CustomSettings_API.getSettings();
        String adminRecordType = hs.hed__Administrative_Account_Record_Type__c;

        List<hed__Education_History__c> eduHistList = new List<hed__Education_History__c>();
        List<Grade_Enrollment__c> gradeEnrollmentsList = new List<Grade_Enrollment__c>();

        Contact testContact = new Contact(LastName = 'Testerson');
        insert testContact;

        for (Integer i = 0; i < 5; i++){
            hed__Education_History__c testEduHist = new hed__Education_History__c(hed__Contact__c = testContact.Id,
                                                                                  hed__Account__c = null);

            eduHistList.add(testEduHist);
        }

        insert eduHistList;

        for (hed__Education_History__c eduHist : eduHistList){
            Grade_Enrollment__c gradeEnroll = new Grade_Enrollment__c(Contact__c = testContact.Id,
                                                                      Educational_Institution__c = null,
                                                                      Grade_Level__c = 'Eighth Grade',
                                                                      Education_History__c = eduHist.Id
                                                                     );

            gradeEnrollmentsList.add(gradeEnroll);
        }

        Test.startTest();
        insert gradeEnrollmentsList;
        Test.stopTest();

        List<Grade_Enrollment__c> gradeEnrollmentResultsList = [SELECT Id,
                                                                       Educational_Institution__c,
                                                                       Education_History__c,
                                                                       Education_History__r.hed__Account__c
                                                                FROM Grade_Enrollment__c
                                                                WHERE Id IN :gradeEnrollmentsList];

        System.assertEquals(5, gradeEnrollmentResultsList.size(), 'Five Grade Enrollment records should be successfully inserted.');

        for (Grade_Enrollment__c gradeEnroll : gradeEnrollmentResultsList){
            System.assertEquals(true, String.isBlank(gradeEnroll.Education_History__r.hed__Account__c), 'Education History Institution field should be blank.');
            System.assertEquals(gradeEnroll.Education_History__r.hed__Account__c, gradeEnroll.Educational_Institution__c, 'Educational Institution on Grade Enrollment and Education History should match.');
        }
    }

    /*********************************************************************************************************
    * @description Test to verify that updating a Grade Enrollment record with a value for Educational 
    * Institution that matches the Educational Institution specified on the associated Education History record
    * is processed without error.
    *********************************************************************************************************/
    @isTest 
    private static void updateGradeEnrollmentMatchingInstitution(){
        GRER_DataInteg_TEST.disableEDUHISDataIntegTrigger();

        hed__Hierarchy_Settings__c hs = hed.UTIL_CustomSettings_API.getSettings();
        String adminRecordType = hs.hed__Administrative_Account_Record_Type__c;

        List<Account> accountsList = new List<Account>();
        List<hed__Education_History__c> eduHistList = new List<hed__Education_History__c>();
        List<Grade_Enrollment__c> gradeEnrollmentsList = new List<Grade_Enrollment__c>();

        Contact testContact = new Contact(LastName = 'Testerson');
        insert testContact;

        Account firstAccount = new Account(RecordTypeId = adminRecordType, Name = 'Test Account 1');
        Account secondAccount = new Account(RecordTypeId = adminRecordType, Name = 'Test Account 2');
        accountsList.add(firstAccount);
        accountsList.add(secondAccount);
        insert accountsList;

        for (Integer i = 0; i < 5; i++){
            hed__Education_History__c testEduHist = new hed__Education_History__c(hed__Contact__c = testContact.Id,
                                                                                  hed__Account__c = null);

            eduHistList.add(testEduHist);
        }

        insert eduHistList;

        for (hed__Education_History__c eduHist : eduHistList){
            Grade_Enrollment__c gradeEnroll = new Grade_Enrollment__c(Contact__c = testContact.Id,
                                                                      Educational_Institution__c = secondAccount.Id,
                                                                      Grade_Level__c = 'Eighth Grade',
                                                                      Education_History__c = eduHist.Id
                                                                     );

            gradeEnrollmentsList.add(gradeEnroll);
        }

        insert gradeEnrollmentsList;

        for (hed__Education_History__c eduHist : eduHistList){
            eduHist.hed__Account__c = firstAccount.Id;
        }

        update eduHistList;

        for (Grade_Enrollment__c gradeEnroll : gradeEnrollmentsList){
            gradeEnroll.Educational_Institution__c = firstAccount.Id;
        }

        Test.startTest();
        update gradeEnrollmentsList;
        Test.stopTest();

        List<Grade_Enrollment__c> gradeEnrollmentResultsList = [SELECT Id,
                                                                       Educational_Institution__c,
                                                                       Education_History__c,
                                                                       Education_History__r.hed__Account__c
                                                                FROM Grade_Enrollment__c
                                                                WHERE Id IN :gradeEnrollmentsList];

        for (Grade_Enrollment__c gradeEnroll : gradeEnrollmentResultsList){
            System.assertEquals(firstAccount.Id, gradeEnroll.Educational_Institution__c, 'Education History Institution field on Grade Enrollment should be updated.');
            System.assertEquals(gradeEnroll.Education_History__r.hed__Account__c, gradeEnroll.Educational_Institution__c, 'Educational Institution on Grade Enrollment and Education History should match.');
        }
    }

    /*********************************************************************************************************
    * @description Test to verify that updating a Grade Enrollment record with a value for Educational 
    * Institution that does not match the Educational Institution specified on the associated Education 
    * History record displays an error message.
    *********************************************************************************************************/
    @isTest 
    private static void updateGradeEnrollmentMismatchingInstitution(){
        hed__Hierarchy_Settings__c hs = hed.UTIL_CustomSettings_API.getSettings();
        String adminRecordType = hs.hed__Administrative_Account_Record_Type__c;

        List<hed__Education_History__c> eduHistList = new List<hed__Education_History__c>();
        List<Grade_Enrollment__c> gradeEnrollmentsList = new List<Grade_Enrollment__c>();
        List<Account> accountsList = new List<Account>();

        Contact testContact = new Contact(LastName = 'Testerson');
        insert testContact;

        Account firstAccount = new Account(RecordTypeId = adminRecordType, Name = 'Test Account 1');
        Account secondAccount = new Account(RecordTypeId = adminRecordType, Name = 'Test Account 2');
        accountsList.add(firstAccount);
        accountsList.add(secondAccount);
        insert accountsList;

        for (Integer i = 0; i < 5; i++){
            hed__Education_History__c testEduHist = new hed__Education_History__c(hed__Contact__c = testContact.Id,
                                                                                  hed__Account__c = firstAccount.Id);

            eduHistList.add(testEduHist);
        }

        insert eduHistList;

        for (hed__Education_History__c eduHist : eduHistList){
            Grade_Enrollment__c gradeEnroll = new Grade_Enrollment__c(Contact__c = testContact.Id,
                                                                      Educational_Institution__c = firstAccount.Id,
                                                                      Grade_Level__c = 'Eighth Grade',
                                                                      Education_History__c = eduHist.Id
                                                                     );

            gradeEnrollmentsList.add(gradeEnroll);
        }

        insert gradeEnrollmentsList;

        for (Grade_Enrollment__c gradeEnroll : gradeEnrollmentsList){
            gradeEnroll.Educational_Institution__c = secondAccount.Id;
        }

        Test.startTest();
        Database.SaveResult[] results = Database.update(gradeEnrollmentsList, false);
        Test.stopTest();

        for (Database.SaveResult sr : results){
            for (Database.Error err : sr.getErrors()){
                System.assertEquals(Label.GrErInstitutionMismatch, err.getMessage(), 'Grade Enrollment with mismatched Institution should not update.');
            }
        }
    }

    /*********************************************************************************************************
    * @description Test to verify that clearing the Educational Institution field on a Grade Enrollment 
    * record that is associated with an Education History record with an Educational Institution specified 
    * will update without error.
    *********************************************************************************************************/
    @isTest 
    private static void updateGradeEnrollmentNoInstitutionOnGradeEnrollment(){
        hed__Hierarchy_Settings__c hs = hed.UTIL_CustomSettings_API.getSettings();
        String adminRecordType = hs.hed__Administrative_Account_Record_Type__c;

        List<hed__Education_History__c> eduHistList = new List<hed__Education_History__c>();
        List<Grade_Enrollment__c> gradeEnrollmentsList = new List<Grade_Enrollment__c>();

        Contact testContact = new Contact(LastName = 'Testerson');
        insert testContact;

        Account firstAccount = new Account(RecordTypeId = adminRecordType, Name = 'Test Account 1');
        insert firstAccount;

        for (Integer i = 0; i < 5; i++){
            hed__Education_History__c testEduHist = new hed__Education_History__c(hed__Contact__c = testContact.Id,
                                                                                  hed__Account__c = firstAccount.Id);

            eduHistList.add(testEduHist);
        }

        insert eduHistList;

        for (hed__Education_History__c eduHist : eduHistList){
            Grade_Enrollment__c gradeEnroll = new Grade_Enrollment__c(Contact__c = testContact.Id,
                                                                      Educational_Institution__c = firstAccount.Id,
                                                                      Grade_Level__c = 'Eighth Grade',
                                                                      Education_History__c = eduHist.Id
                                                                     );

            gradeEnrollmentsList.add(gradeEnroll);
        }

        insert gradeEnrollmentsList;

        for (Grade_Enrollment__c gradeEnroll : gradeEnrollmentsList){
            gradeEnroll.Educational_Institution__c = null;
        }

        Test.startTest();
        update gradeEnrollmentsList;
        Test.stopTest();

        List<Grade_Enrollment__c> gradeEnrollmentResultsList = [SELECT Id,
                                                                       Educational_Institution__c,
                                                                       Education_History__c,
                                                                       Education_History__r.hed__Account__c
                                                                FROM Grade_Enrollment__c
                                                                WHERE Id IN :gradeEnrollmentsList];

        for (Grade_Enrollment__c gradeEnroll : gradeEnrollmentResultsList){
            System.assertEquals(true, String.isBlank(gradeEnroll.Educational_Institution__c), 'Institution on Grade Enrollment should be cleared.');
            System.assertEquals(firstAccount.Id, gradeEnroll.Education_History__r.hed__Account__c, 'Institution on Education History should remain unchanged.');
            System.assertEquals(true, gradeEnroll.Educational_Institution__c != gradeEnroll.Education_History__r.hed__Account__c, 'Institutions on Grade Enrollment and Education History should not match.');
        }
    }

    /*********************************************************************************************************
    * @description Test to verify that updating the Educational Institution field on a Grade Enrollment 
    * record from nothing to a specified value will process without error when the Educational Institution
    * field on the associated Education History record is blank.
    *********************************************************************************************************/
    @isTest 
    private static void updateGradeEnrollmentNoInstitutionOnEducationHistory(){
        hed__Hierarchy_Settings__c hs = hed.UTIL_CustomSettings_API.getSettings();
        String adminRecordType = hs.hed__Administrative_Account_Record_Type__c;

        List<hed__Education_History__c> eduHistList = new List<hed__Education_History__c>();
        List<Grade_Enrollment__c> gradeEnrollmentsList = new List<Grade_Enrollment__c>();

        Contact testContact = new Contact(LastName = 'Testerson');
        insert testContact;

        Account firstAccount = new Account(RecordTypeId = adminRecordType, Name = 'Test Account 1');
        insert firstAccount;

        for (Integer i = 0; i < 5; i++){
            hed__Education_History__c testEduHist = new hed__Education_History__c(hed__Contact__c = testContact.Id,
                                                                                  hed__Account__c = null);

            eduHistList.add(testEduHist);
        }

        insert eduHistList;

        for (hed__Education_History__c eduHist : eduHistList){
            Grade_Enrollment__c gradeEnroll = new Grade_Enrollment__c(Contact__c = testContact.Id,
                                                                      Educational_Institution__c = null,
                                                                      Grade_Level__c = 'Eighth Grade',
                                                                      Education_History__c = eduHist.Id
                                                                     );

            gradeEnrollmentsList.add(gradeEnroll);
        }

        insert gradeEnrollmentsList;

        for (Grade_Enrollment__c gradeEnroll : gradeEnrollmentsList){
            gradeEnroll.Educational_Institution__c = firstAccount.Id;
        }

        Test.startTest();
        update gradeEnrollmentsList;
        Test.stopTest();

        List<Grade_Enrollment__c> gradeEnrollmentResultsList = [SELECT Id,
                                                                       Educational_Institution__c,
                                                                       Education_History__c,
                                                                       Education_History__r.hed__Account__c
                                                                FROM Grade_Enrollment__c
                                                                WHERE Id IN :gradeEnrollmentsList];

        for (Grade_Enrollment__c gradeEnroll : gradeEnrollmentResultsList){
            System.assertEquals(firstAccount.Id, gradeEnroll.Educational_Institution__c, 'Institution on Grade Enrollment should be updated to new value.');
            System.assertEquals(null, gradeEnroll.Education_History__r.hed__Account__c, 'Institution on Education History should remain unchanged.');
            System.assertEquals(true, gradeEnroll.Educational_Institution__c != gradeEnroll.Education_History__r.hed__Account__c, 'Institutions on Grade Enrollment and Education History should not match.');
        }
    }

    /*********************************************************************************************************
    * @description Test to verify that clearing the Educational Institution field on a Grade Enrollment 
    * record will process without error when the Educational Institution field on the associated Education 
    * History record is blank.
    *********************************************************************************************************/
    @isTest 
    private static void updateGradeEnrollmentNoInstitutions(){
        hed__Hierarchy_Settings__c hs = hed.UTIL_CustomSettings_API.getSettings();
        String adminRecordType = hs.hed__Administrative_Account_Record_Type__c;

        List<hed__Education_History__c> eduHistList = new List<hed__Education_History__c>();
        List<Grade_Enrollment__c> gradeEnrollmentsList = new List<Grade_Enrollment__c>();

        Contact testContact = new Contact(LastName = 'Testerson');
        insert testContact;

        Account firstAccount = new Account(RecordTypeId = adminRecordType, Name = 'Test Account 1');
        insert firstAccount;

        for (Integer i = 0; i < 5; i++){
            hed__Education_History__c testEduHist = new hed__Education_History__c(hed__Contact__c = testContact.Id,
                                                                                  hed__Account__c = null);

            eduHistList.add(testEduHist);
        }

        insert eduHistList;

        for (hed__Education_History__c eduHist : eduHistList){
            Grade_Enrollment__c gradeEnroll = new Grade_Enrollment__c(Contact__c = testContact.Id,
                                                                      Educational_Institution__c = firstAccount.Id,
                                                                      Grade_Level__c = 'Eighth Grade',
                                                                      Education_History__c = eduHist.Id
                                                                     );

            gradeEnrollmentsList.add(gradeEnroll);
        }

        insert gradeEnrollmentsList;

        for (Grade_Enrollment__c gradeEnroll : gradeEnrollmentsList){
            gradeEnroll.Educational_Institution__c = null;
        }

        Test.startTest();
        update gradeEnrollmentsList;
        Test.stopTest();

        List<Grade_Enrollment__c> gradeEnrollmentResultsList = [SELECT Id,
                                                                       Educational_Institution__c,
                                                                       Education_History__c,
                                                                       Education_History__r.hed__Account__c
                                                                FROM Grade_Enrollment__c
                                                                WHERE Id IN :gradeEnrollmentsList];

        for (Grade_Enrollment__c gradeEnroll : gradeEnrollmentResultsList){
            System.assertEquals(null, gradeEnroll.Educational_Institution__c, 'Institution on Grade Enrollment should be cleared.');
            System.assertEquals(null, gradeEnroll.Education_History__r.hed__Account__c, 'Institution on Education History should remain unchanged.');
            System.assertEquals(true, gradeEnroll.Educational_Institution__c == gradeEnroll.Education_History__r.hed__Account__c, 'Institutions on Grade Enrollment and Education History should match.');
        }
    }

    /*********************************************************************************************************
    ***********************************************UNIT TESTS*************************************************
    **********************************************************************************************************/
    
    /*********************************************************************************************************
    * @description Test to verify that method hasInstitutionMismatch() returns true when a Grade Enrollment record
    * is related to an Education History record with a mismatching value for the Educational Insttitution fields.
    *********************************************************************************************************/
    @isTest 
    private static void hasInstitutionMismatchTrue(){
        hed__Hierarchy_Settings__c hs = hed.UTIL_CustomSettings_API.getSettings();
        String adminRecordType = hs.hed__Administrative_Account_Record_Type__c;

        List<hed__Education_History__c> educationHistoryList = new List<hed__Education_History__c>();
        List<Grade_Enrollment__c> gradeEnrollmentsList = new List<Grade_Enrollment__c>();
        Map<Id, hed__Education_History__c> educationHistoryByEnrollmentId = new Map<Id, hed__Education_History__c>();

        Id fakeFirstAccountId = GRER_DataInteg_TEST.getFakeId(Account.SObjectType);
        Id fakeSecondAccountId = GRER_DataInteg_TEST.getFakeId(Account.SObjectType);
        Id fakeContactId = GRER_DataInteg_TEST.getFakeId(Contact.SObjectType);

        for (Integer i = 0; i < 5; i++){
            Id fakeEduHistId = GRER_DataInteg_TEST.getFakeId(hed__Education_History__c.SObjectType);
            hed__Education_History__c eduHist = new hed__Education_History__c(Id = fakeEduHistId,
                                                                          hed__Contact__c = fakeContactId,
                                                                          hed__Account__c = fakeFirstAccountId);
                                                                         

            Id fakeGradeEnrollId = GRER_DataInteg_TEST.getFakeId(Grade_Enrollment__c.SObjectType);
            Grade_Enrollment__c gradeEnroll = new Grade_Enrollment__c(Id = fakeGradeEnrollId,
                                                                      Contact__c = fakeContactId,
                                                                      Educational_Institution__c = fakeSecondAccountId,
                                                                      Grade_Level__c = 'Eighth Grade',
                                                                      Education_History__c = fakeEduHistId);
            
            gradeEnrollmentsList.add(gradeEnroll);
            educationHistoryByEnrollmentId.put(fakeGradeEnrollId, eduHist);
        }

        GRER_DataInteg_TDTM gradeEnrollTdtm = new GRER_DataInteg_TDTM();
        Test.startTest();
        for (Grade_Enrollment__c gradeEnroll : gradeEnrollmentsList){
            System.assertEquals(true, gradeEnrollTdtm.hasInstitutionMismatch(gradeEnroll, educationHistoryByEnrollmentId.get(gradeEnroll.Id)), 'Educational Institution on Grade Enrollment and Education History should not match.');
        }
        Test.stopTest();
    }

    /*********************************************************************************************************
    * @description Test to verify that method hasInstitutionMismatch() returns false when a Grade Enrollment record
    * is related to an Education History record with a matching value for the Educational Insttitution fields.
    *********************************************************************************************************/
    @isTest 
    private static void hasInstitutionMismatchFalse(){
        hed__Hierarchy_Settings__c hs = hed.UTIL_CustomSettings_API.getSettings();
        String adminRecordType = hs.hed__Administrative_Account_Record_Type__c;

        List<hed__Education_History__c> educationHistoryList = new List<hed__Education_History__c>();
        List<Grade_Enrollment__c> gradeEnrollmentsList = new List<Grade_Enrollment__c>();
        Map<Id, hed__Education_History__c> educationHistoryByEnrollmentId = new Map<Id, hed__Education_History__c>();

        Id fakeAccountId = GRER_DataInteg_TEST.getFakeId(Account.SObjectType);
        Id fakeContactId = GRER_DataInteg_TEST.getFakeId(Contact.SObjectType);

        for (Integer i = 0; i < 5; i++){
            Id fakeEduHistId = GRER_DataInteg_TEST.getFakeId(hed__Education_History__c.SObjectType);
            hed__Education_History__c eduHist = new hed__Education_History__c(Id = fakeEduHistId,
                                                                          hed__Contact__c = fakeContactId,
                                                                          hed__Account__c = fakeAccountId);
                                                                         

            Id fakeGradeEnrollId = GRER_DataInteg_TEST.getFakeId(Grade_Enrollment__c.SObjectType);
            Grade_Enrollment__c gradeEnroll = new Grade_Enrollment__c(Id = fakeGradeEnrollId,
                                                                      Contact__c = fakeContactId,
                                                                      Educational_Institution__c = fakeAccountId,
                                                                      Grade_Level__c = 'Eighth Grade',
                                                                      Education_History__c = fakeEduHistId);
            
            gradeEnrollmentsList.add(gradeEnroll);
            educationHistoryByEnrollmentId.put(fakeGradeEnrollId, eduHist);
        }

        GRER_DataInteg_TDTM gradeEnrollTdtm = new GRER_DataInteg_TDTM();
        Test.startTest();
        for (Grade_Enrollment__c gradeEnroll : gradeEnrollmentsList){
            System.assertEquals(false, gradeEnrollTdtm.hasInstitutionMismatch(gradeEnroll, educationHistoryByEnrollmentId.get(gradeEnroll.Id)), 'Educational Institution on Grade Enrollment and Education History should match.');
        }
        Test.stopTest();
    }

    /*********************************************************************************************************
    * @description Test to verify that method mapEducationHistoryByGradeEnrollment() returns a populated 
    * map containing Education History records mapped by their related Grade Enrollment Id for Grade Enrollments
    * that are related to an Education History account.
    *********************************************************************************************************/
    @isTest 
    private static void mapEducationHistoryByGradeEnrollmentPositive(){
        hed__Hierarchy_Settings__c hs = hed.UTIL_CustomSettings_API.getSettings();
        String adminRecordType = hs.hed__Administrative_Account_Record_Type__c;

        List<hed__Education_History__c> educationHistoryList = new List<hed__Education_History__c>();
        List<Grade_Enrollment__c> gradeEnrollmentsList = new List<Grade_Enrollment__c>();
        Map<Id, hed__Education_History__c> eduHistById = new Map<Id, hed__Education_History__c>();

        Contact testContact = new Contact(LastName = 'Testerson');
        insert testContact;

        Account firstAccount = new Account(RecordTypeId = adminRecordType, Name = 'Test Account 1');
        insert firstAccount;

        for (Integer i = 0; i < 5; i++){
            hed__Education_History__c testEduHist = new hed__Education_History__c(hed__Contact__c = testContact.Id,
                                                                                  hed__Account__c = firstAccount.Id);

            educationHistoryList.add(testEduHist);
        }

        insert educationHistoryList;

        for (hed__Education_History__c eduHist : educationHistoryList){
            eduHistById.put(eduHist.Id, eduHist);

            Grade_Enrollment__c gradeEnroll = new Grade_Enrollment__c(Contact__c = testContact.Id,
                                                                      Educational_Institution__c = firstAccount.Id,
                                                                      Grade_Level__c = 'Eighth Grade',
                                                                      Education_History__c = eduHist.Id
                                                                     );

            gradeEnrollmentsList.add(gradeEnroll);
        }       

        insert gradeEnrollmentsList;
        
        GRER_DataInteg_TDTM gradeEnrollTdtm = new GRER_DataInteg_TDTM();
        Map<Id, hed__Education_History__c> eduHistByGradeEnrollId = new Map<Id, hed__Education_History__c>();

        Test.startTest();
        eduHistByGradeEnrollId = gradeEnrollTdtm.mapEducationHistoryByGradeEnrollment(gradeEnrollmentsList);
        Test.stopTest();

        System.assertEquals(5, eduHistByGradeEnrollId.keySet().size(), 'There should be 5 mappings of Education History by Grade Enrollment.');

        for (Id gradeEnrollId : eduHistByGradeEnrollId.keySet()){
            hed__Education_History__c relatedEduHistory = eduHistByGradeEnrollId.get(gradeEnrollId);
            
            System.assertEquals(true, relatedEduHistory != null, 'Each grade enrollment should be mapped to an education history.');
            System.assertEquals(eduHistById.get(relatedEduHistory.Id).Id, relatedEduHistory.Id, 'Each Grade Enrollment should be mapped to its corresponding Education History record.');
        }
    }

    /*********************************************************************************************************
    * @description Test to verify that method mapEducationHistoryByGradeEnrollment() returns an empty populated 
    * map containing Education History records mapped by their related Grade Enrollment Id for Grade Enrollments
    * that are not related to an Education History account.
    *********************************************************************************************************/
    @isTest 
    private static void mapEducationHistoryByGradeEnrollmentNegative(){
        hed__Hierarchy_Settings__c hs = hed.UTIL_CustomSettings_API.getSettings();
        String adminRecordType = hs.hed__Administrative_Account_Record_Type__c;

        List<hed__Education_History__c> educationHistoryList = new List<hed__Education_History__c>();
        List<Grade_Enrollment__c> gradeEnrollmentsList = new List<Grade_Enrollment__c>();

        Contact testContact = new Contact(LastName = 'Testerson');
        insert testContact;

        Account firstAccount = new Account(RecordTypeId = adminRecordType, Name = 'Test Account 1');
        insert firstAccount;

        for (Integer i = 0; i < 5; i++){
            Grade_Enrollment__c gradeEnroll = new Grade_Enrollment__c(Contact__c = testContact.Id,
                                                                      Educational_Institution__c = firstAccount.Id,
                                                                      Grade_Level__c = 'Eighth Grade',
                                                                      Education_History__c = null
                                                                     );

            gradeEnrollmentsList.add(gradeEnroll);
        }       

        insert gradeEnrollmentsList;
        
        GRER_DataInteg_TDTM gradeEnrollTdtm = new GRER_DataInteg_TDTM();
        Map<Id, hed__Education_History__c> eduHistByGradeEnrollId = new Map<Id, hed__Education_History__c>();

        Test.startTest();
        eduHistByGradeEnrollId = gradeEnrollTdtm.mapEducationHistoryByGradeEnrollment(gradeEnrollmentsList);
        Test.stopTest();

        System.assertEquals(true, eduHistByGradeEnrollId.isEmpty(), 'Each Grade Enrollment should not have a corresponding Education History record.');
    }

    /*********************************************************************************************************
    * @description Test to verify that method checkEducationalInstitutionAgainstEducationHistory() displays  
    * an error message when Grade Enrollment records with Education Institutions that do not match the value 
    * specified on the associated Education History records are inserted.
    *********************************************************************************************************/
    @isTest 
    private static void checkEducationalInstitutionAgainstEducationHistoryBeforeInsertWithMismatch(){
        hed__Hierarchy_Settings__c hs = hed.UTIL_CustomSettings_API.getSettings();
        String adminRecordType = hs.hed__Administrative_Account_Record_Type__c;

        List<Grade_Enrollment__c> gradeEnrollmentsList = new List<Grade_Enrollment__c>();

        Id fakeFirstAccountId = GRER_DataInteg_TEST.getFakeId(Account.SObjectType);
        Id fakeSecondAccountId = GRER_DataInteg_TEST.getFakeId(Account.SObjectType);
        Id fakeContactId = GRER_DataInteg_TEST.getFakeId(Contact.SObjectType);

        for (Integer i = 0; i < 5; i++){
            Id fakeEduHistId = GRER_DataInteg_TEST.getFakeId(hed__Education_History__c.SObjectType);
            hed__Education_History__c testEduHist = new hed__Education_History__c(Id = fakeEduHistId,
                                                                                  hed__Contact__c = fakeContactId,
                                                                                  hed__Account__c = fakeFirstAccountId);

            Grade_Enrollment__c gradeEnroll = new Grade_Enrollment__c(Id = GRER_DataInteg_TEST.getFakeId(Grade_Enrollment__c.SObjectType),
                                                                      Contact__c = fakeContactId,
                                                                      Educational_Institution__c = fakeSecondAccountId,
                                                                      Grade_Level__c = 'Eighth Grade',
                                                                      Education_History__c = fakeEduHistId
                                                                     );

            gradeEnrollmentsList.add(gradeEnroll);
        }

        Test.startTest();
        GRER_DataInteg_TDTM gradeEnrollTdtm = new GRER_DataInteg_TDTM();
        List<Exception> exceptionsList = new List<Exception>();

        try{
            gradeEnrollTdtm.checkEducationalInstitutionAgainstEducationHistory((List<SObject>)gradeEnrollmentsList);
        } catch (Exception e){
            exceptionsList.add(e);
        }
        Test.stopTest();

        for (Exception err : exceptionsList){
            System.assertEquals(Label.GrErInstitutionMismatch, err.getMessage(), 'Inserting Grade Enrollments with mismatching Educational Institution should display error message.');
        }

    }

    /*********************************************************************************************************
    * @description Test to verify that method checkEducationalInstitutionAgainstEducationHistory() processes 
    * an insert of Grade Enrollment records with Education Institutions that do not match the value specified 
    * on the associated Education History records are inserted.
    *********************************************************************************************************/
    @isTest 
    private static void checkEducationalInstitutionAgainstEducationHistoryBeforeInsertWithoutMismatch(){
        hed__Hierarchy_Settings__c hs = hed.UTIL_CustomSettings_API.getSettings();
        String adminRecordType = hs.hed__Administrative_Account_Record_Type__c;

        List<Grade_Enrollment__c> gradeEnrollmentsList = new List<Grade_Enrollment__c>();

        Id fakeFirstAccountId = GRER_DataInteg_TEST.getFakeId(Account.SObjectType);
        Id fakeContactId = GRER_DataInteg_TEST.getFakeId(Contact.SObjectType);

        for (Integer i = 0; i < 5; i++){
            Id fakeEduHistId = GRER_DataInteg_TEST.getFakeId(hed__Education_History__c.SObjectType);
            hed__Education_History__c testEduHist = new hed__Education_History__c(Id = fakeEduHistId,
                                                                                  hed__Contact__c = fakeContactId,
                                                                                  hed__Account__c = fakeFirstAccountId);

            Grade_Enrollment__c gradeEnroll = new Grade_Enrollment__c(Id = GRER_DataInteg_TEST.getFakeId(Grade_Enrollment__c.SObjectType),
                                                                      Contact__c = fakeContactId,
                                                                      Educational_Institution__c = fakeFirstAccountId,
                                                                      Grade_Level__c = 'Eighth Grade',
                                                                      Education_History__c = fakeEduHistId
                                                                     );

            gradeEnrollmentsList.add(gradeEnroll);
        }

        Test.startTest();
        GRER_DataInteg_TDTM gradeEnrollTdtm = new GRER_DataInteg_TDTM();
        List<Exception> exceptionsList = new List<Exception>();

        try{
            gradeEnrollTdtm.checkEducationalInstitutionAgainstEducationHistory((List<SObject>)gradeEnrollmentsList);
        } catch (Exception e){
            exceptionsList.add(e);
        }
        Test.stopTest();

        System.assertEquals(true, exceptionsList.isEmpty(), 'Inserting Grade Enrollments with matching Educational Institution should not display error messages.');
    }

    /*********************************************************************************************************
    * @description Test to verify that method checkEducationalInstitutionAgainstEducationHistory() processes 
    * updates to Grade Enrollment records when the Education Institution fields match the value specified on 
    * the associated Education History records.
    *********************************************************************************************************/
    @isTest 
    private static void checkEducationalInstitutionAgainstEducationHistoryBeforeUpdateWithoutMismatch(){
        hed__Hierarchy_Settings__c hs = hed.UTIL_CustomSettings_API.getSettings();
        String adminRecordType = hs.hed__Administrative_Account_Record_Type__c;

        List<Grade_Enrollment__c> newGradeEnrollmentsList = new List<Grade_Enrollment__c>();
        List<Grade_Enrollment__c> oldGradeEnrollmentsList = new List<Grade_Enrollment__c>();

        Id fakeFirstAccountId = GRER_DataInteg_TEST.getFakeId(Account.SObjectType);
        Id fakeContactId = GRER_DataInteg_TEST.getFakeId(Contact.SObjectType);

        for (Integer i = 0; i < 5; i++){

            Id fakeEduHistId = GRER_DataInteg_TEST.getFakeId(hed__Education_History__c.SObjectType);
            Id fakeGradeEnrollId = GRER_DataInteg_TEST.getFakeId(Grade_Enrollment__c.SObjectType);
            
            hed__Education_History__c testEduHist = new hed__Education_History__c(Id = fakeEduHistId,
                                                                                  hed__Contact__c = fakeContactId,
                                                                                  hed__Account__c = fakeFirstAccountId);

            Grade_Enrollment__c oldGradeEnroll = new Grade_Enrollment__c(Id = fakeGradeEnrollId,
                                                                      Contact__c = fakeContactId,
                                                                      Educational_Institution__c = null,
                                                                      Grade_Level__c = 'Eighth Grade',
                                                                      Education_History__c = fakeEduHistId
                                                                     );

            Grade_Enrollment__c newGradeEnroll = oldGradeEnroll.clone(true);
            newGradeEnroll.Educational_Institution__c = fakeFirstAccountId;

            oldGradeEnrollmentsList.add(oldGradeEnroll);
            newGradeEnrollmentsList.add(newGradeEnroll);
        }

        Test.startTest();
        GRER_DataInteg_TDTM gradeEnrollTdtm = new GRER_DataInteg_TDTM();
        List<Exception> exceptionsList = new List<Exception>();

        try{
            gradeEnrollTdtm.checkEducationalInstitutionAgainstEducationHistory((List<SObject>)newGradeEnrollmentsList, (List<SObject>)oldGradeEnrollmentsList);
        } catch (Exception e){
            exceptionsList.add(e);
        }
        Test.stopTest();

        System.assertEquals(true, exceptionsList.isEmpty(), 'Inserting Grade Enrollments with matching Educational Institution should not display error messages.');
    }

    /*********************************************************************************************************
    * @description Test to verify that method checkEducationalInstitutionAgainstEducationHistory() displays an 
    * error message for updates to Grade Enrollment records with Education Institution fields that do not match 
    * the value specified on the associated Education History records.
    *********************************************************************************************************/
    @isTest 
    private static void checkEducationalInstitutionAgainstEducationHistoryBeforeUpdateWithMismatch(){
        hed__Hierarchy_Settings__c hs = hed.UTIL_CustomSettings_API.getSettings();
        String adminRecordType = hs.hed__Administrative_Account_Record_Type__c;

        List<Grade_Enrollment__c> newGradeEnrollmentsList = new List<Grade_Enrollment__c>();
        List<Grade_Enrollment__c> oldGradeEnrollmentsList = new List<Grade_Enrollment__c>();

        Id fakeFirstAccountId = GRER_DataInteg_TEST.getFakeId(Account.SObjectType);
        Id fakeSecondAccountId = GRER_DataInteg_TEST.getFakeId(Account.SObjectType);
        Id fakeContactId = GRER_DataInteg_TEST.getFakeId(Contact.SObjectType);

        for (Integer i = 0; i < 5; i++){
            Id fakeEduHistId = GRER_DataInteg_TEST.getFakeId(hed__Education_History__c.SObjectType);
            Id fakeGradeEnrollId = GRER_DataInteg_TEST.getFakeId(Grade_Enrollment__c.SObjectType);
            
            hed__Education_History__c testEduHist = new hed__Education_History__c(Id = fakeEduHistId,
                                                                                  hed__Contact__c = fakeContactId,
                                                                                  hed__Account__c = fakeFirstAccountId);

            Grade_Enrollment__c oldGradeEnroll = new Grade_Enrollment__c(Id = fakeGradeEnrollId,
                                                                      Contact__c = fakeContactId,
                                                                      Educational_Institution__c = fakeFirstAccountId,
                                                                      Grade_Level__c = 'Eighth Grade',
                                                                      Education_History__c = fakeEduHistId
                                                                     );

            Grade_Enrollment__c newGradeEnroll = oldGradeEnroll.clone(true);
            newGradeEnroll.Educational_Institution__c = fakeSecondAccountId;

            oldGradeEnrollmentsList.add(oldGradeEnroll);
            newGradeEnrollmentsList.add(newGradeEnroll);
        }

        Test.startTest();
        GRER_DataInteg_TDTM gradeEnrollTdtm = new GRER_DataInteg_TDTM();
        List<Exception> exceptionsList = new List<Exception>();

        try{
            gradeEnrollTdtm.checkEducationalInstitutionAgainstEducationHistory((List<SObject>)newGradeEnrollmentsList, (List<SObject>)oldGradeEnrollmentsList);
        } catch (Exception e){
            exceptionsList.add(e);
        }
        Test.stopTest();

        for (Exception error : exceptionsList){
            System.assertEquals(Label.GrErInstitutionMismatch, error.getMessage(), 'Inserting Grade Enrollments with mis-matching Educational Institution should display error messages.');
        }
    }

    /*********************************************************************************************************
    * @description Test to verify that method run() displays an error message when Grade 
    * Enrollment records with Education Institutions that do not match the value specified on the associated
    * Education History records are inserted.
    *********************************************************************************************************/
    @isTest 
    private static void runBeforeInsertMismatch(){
        hed.TDTM_Runnable.Action triggerAction = hed.TDTM_Runnable.Action.BeforeInsert;
        Schema.DescribeSObjectResult objResult = Schema.SObjectType.Grade_Enrollment__c;

        hed__Hierarchy_Settings__c hs = hed.UTIL_CustomSettings_API.getSettings();
        String adminRecordType = hs.hed__Administrative_Account_Record_Type__c;

        List<hed__Education_History__c> eduHistList = new List<hed__Education_History__c>();
        List<Grade_Enrollment__c> gradeEnrollmentsList = new List<Grade_Enrollment__c>();

        Id fakeContactId = GRER_DataInteg_TEST.getFakeId(Contact.SObjectType);
        Id fakeFirstAccountId = GRER_DataInteg_TEST.getFakeId(Account.SObjectType);
        Id fakeSecondAccountId = GRER_DataInteg_TEST.getFakeId(Account.SObjectType);

        for (Integer i = 0; i < 5; i++){
            Id fakeEduHistId = GRER_DataInteg_TEST.getFakeId(hed__Education_History__c.SObjectType);
            Id fakeGradeEnrollId = GRER_DataInteg_TEST.getFakeId(Grade_Enrollment__c.SObjectType);
            
            hed__Education_History__c testEduHist = new hed__Education_History__c(Id = fakeEduHistId,
                                                                                  hed__Contact__c = fakeContactId,
                                                                                  hed__Account__c = fakeFirstAccountId);


            Grade_Enrollment__c gradeEnroll = new Grade_Enrollment__c(Id = fakeGradeEnrollId,
                                                                      Contact__c = fakeContactId,
                                                                      Educational_Institution__c = fakeSecondAccountId,
                                                                      Grade_Level__c = 'Eighth Grade',
                                                                      Education_History__c = fakeEduHistId
                                                                     );

            gradeEnrollmentsList.add(gradeEnroll);
        }

        Test.startTest();
        GRER_DataInteg_TDTM gradeEnrollTdtm = new GRER_DataInteg_TDTM();
        List<Exception> exceptionsList = new List<Exception>();

        try{
            gradeEnrollTdtm.run((List<SObject>)gradeEnrollmentsList, null, triggerAction, objResult);
        } catch (Exception e){
            exceptionsList.add(e);
        }
        Test.stopTest();

        for (Exception err : exceptionsList){
            System.assertEquals(Label.GrErInstitutionMismatch, err.getMessage(), 'Inserting Grade Enrollments with mismatching Educational Institution should display error message.');
        }
    }

    /*********************************************************************************************************
    * @description Test to verify that method run() successfully processes and insert  Grade 
    * Enrollment records with Education Institutions that do not match the value specified on the associated
    * Education History records are inserted.
    *********************************************************************************************************/
    @isTest 
    private static void runBeforeInsertMatching(){
        hed.TDTM_Runnable.Action triggerAction = hed.TDTM_Runnable.Action.BeforeInsert;
        Schema.DescribeSObjectResult objResult = Schema.SObjectType.Grade_Enrollment__c;

        hed__Hierarchy_Settings__c hs = hed.UTIL_CustomSettings_API.getSettings();
        String adminRecordType = hs.hed__Administrative_Account_Record_Type__c;

        List<hed__Education_History__c> educationHistoryList = new List<hed__Education_History__c>();
        List<Grade_Enrollment__c> gradeEnrollmentsList = new List<Grade_Enrollment__c>();

        Id fakeFirstAccountId = GRER_DataInteg_TEST.getFakeId(Account.SObjectType);
        Id fakeSecondAccountId = GRER_DataInteg_TEST.getFakeId(Account.SObjectType);
        Id fakeContactId = GRER_DataInteg_TEST.getFakeId(Contact.SObjectType);

        for (Integer i = 0; i < 5; i++){
            Id fakeEduHistId = GRER_DataInteg_TEST.getFakeId(hed__Education_History__c.SObjectType);
            Id fakeGradeEnrollId = GRER_DataInteg_TEST.getFakeId(Grade_Enrollment__c.SObjectType);

            hed__Education_History__c testEduHist = new hed__Education_History__c(Id = fakeEduHistId,
                                                                                  hed__Contact__c = fakeContactId,
                                                                                  hed__Account__c = fakeFirstAccountId);

            Grade_Enrollment__c gradeEnroll = new Grade_Enrollment__c(Id = fakeGradeEnrollId,
                                                                      Contact__c = fakeContactId,
                                                                      Educational_Institution__c = fakeFirstAccountId,
                                                                      Grade_Level__c = 'Eighth Grade',
                                                                      Education_History__c = fakeEduHistId
                                                                     );

            gradeEnrollmentsList.add(gradeEnroll);
        }

        Test.startTest();
        GRER_DataInteg_TDTM gradeEnrollTdtm = new GRER_DataInteg_TDTM();
        List<Exception> exceptionsList = new List<Exception>();

        try{
            gradeEnrollTdtm.run((List<SObject>)gradeEnrollmentsList, null, triggerAction, objResult);
        } catch (Exception e){
            exceptionsList.add(e);
        }
        Test.stopTest();

        System.assertEquals(true, exceptionsList.isEmpty(), 'Inserting Grade Enrollments with matching Educational Institution should not display error messages.');
    }

    /*********************************************************************************************************
    * @description Test to verify that method run() displays an error message for updates to Grade 
    * Enrollment records with Education Institution fields that do not match the value specified on the associated
    * Education History records.
    *********************************************************************************************************/
    @isTest 
    private static void runBeforeUpdateMismatch(){
        hed.TDTM_Runnable.Action triggerAction = hed.TDTM_Runnable.Action.BeforeUpdate;
        Schema.DescribeSObjectResult objResult = Schema.SObjectType.Grade_Enrollment__c;

        hed__Hierarchy_Settings__c hs = hed.UTIL_CustomSettings_API.getSettings();
        String adminRecordType = hs.hed__Administrative_Account_Record_Type__c;

        List<Grade_Enrollment__c> newGradeEnrollmentsList = new List<Grade_Enrollment__c>();
        List<Grade_Enrollment__c> oldGradeEnrollmentsList = new List<Grade_Enrollment__c>();

        Id fakeFirstAccountId = GRER_DataInteg_TEST.getFakeId(Account.SObjectType);
        Id fakeSecondAccountId = GRER_DataInteg_TEST.getFakeId(Account.SObjectType);
        Id fakeContactId = GRER_DataInteg_TEST.getFakeId(Contact.SObjectType);

        for (Integer i = 0; i < 5; i++){
            Id fakeEduHistId = GRER_DataInteg_TEST.getFakeId(hed__Education_History__c.SObjectType);
            hed__Education_History__c testEduHist = new hed__Education_History__c(Id = fakeEduHistId,
                                                                                  hed__Contact__c = fakeContactId,
                                                                                  hed__Account__c = fakeFirstAccountId);

            Id fakeGradeEnrollId = GRER_DataInteg_TEST.getFakeId(Grade_Enrollment__c.SObjectType);

            Grade_Enrollment__c oldGradeEnroll = new Grade_Enrollment__c(Id = fakeGradeEnrollId,
                                                                         Contact__c = fakeContactId,
                                                                         Educational_Institution__c = fakeFirstAccountId,
                                                                         Grade_Level__c = 'Eighth Grade',
                                                                         Education_History__c = fakeEduHistId
                                                                        );

            Grade_Enrollment__c newGradeEnroll = oldGradeEnroll.clone(false);
            newGradeEnroll.Id = fakeGradeEnrollId;
            newGradeEnroll.Educational_Institution__c = fakeSecondAccountId;

            oldGradeEnrollmentsList.add(oldGradeEnroll);
            newGradeEnrollmentsList.add(newGradeEnroll);
        }

        Test.startTest();
        GRER_DataInteg_TDTM gradeEnrollTdtm = new GRER_DataInteg_TDTM();
        List<Exception> exceptionsList = new List<Exception>();

        try{
            gradeEnrollTdtm.run((List<SObject>)newGradeEnrollmentsList, (List<SObject>)oldGradeEnrollmentsList, triggerAction, objResult);
        } catch (Exception e){
            exceptionsList.add(e);
        }
        Test.stopTest();

        for (Exception error : exceptionsList){
            System.assertEquals(Label.GrErInstitutionMismatch, error.getMessage(), 'Inserting Grade Enrollments with mis-matching Educational Institution should display error messages.');
        }
    }

    /*********************************************************************************************************
    * @description Test to verify that method run() successfully processes updates to Grade 
    * Enrollment records when the Education Institution fields match the value specified on the associated
    * Education History records.
    *********************************************************************************************************/
    @isTest 
    private static void runBeforeUpdateMatching(){
        hed.TDTM_Runnable.Action triggerAction = hed.TDTM_Runnable.Action.BeforeUpdate;
        Schema.DescribeSObjectResult objResult = Schema.SObjectType.Grade_Enrollment__c;

        hed__Hierarchy_Settings__c hs = hed.UTIL_CustomSettings_API.getSettings();
        String adminRecordType = hs.hed__Administrative_Account_Record_Type__c;

        List<Grade_Enrollment__c> newGradeEnrollmentsList = new List<Grade_Enrollment__c>();
        List<Grade_Enrollment__c> oldGradeEnrollmentsList = new List<Grade_Enrollment__c>();

        Id fakeFirstAccountId = GRER_DataInteg_TEST.getFakeId(Account.SObjectType);
        Id fakeSecondAccountId = GRER_DataInteg_TEST.getFakeId(Account.SObjectType);
        Id fakeContactId = GRER_DataInteg_TEST.getFakeId(Contact.SObjectType);

        for (Integer i = 0; i < 5; i++){
            Id fakeEduHistId = GRER_DataInteg_TEST.getFakeId(hed__Education_History__c.SObjectType);
            Id fakeGradeEnrollId = GRER_DataInteg_TEST.getFakeId(Grade_Enrollment__c.SObjectType);
            
            hed__Education_History__c testEduHist = new hed__Education_History__c(Id = fakeEduHistId,
                                                                                hed__Contact__c = fakeContactId,
                                                                                hed__Account__c = fakeFirstAccountId);

            Grade_Enrollment__c oldGradeEnroll = new Grade_Enrollment__c(Id = fakeGradeEnrollId,
                                                                      Contact__c = fakeContactId,
                                                                      Educational_Institution__c = null,
                                                                      Grade_Level__c = 'Eighth Grade',
                                                                      Education_History__c = fakeEduHistId
                                                                     );

            Grade_Enrollment__c newGradeEnroll = oldGradeEnroll.clone(true);
            newGradeEnroll.Educational_Institution__c = fakeFirstAccountId;

            oldGradeEnrollmentsList.add(oldGradeEnroll);
            newGradeEnrollmentsList.add(newGradeEnroll);
        }

        Test.startTest();
        GRER_DataInteg_TDTM gradeEnrollTdtm = new GRER_DataInteg_TDTM();
        List<Exception> exceptionsList = new List<Exception>();

        try{
            gradeEnrollTdtm.run((List<SObject>)newGradeEnrollmentsList, (List<SObject>)oldGradeEnrollmentsList, triggerAction, objResult);
        } catch (Exception e){
            exceptionsList.add(e);
        }
        Test.stopTest();

        System.assertEquals(true, exceptionsList.isEmpty(), 'Inserting Grade Enrollments with matching Educational Institution should not display error messages.');
        
    }

    /*********************************************************************************************************
    * @description Test to verify that method run() does not result in errors when null SObject lists are 
    * provided as parameters.
    *********************************************************************************************************/
    @isTest 
    private static void runWithNullLists(){
        hed.TDTM_Runnable.Action triggerAction = hed.TDTM_Runnable.Action.BeforeInsert;
        Schema.DescribeSObjectResult objResult = Schema.SObjectType.Grade_Enrollment__c;

        Test.startTest();
        GRER_DataInteg_TDTM gradeEnrollTdtm = new GRER_DataInteg_TDTM();
        List<Exception> exceptionsList = new List<Exception>();

        try{
            gradeEnrollTdtm.run(null, null, triggerAction, objResult);
        } catch (Exception e){
            exceptionsList.add(e);
        }
        Test.stopTest();

        System.assertEquals(true, exceptionsList.isEmpty(), 'Execution with null lists should not display error messages.');

    }

    /*********************************************************************************************************
    * @description Helper method to generate a fake ID for a specified SObjectType.
    * @param sot The SObjectType of the fake Id to generate.
    * @return The fake Id.
    **********************************************************************************************************/
    static Integer s_num = 1;
    private static String getFakeId(Schema.SObjectType sot) {
        String result = String.valueOf(s_num++);
        return sot.getDescribe().getKeyPrefix() +
           '0'.repeat(12-result.length()) + result;
    }

    /*********************************************************************************************************
    * @description Helper method to disable insert and update triggers on Education History EDUHIS_DataInteg_TDTM
    * class to prevent collisions with Grade Enrollment trigger testing.
    **********************************************************************************************************/
    private static void disableEDUHISDataIntegTrigger() {
        //Insert HEDA Trigger Handlers
        List<hed.TDTM_Global_API.TdtmToken> hedaTokens = hed.TDTM_Global_API.getDefaultTdtmConfig();
        hed.TDTM_Global_API.setTdtmConfig(hedaTokens);

        //Insert K12 trigger handlers
        STG_InstallScript.setK12kitDefaultTriggerHandlers();

        for (hed.TDTM_Global_API.TdtmToken tdtmToken : hed.TDTM_Global_API.getTdtmConfig()){
            if (tdtmToken.className == 'EDUHIS_DataInteg_TDTM'){
                tdtmToken.active = false;
            }
        }
    }

}