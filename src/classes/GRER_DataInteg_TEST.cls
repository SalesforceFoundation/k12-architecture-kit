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
* @description Test class for GRER_DataInteg_TDTM class to ensure that updates to the Educational 
* Institution on a Grade Enrollment record with a related Education History only occurs if the 
* institutions on both records match. */
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
    * @description Test to verify that clearing the Educational Institution field on a Grade Enrollment record 
    * updates without error even if there is an Educational Institution specified on the associated Education 
    * History record.
    *********************************************************************************************************/
    @isTest 
    private static void updateGradeEnrollmentNullInstitution(){
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
            gradeEnroll.Educational_Institution__c = null;
        }

        Test.startTest();
        Database.SaveResult[] results = Database.update(gradeEnrollmentsList, false);
        Test.stopTest();

        List<Grade_Enrollment__c> gradeEnrollmentResultsList = [SELECT Id,
                                                                       Educational_Institution__c,
                                                                       Education_History__c,
                                                                       Education_History__r.hed__Account__c
                                                                FROM Grade_Enrollment__c
                                                                WHERE Id IN :gradeEnrollmentsList];

        for (Grade_Enrollment__c gradeEnroll : gradeEnrollmentResultsList){
            System.assertEquals(null, gradeEnroll.Educational_Institution__c, 'Education History Institution field on Grade Enrollment should be cleared.');
            System.assertEquals(true, gradeEnroll.Educational_Institution__c != gradeEnroll.Education_History__r.hed__Account__c, 'Educational Institution on Grade Enrollment and Education History should not match.');
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

    /************************************************************************************************************
    * @description Test method to verify that isInsertRecursion returns true when the recursion flag for
    * GRER_DataInteg_TDTM_After_Insert is set.
    *************************************************************************************************************/ 
    @isTest 
    private static void isGRERDataIntegInsertRecursionTrue(){
        TDTM_ProcessControl.setRecursionFlag(TDTM_ProcessControl.registeredTrigger.GRER_DataInteg_TDTM_After_Insert, true);

        GRER_DataInteg_TDTM grerTdtm = new GRER_DataInteg_TDTM();

        Test.startTest();
        System.assertEquals(true, grerTdtm.isInsertRecursion(), 'Insert recursion status for GRER_DataInteg_TDTM_After_Insert should be true.');
        Test.stopTest();
    }

    /************************************************************************************************************
    * @description Test method to verify that isInsertRecursion returns false when the recursion flag for
    * GRER_DataInteg_TDTM_After_Insert is not set.
    *************************************************************************************************************/ 
    @isTest 
    private static void isGRERDataIntegInsertRecursionFalse(){
        TDTM_ProcessControl.setRecursionFlag(TDTM_ProcessControl.registeredTrigger.GRER_DataInteg_TDTM_After_Insert, false);

        GRER_DataInteg_TDTM grerTdtm = new GRER_DataInteg_TDTM();

        Test.startTest();
        System.assertEquals(false, grerTdtm.isInsertRecursion(), 'Insert recursion status for GRER_DataInteg_TDTM_After_Insert should be false.');
        Test.stopTest();
    }

    /************************************************************************************************************
    * @description Test method to verify that unsetInsertRecursion correctly updates the status of the 
    * GRER_DataInteg_TDTM_After_Insert recursion flag to false.
    *************************************************************************************************************/ 
    @isTest 
    private static void unsetInsertRecursionTrue(){
        TDTM_ProcessControl.setRecursionFlag(TDTM_ProcessControl.registeredTrigger.GRER_DataInteg_TDTM_After_Insert, true);

        GRER_DataInteg_TDTM grerTdtm = new GRER_DataInteg_TDTM();

        Test.startTest();
        grerTdtm.unsetInsertRecursion();
        Test.stopTest();

        System.assertEquals(false, TDTM_ProcessControl.getRecursionFlag(TDTM_ProcessControl.registeredTrigger.GRER_DataInteg_TDTM_After_Insert), 'Insert recursion flag for GRER_DataInteg_TDTM_After_Insert should be cleared.');
    }

     /************************************************************************************************************
    * @description Test method to verify that unsetInsertRecursion does not clear the status of the 
    * GRER_DataInteg_TDTM_After_Insert recursion flag to if it is already set to false.
    *************************************************************************************************************/ 
    @isTest 
    private static void unsetInsertRecursionFalse(){
        TDTM_ProcessControl.setRecursionFlag(TDTM_ProcessControl.registeredTrigger.GRER_DataInteg_TDTM_After_Insert, false);

        GRER_DataInteg_TDTM grerTdtm = new GRER_DataInteg_TDTM();

        Test.startTest();
        grerTdtm.unsetInsertRecursion();
        Test.stopTest();

        System.assertEquals(false, TDTM_ProcessControl.getRecursionFlag(TDTM_ProcessControl.registeredTrigger.GRER_DataInteg_TDTM_After_Insert), 'Insert recursion flag for GRER_DataInteg_TDTM_After_Insert should be remain cleared.');
    }

    /************************************************************************************************************
    * @description Test method to verify that setInsertRecursion correctly updates the status of the 
    * GRER_DataInteg_TDTM_After_Insert recursion flag to true.
    *************************************************************************************************************/ 
    @isTest 
    private static void setInsertRecursionTrue(){
        TDTM_ProcessControl.setRecursionFlag(TDTM_ProcessControl.registeredTrigger.GRER_DataInteg_TDTM_After_Insert, false);

        GRER_DataInteg_TDTM grerTdtm = new GRER_DataInteg_TDTM();

        Test.startTest();
        grerTdtm.setInsertRecursion();
        Test.stopTest();

        System.assertEquals(true, TDTM_ProcessControl.getRecursionFlag(TDTM_ProcessControl.registeredTrigger.GRER_DataInteg_TDTM_After_Insert), 'Insert recursion flag for GRER_DataInteg_TDTM_After_Insert should be set.');
    }

     /************************************************************************************************************
    * @description Test method to verify that setInsertRecursion does not update the status of the 
    * GRER_DataInteg_TDTM_After_Insert recursion flag when it is already set to true.
    *************************************************************************************************************/ 
    @isTest 
    private static void setInsertRecursionFalse(){
        TDTM_ProcessControl.setRecursionFlag(TDTM_ProcessControl.registeredTrigger.GRER_DataInteg_TDTM_After_Insert, true);

        GRER_DataInteg_TDTM grerTdtm = new GRER_DataInteg_TDTM();

        Test.startTest();
        grerTdtm.setInsertRecursion();
        Test.stopTest();

        System.assertEquals(true, TDTM_ProcessControl.getRecursionFlag(TDTM_ProcessControl.registeredTrigger.GRER_DataInteg_TDTM_After_Insert), 'Insert recursion flag for GRER_DataInteg_TDTM_After_Insert should remain set.');
    }

    /*********************************************************************************************************
    * @description Test to verify that method checkEducationalInstitutionAgainstEducationHistory() displays  
    * an error message when Grade Enrollment records with Education Institutions that do not match the value 
    * specified on the associated Education History records are inserted.
    *********************************************************************************************************/
    @isTest 
    private static void checkEducationalInstitutionAgainstEducationHistoryAfterInsertWithMismatch(){
        hed__Hierarchy_Settings__c hs = hed.UTIL_CustomSettings_API.getSettings();
        String adminRecordType = hs.hed__Administrative_Account_Record_Type__c;

        List<Grade_Enrollment__c> gradeEnrollmentsList = new List<Grade_Enrollment__c>();
        List<hed__Education_History__c> eduHistList = new List<hed__Education_History__c>();
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
                                                                      Educational_Institution__c = secondAccount.Id,
                                                                      Grade_Level__c = 'Eighth Grade',
                                                                      Education_History__c = eduHist.Id);

            gradeEnrollmentsList.add(gradeEnroll);
        }

        insert gradeEnrollmentsList;
        
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
    * @description Test to verify that method handleBeforeUpdate() successfully processes updates to Grade 
    * Enrollment records when the Education Institution fields match the value specified on the associated
    * Education History records.
    *********************************************************************************************************/
    @isTest 
    private static void handleBeforeUpdateWithoutMismatch(){
        hed__Hierarchy_Settings__c hs = hed.UTIL_CustomSettings_API.getSettings();
        String adminRecordType = hs.hed__Administrative_Account_Record_Type__c;

        List<Grade_Enrollment__c> newGradeEnrollmentsList = new List<Grade_Enrollment__c>();
        List<Grade_Enrollment__c> oldGradeEnrollmentsList = new List<Grade_Enrollment__c>();
        List<Grade_Enrollment__c> gradeEnrollmentsList = new List<Grade_Enrollment__c>();
        List<hed__Education_History__c> eduHistList = new List<hed__Education_History__c>();
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
            Grade_Enrollment__c oldGradeEnroll = new Grade_Enrollment__c(Contact__c = testContact.Id,
                                                                         Educational_Institution__c = null,
                                                                         Grade_Level__c = 'Eighth Grade',
                                                                         Education_History__c = eduHist.Id);

            oldGradeEnrollmentsList.add(oldGradeEnroll);
        }

        insert oldGradeEnrollmentsList;

        for (Grade_Enrollment__c gradeEnroll : oldGradeEnrollmentsList){
            Grade_Enrollment__c newGradeEnroll = gradeEnroll.clone(true);
            newGradeEnroll.Educational_Institution__c = firstAccount.Id;
            newGradeEnrollmentsList.add(newGradeEnroll);
        }
        
        Test.startTest();
        GRER_DataInteg_TDTM gradeEnrollTdtm = new GRER_DataInteg_TDTM();
        List<Exception> exceptionsList = new List<Exception>();

        try{
            gradeEnrollTdtm.handleBeforeUpdate((List<SObject>)newGradeEnrollmentsList, (List<SObject>)oldGradeEnrollmentsList);
        } catch (Exception e){
            exceptionsList.add(e);
        }
        Test.stopTest();

        System.assertEquals(true, exceptionsList.isEmpty(), 'Inserting Grade Enrollments with matching Educational Institution should not display error messages.');
    }

    /*********************************************************************************************************
    * @description Test to verify that method handleBeforeUpdate() displays an error message for updates to Grade 
    * Enrollment records with Education Institution fields that do not match the value specified on the associated
    * Education History records.
    *********************************************************************************************************/
    @isTest 
    private static void handleBeforeUpdateWithMismatch(){
        hed__Hierarchy_Settings__c hs = hed.UTIL_CustomSettings_API.getSettings();
        String adminRecordType = hs.hed__Administrative_Account_Record_Type__c;

        List<Grade_Enrollment__c> newGradeEnrollmentsList = new List<Grade_Enrollment__c>();
        List<Grade_Enrollment__c> oldGradeEnrollmentsList = new List<Grade_Enrollment__c>();
        List<Grade_Enrollment__c> gradeEnrollmentsList = new List<Grade_Enrollment__c>();
        List<hed__Education_History__c> eduHistList = new List<hed__Education_History__c>();
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
            Grade_Enrollment__c oldGradeEnroll = new Grade_Enrollment__c(Contact__c = testContact.Id,
                                                                         Educational_Institution__c = firstAccount.Id,
                                                                         Grade_Level__c = 'Eighth Grade',
                                                                         Education_History__c = eduHist.Id
                                                                        );

            oldGradeEnrollmentsList.add(oldGradeEnroll);
        }

        insert oldGradeEnrollmentsList;

        for (Grade_Enrollment__c gradeEnroll : oldGradeEnrollmentsList){
            Grade_Enrollment__c newGradeEnroll = gradeEnroll.clone(true);
            newGradeEnroll.Educational_Institution__c = secondAccount.Id;
            newGradeEnrollmentsList.add(newGradeEnroll);
        }

        Test.startTest();
        GRER_DataInteg_TDTM gradeEnrollTdtm = new GRER_DataInteg_TDTM();
        List<Exception> exceptionsList = new List<Exception>();

        try{
            gradeEnrollTdtm.handleBeforeUpdate((List<SObject>)newGradeEnrollmentsList, (List<SObject>)oldGradeEnrollmentsList);
        } catch (Exception e){
            exceptionsList.add(e);
        }
        Test.stopTest();

        for (Exception error : exceptionsList){
            System.assertEquals(Label.GrErInstitutionMismatch, error.getMessage(), 'Inserting Grade Enrollments with mis-matching Educational Institution should display error messages.');
        }
    }

    /*********************************************************************************************************
    * @description Test to verify that method handleAfterInsert() displays an error message when Grade 
    * Enrollment records with Education Institutions that do not match the value specified on the associated
    * Education History records are inserted.
    *********************************************************************************************************/
    @isTest 
    private static void handleAfterInsertWithMismatch(){
        hed__Hierarchy_Settings__c hs = hed.UTIL_CustomSettings_API.getSettings();
        String adminRecordType = hs.hed__Administrative_Account_Record_Type__c;
        TDTM_ProcessControl.setRecursionFlag(TDTM_ProcessControl.registeredTrigger.GRER_DataInteg_TDTM_After_Insert, false);

        List<Grade_Enrollment__c> gradeEnrollmentsList = new List<Grade_Enrollment__c>();
        List<hed__Education_History__c> eduHistList = new List<hed__Education_History__c>();
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
                                                                      Educational_Institution__c = secondAccount.Id,
                                                                      Grade_Level__c = 'Eighth Grade',
                                                                      Education_History__c = eduHist.Id
                                                                     );

            gradeEnrollmentsList.add(gradeEnroll);
        }

        insert gradeEnrollmentsList;

        GRER_DataInteg_TDTM gradeEnrollTdtm = new GRER_DataInteg_TDTM();
        List<Exception> exceptionsList = new List<Exception>();

        Test.startTest();
        try{
            gradeEnrollTdtm.handleAfterInsert((List<SObject>)gradeEnrollmentsList);
        } catch (Exception e){
            exceptionsList.add(e);
        }
        Test.stopTest();

        for (Exception err : exceptionsList){
            System.assertEquals(Label.GrErInstitutionMismatch, err.getMessage(), 'Inserting Grade Enrollments with mismatching Educational Institution should display error message.');
        }
    }

    /*********************************************************************************************************
    * @description Test to verify that method handleAfterInsert() successfully processes and insert  Grade 
    * Enrollment records with Education Institutions that do not match the value specified on the associated
    * Education History records are inserted.
    *********************************************************************************************************/
    @isTest 
    private static void handleAfterInsertWithoutMismatch(){
        hed__Hierarchy_Settings__c hs = hed.UTIL_CustomSettings_API.getSettings();
        String adminRecordType = hs.hed__Administrative_Account_Record_Type__c;
        TDTM_ProcessControl.setRecursionFlag(TDTM_ProcessControl.registeredTrigger.GRER_DataInteg_TDTM_After_Insert, false);

        List<Grade_Enrollment__c> gradeEnrollmentsList = new List<Grade_Enrollment__c>();
        List<hed__Education_History__c> eduHistList = new List<hed__Education_History__c>();
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

        GRER_DataInteg_TDTM gradeEnrollTdtm = new GRER_DataInteg_TDTM();
        List<Exception> exceptionsList = new List<Exception>();

        Test.startTest();
        try{
            gradeEnrollTdtm.handleAfterInsert((List<SObject>)gradeEnrollmentsList);
        } catch (Exception e){
            exceptionsList.add(e);
        }
        Test.stopTest();

        System.assertEquals(true, exceptionsList.isEmpty(), 'Inserting Grade Enrollments with matching Educational Institution should not display error messages.');
    }

    @isTest 
    private static void handleAfterInsertRecursion(){
        hed__Hierarchy_Settings__c hs = hed.UTIL_CustomSettings_API.getSettings();
        String adminRecordType = hs.hed__Administrative_Account_Record_Type__c;
        TDTM_ProcessControl.setRecursionFlag(TDTM_ProcessControl.registeredTrigger.GRER_DataInteg_TDTM_After_Insert, true);

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
                                                                      Educational_Institution__c = fakeSecondAccountId,
                                                                      Grade_Level__c = 'Eighth Grade',
                                                                      Education_History__c = fakeEduHistId
                                                                     );

            gradeEnrollmentsList.add(gradeEnroll);
        }

        GRER_DataInteg_TDTM gradeEnrollTdtm = new GRER_DataInteg_TDTM();
        List<Exception> exceptionsList = new List<Exception>();

        Test.startTest();
        try{
            gradeEnrollTdtm.handleAfterInsert((List<SObject>)gradeEnrollmentsList);
        } catch (Exception e){
            exceptionsList.add(e);
        }
        Test.stopTest();

        System.assertEquals(true, exceptionsList.isEmpty(), 'Inserting Grade Enrollments in after insert recursion context should not display error messages.');
        System.assertEquals(true, TDTM_ProcessControl.getRecursionFlag(TDTM_ProcessControl.registeredTrigger.GRER_DataInteg_TDTM_After_Insert), 'Recursion flag should remain set.');
    }

    /*********************************************************************************************************
    * @description Test to verify that method checkEducationalInstitutionAgainstEducationHistory() processes 
    * an insert of Grade Enrollment records with Education Institutions that do not match the value specified 
    * on the associated Education History records are inserted.
    *********************************************************************************************************/
    @isTest 
    private static void checkEducationalInstitutionAgainstEducationHistoryAfterInsertWithoutMismatch(){
        hed__Hierarchy_Settings__c hs = hed.UTIL_CustomSettings_API.getSettings();
        String adminRecordType = hs.hed__Administrative_Account_Record_Type__c;

        List<Grade_Enrollment__c> gradeEnrollmentsList = new List<Grade_Enrollment__c>();
        List<hed__Education_History__c> eduHistList = new List<hed__Education_History__c>();
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

        GRER_DataInteg_TDTM gradeEnrollTdtm = new GRER_DataInteg_TDTM();
        List<Exception> exceptionsList = new List<Exception>();

        Test.startTest();
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
        List<hed__Education_History__c> eduHistList = new List<hed__Education_History__c>();
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

            Grade_Enrollment__c oldGradeEnroll = new Grade_Enrollment__c(Contact__c = testContact.Id,
                                                                         Educational_Institution__c = null,
                                                                         Grade_Level__c = 'Eighth Grade',
                                                                         Education_History__c = eduHist.Id
                                                                        );

            oldGradeEnrollmentsList.add(oldGradeEnroll);
            
        }
        
        insert oldGradeEnrollmentsList;

        for (Grade_Enrollment__c gradeEnroll : oldGradeEnrollmentsList){
            Grade_Enrollment__c newGradeEnroll = gradeEnroll.clone(true);
            newGradeEnroll.Educational_Institution__c = firstAccount.Id;
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
        List<hed__Education_History__c> eduHistList = new List<hed__Education_History__c>();
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
            Grade_Enrollment__c oldGradeEnroll = new Grade_Enrollment__c(Contact__c = testContact.Id,
                                                                         Educational_Institution__c = firstAccount.Id,
                                                                         Grade_Level__c = 'Eighth Grade',
                                                                         Education_History__c = eduHist.Id
                                                                        );
            oldGradeEnrollmentsList.add(oldGradeEnroll);
        }

        insert oldGradeEnrollmentsList;

        for (Grade_Enrollment__c gradeEnroll : oldGradeEnrollmentsList){
            Grade_Enrollment__c newGradeEnroll = gradeEnroll.clone(true);
            newGradeEnroll.Educational_Institution__c = secondAccount.Id;
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
    private static void runAfterInsertMismatch(){
        hed.TDTM_Runnable.Action triggerAction = hed.TDTM_Runnable.Action.AfterInsert;
        Schema.DescribeSObjectResult objResult = Schema.SObjectType.Grade_Enrollment__c;

        hed__Hierarchy_Settings__c hs = hed.UTIL_CustomSettings_API.getSettings();
        String adminRecordType = hs.hed__Administrative_Account_Record_Type__c;

        List<Grade_Enrollment__c> gradeEnrollmentsList = new List<Grade_Enrollment__c>();
        List<hed__Education_History__c> eduHistList = new List<hed__Education_History__c>();
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
                                                                      Educational_Institution__c = secondAccount.Id,
                                                                      Grade_Level__c = 'Eighth Grade',
                                                                      Education_History__c = eduHist.Id
                                                                     );

            gradeEnrollmentsList.add(gradeEnroll);
        }

        insert gradeEnrollmentsList;

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
    private static void runAfterInsertMatching(){
        hed.TDTM_Runnable.Action triggerAction = hed.TDTM_Runnable.Action.AfterInsert;
        Schema.DescribeSObjectResult objResult = Schema.SObjectType.Grade_Enrollment__c;

        hed__Hierarchy_Settings__c hs = hed.UTIL_CustomSettings_API.getSettings();
        String adminRecordType = hs.hed__Administrative_Account_Record_Type__c;

        List<Grade_Enrollment__c> gradeEnrollmentsList = new List<Grade_Enrollment__c>();
        List<hed__Education_History__c> eduHistList = new List<hed__Education_History__c>();
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
                                                                      Education_History__c = eduHist.Id);

            gradeEnrollmentsList.add(gradeEnroll);
        }

        insert gradeEnrollmentsList;

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
        List<hed__Education_History__c> eduHistList = new List<hed__Education_History__c>();
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
            Grade_Enrollment__c oldGradeEnroll = new Grade_Enrollment__c(Contact__c = testContact.Id,
                                                                         Educational_Institution__c = firstAccount.Id,
                                                                         Grade_Level__c = 'Eighth Grade',
                                                                         Education_History__c = eduHist.Id);

            oldGradeEnrollmentsList.add(oldGradeEnroll);
        }

        insert oldGradeEnrollmentsList;

        for (Grade_Enrollment__c gradeEnroll : oldGradeEnrollmentsList){
            Grade_Enrollment__c newGradeEnroll = gradeEnroll.clone(true);
            newGradeEnroll.Educational_Institution__c = secondAccount.Id;
            newGradeEnrollmentsList.add(newGradeEnroll);
        }

        GRER_DataInteg_TDTM gradeEnrollTdtm = new GRER_DataInteg_TDTM();
        List<Exception> exceptionsList = new List<Exception>();

        Test.startTest();
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
        List<hed__Education_History__c> eduHistList = new List<hed__Education_History__c>();
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

            Grade_Enrollment__c oldGradeEnroll = new Grade_Enrollment__c(Contact__c = testContact.Id,
                                                                         Educational_Institution__c = null,
                                                                         Grade_Level__c = 'Eighth Grade',
                                                                         Education_History__c = eduHist.Id
                                                                        );
            oldGradeEnrollmentsList.add(oldGradeEnroll);
        }

        insert oldGradeEnrollmentsList;

        for (Grade_Enrollment__c gradeEnroll : oldGradeEnrollmentsList){
            Grade_Enrollment__c newGradeEnroll = gradeEnroll.clone(true);
            newGradeEnroll.Educational_Institution__c = firstAccount.Id;
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
        hed.TDTM_Runnable.Action triggerAction = hed.TDTM_Runnable.Action.AfterInsert;
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
}