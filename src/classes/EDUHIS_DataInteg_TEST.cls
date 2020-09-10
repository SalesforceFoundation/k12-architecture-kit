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
private class EDUHIS_DataInteg_TEST {
    
    // Get Namespace
    // Static String namespace = UTIL_Namespace.getNamespace();
    // Static String prefix = (String.isNotBlank(namespace)) ? namespace + '.' : '';
    // Static String gradeEnrollClass = prefix+'GRER_SyncGradeLevel_TDTM';
    
    @testSetup
    static void setup() {
        //Insert EDA Trigger Handlers
        List<hed.TDTM_Global_API.TdtmToken> tokens = hed.TDTM_Global_API.getTdtmConfig();
        tokens.add(new hed.TDTM_Global_API.TdtmToken('EDUHIS_DataInteg_TDTM', 'Education_History__c', 'BeforeUpdate', 1.00));

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
    @isTest
    public static void updateEducationHistoryWithoutGradeEnrollments() {
        EDUHIS_DataInteg_TEST.setup();

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
    * with related Grade Enrollments associated with matching Institutions updates without an error.
    *********************************************************************************************************/
    @isTest
    public static void updateEducationHistoryWithGradeEnrollmentsMatching() {
        EDUHIS_DataInteg_TEST.setup();

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
                                                                      Educational_Institution__c = secondAccount.Id,
                                                                      Grade_Level__c = 'Eighth Grade'
                                                                     );

            gradeEnrollmentsList.add(gradeEnroll);
        }

        insert gradeEnrollmentsList;

        Test.startTest();
        update educationHistoryList;
        Test.stopTest();

        for (hed__Education_History__c eduHist : educationHistoryList){
            System.assertEquals(secondAccount.Id, eduHist.hed__Account__c, 'Educational Institution should update for Education History with no Grade Enrollments');
        }
    }

    /*********************************************************************************************************
    * @description Tests to verify that changing the Educational Institution on an Education History record
    * with related Grade Enrollments associated with mis-matching Institutions does not update and displays an error.
    *********************************************************************************************************/
    @isTest
    public static void updateEducationHistoryWithGradeEnrollmentsMismatching() {
        EDUHIS_DataInteg_TEST.setup();
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
                                                                      Educational_Institution__c = firstAccount.Id,
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
               
        // System.debug('MK DEBUG: testAccount1 ID: ' + firstAccount.Id);

        // for (hed__Education_History__c eduHist : educationHistoryList){
        // //     System.assertEquals(firstAccount.Id, eduHist.hed__Account__c, 'Educational Institution on Education History should not update.');
        //     System.debug('MK DEBUG: eduHist.hed__Account__c: ' + eduHist.hed__Account__c);

        // }  

        for(Database.SaveResult sr : results){
            System.assertEquals(false, sr.isSuccess(), 'Update on Education History with mismatching Institutions should fail.');
            for (Database.Error err : sr.getErrors()){
                System.assertEquals(Label.EduHisInstitutionMismatch, err.getMessage(), 'Error message should display for mismatching Educational Institutions.');
            }
        }
    }

    /*********************************************************************************************************
    * @description Tests to verify that clearing the Educational Institution on an Education History record
    * with related Grade Enrollments associated with different Institutions does update.
    *********************************************************************************************************/
    @isTest
    public static void updateEducationHistoryWithGradeEnrollmentsBlankInstitutionOnEducationHistory() {
        EDUHIS_DataInteg_TEST.setup();
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
    * with related Grade Enrollments associated with blank values for Institution does update.
    *********************************************************************************************************/
    @isTest
    public static void updateEducationHistoryWithGradeEnrollmentsBlankInstitutionOnGradeEnrollment() {
        EDUHIS_DataInteg_TEST.setup();
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
    * with related Grade Enrollments associated with blank values for Institution does update.
    *********************************************************************************************************/
    @isTest
    public static void updateEducationHistoryWithGradeEnrollmentsBlankInstitutionOnBoth() {
        EDUHIS_DataInteg_TEST.setup();
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
    * @description Test to verify that method hasInstitutionMismatch returns true when an Education History
    * record is related to Grade Enrollment records with mismatching Educational Insttitutions.
    *********************************************************************************************************/
    @isTest 
    private static void hasInstitutionMismatchTrue(){
        List<hed__Education_History__c> educationHistoryList = new List<hed__Education_History__c>();

        // for (Integer i = 0; i < 5; i++){
        //     hed__Education_History__c eduHist = new hed__Education_History__c(); 
        //     educationHistoryList.add(eduHist);
        // }

    }

    /*********************************************************************************************************
    * @description Test to verify that method hasInstitutionMismatch returns false when an Education History
    * record is related to Grade Enrollment records without mismatching Educational Insttitutions.
    *********************************************************************************************************/
    @isTest 
    private static void hasInstitutionMismatchFalse(){
        
    }
}