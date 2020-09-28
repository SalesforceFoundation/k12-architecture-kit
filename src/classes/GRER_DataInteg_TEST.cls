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
* @description Test class for GRER_DataInteg_TDTM class to ensure that updates to the Educational 
* Institution on a Grade Enrollment record with a related Education History only occurs if the 
* institutions on both records match. */
@isTest
private class GRER_DataInteg_TEST {
    
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
            for (Integer i = 0; i < 5; i++){
                Grade_Enrollment__c gradeEnroll = new Grade_Enrollment__c(Contact__c = testContact.Id,
                                                                          Educational_Institution__c = firstAccount.Id,
                                                                          Grade_Level__c = 'Eighth Grade',
                                                                          Education_History__c = eduHist.Id);

                gradeEnrollmentsList.add(gradeEnroll);
            }
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

        System.assertEquals(25, gradeEnrollmentResultsList.size(), 'Five Grade Enrollment records should be successfully inserted.');

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
            for (Integer i = 0; i < 5; i++){
            Grade_Enrollment__c gradeEnroll = new Grade_Enrollment__c(Contact__c = testContact.Id,
                                                                      Educational_Institution__c = secondAccount.Id,
                                                                      Grade_Level__c = 'Second Grade',
                                                                      Education_History__c = eduHist.Id);

            gradeEnrollmentsList.add(gradeEnroll);
            }
        }

        Test.startTest();
        Database.SaveResult[] results = Database.insert(gradeEnrollmentsList, false);
        Test.stopTest();

        for (Database.SaveResult sr : results){
            System.assertEquals(false, sr.isSuccess(), 'Grade Enrollment insert should fail.');
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
            for (Integer i = 0; i < 5; i++){
                Grade_Enrollment__c gradeEnroll = new Grade_Enrollment__c(Contact__c = testContact.Id,
                                                                        Educational_Institution__c = null,
                                                                        Grade_Level__c = 'Eighth Grade',
                                                                        Education_History__c = eduHist.Id
                                                                        );
                gradeEnrollmentsList.add(gradeEnroll);
            }
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

        System.assertEquals(25, gradeEnrollmentResultsList.size(), 'Five Grade Enrollment records should be successfully inserted.');

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
        List<Account> accountsList = new List<Account>();

        Account firstAccount = new Account(RecordTypeId = adminRecordType, Name = 'Test Account 1');
        Account secondAccount = new Account(RecordTypeId = adminRecordType, Name = 'Test Account 2');
        accountsList.add(firstAccount);
        accountsList.add(secondAccount);
        insert accountsList;

        Contact testContact = new Contact(LastName = 'Testerson');
        insert testContact;

        for (Integer i = 0; i < 5; i++){
            hed__Education_History__c testEduHist = new hed__Education_History__c(hed__Contact__c = testContact.Id,
                                                                                  hed__Account__c = null);
            eduHistList.add(testEduHist);
        }

        insert eduHistList;

        for (hed__Education_History__c eduHist : eduHistList){
            Grade_Enrollment__c gradeEnroll1 = new Grade_Enrollment__c(Contact__c = testContact.Id,
                                                                      Educational_Institution__c = firstAccount.Id,
                                                                      Grade_Level__c = 'First Grade',
                                                                      Education_History__c = eduHist.Id);

            Grade_Enrollment__c gradeEnroll2 = new Grade_Enrollment__c(Contact__c = testContact.Id,
                                                                      Educational_Institution__c = secondAccount.Id,
                                                                      Grade_Level__c = 'Second Grade',
                                                                      Education_History__c = eduHist.Id);

            gradeEnrollmentsList.add(gradeEnroll1);
            gradeEnrollmentsList.add(gradeEnroll2);
        }

        Test.startTest();
        insert gradeEnrollmentsList;
        Test.stopTest();

        List<Grade_Enrollment__c> gradeEnrollmentResultsList = [SELECT Id,
                                                                       Educational_Institution__c,
                                                                       Education_History__c,
                                                                       Education_History__r.hed__Account__c,
                                                                       Grade_Level__c
                                                                FROM Grade_Enrollment__c
                                                                WHERE Id IN :gradeEnrollmentsList];

        System.assertEquals(10, gradeEnrollmentResultsList.size(), 'Ten Grade Enrollment records should be successfully inserted.');

        for (Grade_Enrollment__c gradeEnroll : gradeEnrollmentResultsList){
            System.assertEquals(true, String.isBlank(gradeEnroll.Education_History__r.hed__Account__c), 'Education History Institution field should remain blank.');
            System.assertEquals(true, gradeEnroll.Educational_Institution__c != gradeEnroll.Education_History__r.hed__Account__c, 'Educational Institution on Grade Enrollment and Education History should not match.');
        
            if (gradeEnroll.Grade_Level__c == 'First Grade'){
                System.assertEquals(firstAccount.Id, gradeEnroll.Educational_Institution__c, 'Grade Enrollment should be inserted with Institution field populated.');
            } else {
                System.assertEquals(secondAccount.Id, gradeEnroll.Educational_Institution__c, 'Grade Enrollment should be inserted with Institution field populated.');
            }
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
            for (Integer i = 0; i < 5; i++){
                Grade_Enrollment__c gradeEnroll = new Grade_Enrollment__c(Contact__c = testContact.Id,
                                                                          Educational_Institution__c = null,
                                                                          Grade_Level__c = 'Eighth Grade',
                                                                          Education_History__c = eduHist.Id);

                gradeEnrollmentsList.add(gradeEnroll);
            }
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

        System.assertEquals(25, gradeEnrollmentResultsList.size(), '25 Grade Enrollment records should be successfully inserted.');

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
        GRER_DataInteg_TEST.disableEducationHistoryDataIntegTrigger();

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
            for (Integer i = 0; i < 5; i++){
                Grade_Enrollment__c gradeEnroll = new Grade_Enrollment__c(Contact__c = testContact.Id,
                                                                          Educational_Institution__c = null,
                                                                          Grade_Level__c = 'Eighth Grade',
                                                                          Education_History__c = eduHist.Id);

                gradeEnrollmentsList.add(gradeEnroll);
            }
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
            for (Integer i = 0; i < 5; i++){
                Grade_Enrollment__c gradeEnroll = new Grade_Enrollment__c(Contact__c = testContact.Id,
                                                                        Educational_Institution__c = firstAccount.Id,
                                                                        Grade_Level__c = 'First Grade',
                                                                        Education_History__c = eduHist.Id);

                
                gradeEnrollmentsList.add(gradeEnroll);
            }
        }

        insert gradeEnrollmentsList;

        for (Grade_Enrollment__c gradeEnroll : gradeEnrollmentsList){
            gradeEnroll.Educational_Institution__c = secondAccount.Id;
        }

        Test.startTest();
        Database.SaveResult[] results = Database.update(gradeEnrollmentsList, false);
        Test.stopTest();

        for (Database.SaveResult sr : results){
            System.assertEquals(false, sr.isSuccess(), 'Grade Enrollment update should fail.');
            for (Database.Error err : sr.getErrors()){
                System.assertEquals(Label.GrErInstitutionMismatch, err.getMessage(), 'Grade Enrollment with mismatched Institution should not update.');
            }
        }

        List<Grade_Enrollment__c> gradeEnrollResulstList = [SELECT Id,
                                                                   Educational_Institution__c
                                                            FROM Grade_Enrollment__c
                                                            WHERE Id IN: gradeEnrollmentsList];

        for (Grade_Enrollment__c gradeEnroll : gradeEnrollResulstList){
            System.assertEquals(firstAccount.Id, gradeEnroll.Educational_Institution__c, 'Educational Institution on Education History should not update.');
        }
    }

    /*********************************************************************************************************
    * @description Test to verify that clearing the Educational Institution field on a Grade Enrollment record 
    * updates without error even if there is an Educational Institution specified on the associated Education 
    * History record.
    *********************************************************************************************************/
    @isTest 
    private static void updateGradeEnrollmentNullInstitution(){
        GRER_DataInteg_TEST.disableEducationHistoryDataIntegTrigger();

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
            Grade_Enrollment__c gradeEnroll1 = new Grade_Enrollment__c(Contact__c = testContact.Id,
                                                                      Educational_Institution__c = firstAccount.Id,
                                                                      Grade_Level__c = 'Eighth Grade',
                                                                      Education_History__c = eduHist.Id);

            Grade_Enrollment__c gradeEnroll2 = new Grade_Enrollment__c(Contact__c = testContact.Id,
                                                                      Educational_Institution__c = secondAccount.Id,
                                                                      Grade_Level__c = 'Eighth Grade',
                                                                      Education_History__c = eduHist.Id);

            gradeEnrollmentsList.add(gradeEnroll1);
            gradeEnrollmentsList.add(gradeEnroll2);
        }

        try{
            insert gradeEnrollmentsList;
        } catch (DmlException e){
            System.assertEquals(true, e.getMessage().contains(Label.GrErInstitutionMismatch), 'Inserting Grade Enrollments with mismatching Educational Institution should display error message.');
        }
        
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
    * @description Test to verify that updating the Educational Institution field on a Grade Enrollment 
    * record will process without error when the Educational Institution field on the associated Education 
    * History record is blank.
    *********************************************************************************************************/
    @isTest 
    private static void updateGradeEnrollmentNoInstitutionOnEducationHistory(){

        GRER_DataInteg_TEST.disableEducationHistoryDataIntegTrigger();

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
                                                                                  hed__Account__c = null);

            eduHistList.add(testEduHist);
        }

        insert eduHistList;

        for (hed__Education_History__c eduHist : eduHistList){
            Grade_Enrollment__c gradeEnrollNull = new Grade_Enrollment__c(Contact__c = testContact.Id,
                                                                      Educational_Institution__c = null,
                                                                      Grade_Level__c = 'Eighth Grade',
                                                                      Education_History__c = eduHist.Id);

            Grade_Enrollment__c gradeEnroll = new Grade_Enrollment__c(Contact__c = testContact.Id,
                                                                      Educational_Institution__c = firstAccount.Id,
                                                                      Grade_Level__c = 'Eighth Grade',
                                                                      Education_History__c = eduHist.Id);

            gradeEnrollmentsList.add(gradeEnroll);
        }

        insert gradeEnrollmentsList;

        for (Grade_Enrollment__c gradeEnroll : gradeEnrollmentsList){
            gradeEnroll.Educational_Institution__c = secondAccount.Id;
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
            System.assertEquals(secondAccount.Id, gradeEnroll.Educational_Institution__c, 'Institution on Grade Enrollment should be updated to new value.');
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
            for (Integer i = 0; i < 5; i++){
                Grade_Enrollment__c gradeEnroll = new Grade_Enrollment__c(Contact__c = testContact.Id,
                                                                        Educational_Institution__c = firstAccount.Id,
                                                                        Grade_Level__c = 'Eighth Grade',
                                                                        Education_History__c = eduHist.Id);

                gradeEnrollmentsList.add(gradeEnroll);
            }
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
    * @description Test to verify that method handleAfterUpdate() successfully processes updates to Grade 
    * Enrollment records when the Education Institution fields match the value specified on the associated
    * Education History records.
    *********************************************************************************************************/
    @isTest 
    private static void handleAfterUpdateWithoutMismatch(){
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
            for (Integer i = 0; i < 5; i++){
                Grade_Enrollment__c oldGradeEnroll = new Grade_Enrollment__c(Contact__c = testContact.Id,
                                                                            Educational_Institution__c = null,
                                                                            Grade_Level__c = 'Eighth Grade',
                                                                            Education_History__c = eduHist.Id);

                oldGradeEnrollmentsList.add(oldGradeEnroll);
            }
        }

        insert oldGradeEnrollmentsList;

        for (Grade_Enrollment__c gradeEnroll : oldGradeEnrollmentsList){
            Grade_Enrollment__c newGradeEnroll = gradeEnroll.clone(true);
            newGradeEnroll.Educational_Institution__c = firstAccount.Id;
            newGradeEnrollmentsList.add(newGradeEnroll);
        }
        
        GRER_DataInteg_TDTM gradeEnrollTdtm = new GRER_DataInteg_TDTM();
        List<Grade_Enrollment__c> gradeEnrollWithErrorList = new List<Grade_Enrollment__c>();
        
        Test.startTest();
        gradeEnrollWithErrorList = gradeEnrollTdtm.handleAfterUpdate((List<SObject>)newGradeEnrollmentsList, (List<SObject>)oldGradeEnrollmentsList);
        Test.stopTest();

        System.assertEquals(true, gradeEnrollWithErrorList.isEmpty(), 'Updates with matching Education Institution for Education History and Grade Enrollment should not display an error.'); 
    }

    /*********************************************************************************************************
    * @description Test to verify that method handleAfterUpdate() displays an error message for updates to Grade 
    * Enrollment records with Education Institution fields that do not match the value specified on the associated
    * Education History records.
    *********************************************************************************************************/
    @isTest 
    private static void handleAfterUpdateWithMismatch(){
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
            for (Integer i = 0; i < 5; i++){
                Grade_Enrollment__c oldGradeEnroll = new Grade_Enrollment__c(Contact__c = testContact.Id,
                                                                            Educational_Institution__c = firstAccount.Id,
                                                                            Grade_Level__c = 'Eighth Grade',
                                                                            Education_History__c = eduHist.Id
                                                                            );

                oldGradeEnrollmentsList.add(oldGradeEnroll);
            }
        }

        insert oldGradeEnrollmentsList;

        for (Grade_Enrollment__c gradeEnroll : oldGradeEnrollmentsList){
            Grade_Enrollment__c newGradeEnroll = gradeEnroll.clone(true);
            newGradeEnroll.Educational_Institution__c = secondAccount.Id;
            newGradeEnrollmentsList.add(newGradeEnroll);
        }

        GRER_DataInteg_TDTM gradeEnrollTdtm = new GRER_DataInteg_TDTM();

        Test.startTest();
        try{
            gradeEnrollTdtm.handleAfterUpdate((List<SObject>)newGradeEnrollmentsList, (List<SObject>)oldGradeEnrollmentsList);
        } catch (DmlException e){
            System.assertEquals(true, e.getMessage().contains(Label.GrErInstitutionMismatch), 'Updating Grade Enrollments with mismatching Educational Institution should display error message.');
        }
        Test.stopTest();
    }

    /*********************************************************************************************************
    * @description Test to verify that method handleAfterInsert() displays an error message when Grade 
    * Enrollment records with Education Institutions that do not match the value specified on the associated
    * Education History records are inserted.
    *********************************************************************************************************/
    @isTest 
    private static void handleAfterInsertWithMismatch(){
        GRER_DataInteg_TEST.disableEducationHistoryDataIntegTrigger();

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
                                                                                  hed__Account__c = null);
            eduHistList.add(testEduHist);
        }

        insert eduHistList;

        for (hed__Education_History__c eduHist : eduHistList){
            for (Integer i = 0; i < 5; i++){
                Grade_Enrollment__c gradeEnrollMismatch = new Grade_Enrollment__c(Contact__c = testContact.Id,
                                                                                Educational_Institution__c = secondAccount.Id,
                                                                                Grade_Level__c = 'Second Grade',
                                                                                Education_History__c = eduHist.Id);

                

                gradeEnrollmentsList.add(gradeEnrollMismatch);
            }
        }

        insert gradeEnrollmentsList;

        for (hed__Education_History__c eduHist : eduHistList){
            eduHist.hed__Account__c = firstAccount.Id;
        }

        update eduHistList;

        GRER_DataInteg_TDTM gradeEnrollTdtm = new GRER_DataInteg_TDTM();
        Test.startTest();
        List<Grade_Enrollment__c> gradeEnrollWithErrorsList = new List<Grade_Enrollment__c>();
        try{
            gradeEnrollWithErrorsList = gradeEnrollTdtm.handleAfterInsert((List<SObject>)gradeEnrollmentsList);
        } catch (DmlException e){
            System.assertEquals(true, e.getMessage().contains(Label.GrErInstitutionMismatch), 'Inserting Grade Enrollments with mismatching institution should result in an error.');
        }
        
        Test.stopTest();
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
            for (Integer i = 0; i < 5; i++){
                Grade_Enrollment__c gradeEnroll = new Grade_Enrollment__c(Contact__c = testContact.Id,
                                                                        Educational_Institution__c = firstAccount.Id,
                                                                        Grade_Level__c = 'Eighth Grade',
                                                                        Education_History__c = eduHist.Id
                                                                        );

                gradeEnrollmentsList.add(gradeEnroll);
            }
        }

        insert gradeEnrollmentsList;

        GRER_DataInteg_TDTM gradeEnrollTdtm = new GRER_DataInteg_TDTM();
        List<Grade_Enrollment__c> gradeEnrollWithErrorsList = new List<Grade_Enrollment__c>();

        Test.startTest();
        gradeEnrollWithErrorsList = gradeEnrollTdtm.handleAfterInsert((List<SObject>)gradeEnrollmentsList);
        Test.stopTest();

        System.assertEquals(true, gradeEnrollWithErrorsList.isEmpty(), 'Inserting Grade Enrollments with matching Educational Institution should not display error messages.');
    }

    /*********************************************************************************************************
    * @description Test to verify that method checkEducationalInstitutionAgainstEducationHistory() displays  
    * an error message when Grade Enrollment records with Education Institutions that do not match the value 
    * specified on the associated Education History records are inserted.
    *********************************************************************************************************/
    @isTest 
    private static void checkEducationalInstitutionAgainstEducationHistoryAfterInsertWithMismatch(){
        GRER_DataInteg_TEST.disableEducationHistoryDataIntegTrigger();

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
                                                                                  hed__Account__c = null);
            eduHistList.add(testEduHist);
        }

        insert eduHistList;

        for (hed__Education_History__c eduHist : eduHistList){
            Grade_Enrollment__c gradeEnrollMatch = new Grade_Enrollment__c(Contact__c = testContact.Id,
                                                                              Educational_Institution__c = firstAccount.Id,
                                                                              Grade_Level__c = 'Eighth Grade',
                                                                              Education_History__c = eduHist.Id);

            Grade_Enrollment__c gradeEnrollMismatch = new Grade_Enrollment__c(Contact__c = testContact.Id,
                                                                              Educational_Institution__c = secondAccount.Id,
                                                                              Grade_Level__c = 'Eighth Grade',
                                                                              Education_History__c = eduHist.Id);

            gradeEnrollmentsList.add(gradeEnrollMatch);
            gradeEnrollmentsList.add(gradeEnrollMismatch);
        }

        insert gradeEnrollmentsList;

        for (hed__Education_History__c eduHist : eduHistList){
            eduHist.hed__Account__c = firstAccount.Id;
        }

        update eduHistList;

        GRER_DataInteg_TDTM gradeEnrollTdtm = new GRER_DataInteg_TDTM();

        Test.startTest();
        try{
            List<Grade_Enrollment__c> gradeEnrollWithErrorsList = new List<Grade_Enrollment__c>();
            gradeEnrollWithErrorsList = gradeEnrollTdtm.checkEducationalInstitutionAgainstEducationHistory((List<SObject>)gradeEnrollmentsList);
        } catch (DmlException e){
            System.assertEquals(true, e.getMessage().contains(Label.GrErInstitutionMismatch), 'Inserting Grade Enrollments with mismatching Educational Institution should display error message.');
        }
        Test.stopTest();
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
            for (Integer i = 0; i < 5; i++){
                Grade_Enrollment__c gradeEnroll = new Grade_Enrollment__c(Contact__c = testContact.Id,
                                                                        Educational_Institution__c = firstAccount.Id,
                                                                        Grade_Level__c = 'Eighth Grade',
                                                                        Education_History__c = eduHist.Id);

                gradeEnrollmentsList.add(gradeEnroll);
            }
        }

        insert gradeEnrollmentsList;

        GRER_DataInteg_TDTM gradeEnrollTdtm = new GRER_DataInteg_TDTM();
        List<Grade_Enrollment__c> gradeEnrollWithErrorsList = new List<Grade_Enrollment__c>();

        Test.startTest();        
        gradeEnrollWithErrorsList = gradeEnrollTdtm.checkEducationalInstitutionAgainstEducationHistory((List<SObject>)gradeEnrollmentsList);
        Test.stopTest();

        System.assertEquals(true, gradeEnrollWithErrorsList.isEmpty(), 'Inserting Grade Enrollments with matching Educational Institution should not display error messages.');
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

        GRER_DataInteg_TDTM gradeEnrollTdtm = new GRER_DataInteg_TDTM();
        List<Grade_Enrollment__c> gradeEnrollWithErrorsList = new List<Grade_Enrollment__c>();

        Test.startTest();        
        gradeEnrollWithErrorsList = gradeEnrollTdtm.checkEducationalInstitutionAgainstEducationHistory((List<SObject>)newGradeEnrollmentsList, (List<SObject>)oldGradeEnrollmentsList);
        Test.stopTest();

        System.assertEquals(true, gradeEnrollWithErrorsList.isEmpty(), 'Updating Grade Enrollments with matching Educational Institution should not display error messages.');
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

        GRER_DataInteg_TDTM gradeEnrollTdtm = new GRER_DataInteg_TDTM();
        List<Grade_Enrollment__c> gradeEnrollWithErrorsList = new List<Grade_Enrollment__c>();

        Test.startTest();  
        try{
            gradeEnrollWithErrorsList = gradeEnrollTdtm.checkEducationalInstitutionAgainstEducationHistory((List<SObject>)newGradeEnrollmentsList, (List<SObject>)oldGradeEnrollmentsList);
        } catch (DmlException e){
            System.assertEquals(true, e.getMessage().contains(Label.GrErInstitutionMismatch), 'Updating Grade Enrollments with mis-matching Educational Institution should display error messages.');
        }
    }

    /*********************************************************************************************************
    * @description Test to verify that method run() displays an error message when Grade 
    * Enrollment records with Education Institutions that do not match the value specified on the associated
    * Education History records are inserted.
    *********************************************************************************************************/
    @isTest 
    private static void runAfterInsertMismatch(){
        GRER_DataInteg_TEST.disableEducationHistoryDataIntegTrigger();

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
                                                                                  hed__Account__c = null);
            eduHistList.add(testEduHist);
        }

        insert eduHistList;

        for (hed__Education_History__c eduHist : eduHistList){
            for (Integer i = 0; i < 5; i++){
                Grade_Enrollment__c gradeEnroll = new Grade_Enrollment__c(Contact__c = testContact.Id,
                                                                        Educational_Institution__c = secondAccount.Id,
                                                                        Grade_Level__c = 'Eighth Grade',
                                                                        Education_History__c = eduHist.Id
                                                                        );

                gradeEnrollmentsList.add(gradeEnroll);
            }
        }

        insert gradeEnrollmentsList;

        for (hed__Education_History__c eduHist : eduHistList){
            eduHist.hed__Account__c = firstAccount.Id;
        }

        update eduHistList;
       
        GRER_DataInteg_TDTM gradeEnrollTdtm = new GRER_DataInteg_TDTM();

        Test.startTest();
        try{
            gradeEnrollTdtm.run((List<SObject>)gradeEnrollmentsList, null, triggerAction, objResult);
        } catch (DmlException e){
            System.assertEquals(true, e.getMessage().contains(Label.GrErInstitutionMismatch), 'Inserting Grade Enrollments with mismatching Educational Institution should display error message.');
        }
        Test.stopTest();
    }

    /*********************************************************************************************************
    * @description Test to verify that method run() successfully processes and insert  Grade 
    * Enrollment records with Education Institutions that match the value specified on the associated
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
            for (Integer i = 0; i < 5; i++){
                Grade_Enrollment__c gradeEnroll = new Grade_Enrollment__c(Contact__c = testContact.Id,
                                                                        Educational_Institution__c = firstAccount.Id,
                                                                        Grade_Level__c = 'Eighth Grade',
                                                                        Education_History__c = eduHist.Id);

                gradeEnrollmentsList.add(gradeEnroll);
            }
        }
        
        insert gradeEnrollmentsList;

        GRER_DataInteg_TDTM gradeEnrollTdtm = new GRER_DataInteg_TDTM();

        Test.startTest();
        try{
            gradeEnrollTdtm.run((List<SObject>)gradeEnrollmentsList, null, triggerAction, objResult);
        } catch (DmlException e){
            System.assertEquals(false, e.getMessage().contains(Label.GrErInstitutionMismatch), 'Inserting Grade Enrollments with matching Educational Institution should not display error message.');
        }
        Test.stopTest();
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
            for (Integer i = 0; i < 5; i++){
                Grade_Enrollment__c oldGradeEnroll = new Grade_Enrollment__c(Contact__c = testContact.Id,
                                                                            Educational_Institution__c = firstAccount.Id,
                                                                            Grade_Level__c = 'Eighth Grade',
                                                                            Education_History__c = eduHist.Id);

                oldGradeEnrollmentsList.add(oldGradeEnroll);
            }
        }

        insert oldGradeEnrollmentsList;

        for (Grade_Enrollment__c gradeEnroll : oldGradeEnrollmentsList){
            Grade_Enrollment__c newGradeEnroll = gradeEnroll.clone(true);
            newGradeEnroll.Educational_Institution__c = secondAccount.Id;
            newGradeEnrollmentsList.add(newGradeEnroll);
        }

        GRER_DataInteg_TDTM gradeEnrollTdtm = new GRER_DataInteg_TDTM();

        Test.startTest();
        try{
            gradeEnrollTdtm.run((List<SObject>)newGradeEnrollmentsList, (List<SObject>)oldGradeEnrollmentsList, triggerAction, objResult);
        } catch (DmlException e){
            System.assertEquals(true, e.getMessage().contains(Label.GrErInstitutionMismatch), 'Updating Grade Enrollments with mismatching Educational Institution should display error message.');
        }
        Test.stopTest();
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
            for (Integer i = 0; i < 5; i++){
                Grade_Enrollment__c oldGradeEnroll = new Grade_Enrollment__c(Contact__c = testContact.Id,
                                                                            Educational_Institution__c = null,
                                                                            Grade_Level__c = 'Eighth Grade',
                                                                            Education_History__c = eduHist.Id
                                                                            );
                oldGradeEnrollmentsList.add(oldGradeEnroll);
            }
        }

        insert oldGradeEnrollmentsList;

        for (Grade_Enrollment__c gradeEnroll : oldGradeEnrollmentsList){
            Grade_Enrollment__c newGradeEnroll = gradeEnroll.clone(true);
            newGradeEnroll.Educational_Institution__c = firstAccount.Id;
            newGradeEnrollmentsList.add(newGradeEnroll);
        }

        Test.startTest();
        GRER_DataInteg_TDTM gradeEnrollTdtm = new GRER_DataInteg_TDTM();
        try{
            gradeEnrollTdtm.run((List<SObject>)newGradeEnrollmentsList, (List<SObject>)oldGradeEnrollmentsList, triggerAction, objResult);
        } catch (DmlException e){
            System.assertEquals(false, e.getMessage().contains(Label.GrErInstitutionMismatch), 'Inserting Grade Enrollments with matching Educational Institution should not display error messages.');
        }
        Test.stopTest();
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
        try{
            gradeEnrollTdtm.run(null, null, triggerAction, objResult);
        } catch (DmlException e){
            System.assertEquals(false, e.getMessage().contains(Label.GrErInstitutionMismatch), 'Executing Trigger with null lists should not display error messages.');
        }
        Test.stopTest();
    }

    /**********************************************************************************************************
    * @description Disables the Education History Data Integrity triggers to prevent conflicts and allow 
    * thorough testing of Grade Enrollment trigger functionality.
    **********************************************************************************************************/
    private static void disableEducationHistoryDataIntegTrigger(){
        for (hed.TDTM_Global_API.TdtmToken tdtmToken : hed.TDTM_Global_API.getTdtmConfig()){
            if (tdtmToken.className == UTIL_Namespace.StrTokenNSPrefixDotNotation('EDUHIS_DataInteg_TDTM')){
                tdtmToken.active = false;
            }
        }
    }
}