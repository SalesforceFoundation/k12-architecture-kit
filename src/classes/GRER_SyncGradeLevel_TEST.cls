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
private class GRER_SyncGradeLevel_TEST {

    @testSetup
    static void setup() {
        //Insert HEDA Trigger Handlers
        List<hed.TDTM_Global_API.TdtmToken> hedaTokens = hed.TDTM_Global_API.getDefaultTdtmConfig();
        hed.TDTM_Global_API.setTdtmConfig(hedaTokens);

        //Insert K12 trigger handlers
        STG_InstallScript.setK12kitDefaultTriggerHandlers();
    }

    /*********************************************************************************************************
    * @description Create a Grade Enrollment and related Contact does not have existing grade enrollments
    */
    @isTest
    public static void insertCurrentGradeErollmentNonExistingGE() {
        //Test data setup
        Contact testContact = hed.UTIL_UnitTestData_API.getContact();
        testContact.Current_Grade_Level__c = 'Preschool';
        insert testContact;

        Grade_Enrollment__c testGradeEnroll = new Grade_Enrollment__c(Status__c = 'Current', Grade_Level__c = 'Prekindergarten', Contact__c = testContact.Id);

        //Run the code
        Test.startTest();
        insert testGradeEnroll;          
        Test.stopTest();

        //Assert the results
        List<Contact> resultContacts = [SELECT Current_Grade_Level__c FROM Contact];
        system.assertEquals(1, resultContacts.size(), 'There should be only one contact created');
        system.assertEquals('Prekindergarten', resultContacts[0].Current_Grade_Level__c, 'The current grade level of the contact is not updated properly');
    }

    /*********************************************************************************************************
    * @description Create a Grade Enrollment and related Contact does have existing grade enrollments
    */
    @isTest
    public static void insertCurrentGradeErollmentExistingGE() {
        //Test data setup
        Contact testContact = hed.UTIL_UnitTestData_API.getContact();
        testContact.Current_Grade_Level__c = 'Preschool';
        insert testContact;
        
        Grade_Enrollment__c GradeEnroll = [SELECT Id, Status__c, Grade_Level__c, Contact__c FROM Grade_Enrollment__c];
        System.assertEquals('Current', GradeEnroll.Status__c, 'A Grade Enrollment should have been created after a contact is inserted');
        System.assertEquals('Preschool', GradeEnroll.Grade_Level__c, 'Status should match Contact\'s Current Grade Level');
        System.assertEquals(testContact.Id, GradeEnroll.Contact__c, 'Grade Level should be linked to Contact');
        
        Grade_Enrollment__c testGradeEnroll = new Grade_Enrollment__c(Status__c = 'Current', Grade_Level__c = 'Prekindergarten', Contact__c = testContact.Id);
        insert testGradeEnroll;

        Grade_Enrollment__c testNewGradeEnroll = new Grade_Enrollment__c(Status__c = 'Current', Grade_Level__c = 'Transitional Kindergarten', Contact__c = testContact.Id);

        //Run the code
        Test.startTest();
        insert testNewGradeEnroll;          
        Test.stopTest();

        //Assert the results
        List<Contact> resultContacts = [SELECT Current_Grade_Level__c FROM Contact];
        system.assertEquals(1, resultContacts.size(), 'There should be only one contact created');
        system.assertEquals('Transitional Kindergarten', resultContacts[0].Current_Grade_Level__c, 'The current grade level of the contact is not updated properly');

        List<Grade_Enrollment__c> resultGradeEnrollments= [SELECT Status__c FROM Grade_Enrollment__c];
        system.assertEquals(3, resultGradeEnrollments.size(), 'There should be 3 grade enrollments created');
        for (Grade_Enrollment__c ge : resultGradeEnrollments) {
            if (ge.Id == testNewGradeEnroll.Id) {
                system.assertEquals('Current', ge.Status__c, 'the new Grade Enrollment should be current');
            } else {
                system.assertEquals('Former', ge.Status__c, 'the old Grade Enrollment should be former');
            }
        }
    }

    /*********************************************************************************************************
    * @description Update a former Grade Enrollment to current
    */
    @isTest
    public static void updateFormerGradeErollmentToCurrent() {
        //Test data setup
        Contact testContact = hed.UTIL_UnitTestData_API.getContact();
        testContact.Current_Grade_Level__c = 'Preschool';
        insert testContact;
        
        Grade_Enrollment__c GradeEnroll = [SELECT Id, Status__c, Grade_Level__c, Contact__c FROM Grade_Enrollment__c];
        System.assertEquals('Current', GradeEnroll.Status__c, 'A Grade Enrollment should have been created after a contact is inserted');
        System.assertEquals('Preschool', GradeEnroll.Grade_Level__c, 'Status should match Contact\'s Current Grade Level');
        System.assertEquals(testContact.Id, GradeEnroll.Contact__c, 'Grade Level should be linked to Contact');
        
        Grade_Enrollment__c testGradeEnroll = new Grade_Enrollment__c(Status__c = 'Current', Grade_Level__c = 'Prekindergarten', Contact__c = testContact.Id);
        insert testGradeEnroll;

        Grade_Enrollment__c testNewGradeEnroll = new Grade_Enrollment__c(Status__c = 'Current', Grade_Level__c = 'Transitional Kindergarten', Contact__c = testContact.Id);

        //Run the code
        Test.startTest();
        insert testNewGradeEnroll;
        testGradeEnroll.Status__c = 'Current';
        update testGradeEnroll;        
        Test.stopTest();

        //Assert the results
        List<Contact> resultContacts = [SELECT Current_Grade_Level__c FROM Contact];
        system.assertEquals(1, resultContacts.size(), 'There should be only one contact created');
        system.assertEquals('Prekindergarten', resultContacts[0].Current_Grade_Level__c, 'The current grade level of the contact is not updated properly');

        List<Grade_Enrollment__c> resultGradeEnrollments= [SELECT Status__c FROM Grade_Enrollment__c];
        system.assertEquals(3, resultGradeEnrollments.size(), 'There should be two grade enrollments created');
        for (Grade_Enrollment__c ge : resultGradeEnrollments) {
            if (ge.Id != testGradeEnroll.Id) {
                system.assertEquals('Former', ge.Status__c, 'the Old Grade Enrollment should be former');
            } else {
                system.assertEquals('Current', ge.Status__c, 'the New Grade Enrollment should be current');
            }
        }
    }

    /*********************************************************************************************************
    * @description Update the grade level of a current Grade Enrollment
    */
    @isTest
    public static void updateCurrentGradeErollmentGradeLevel() {
        //Test data setup
        Contact testContact = hed.UTIL_UnitTestData_API.getContact();
        testContact.Current_Grade_Level__c = 'Preschool';
        insert testContact;
        
        Grade_Enrollment__c GradeEnroll = [SELECT Id, Status__c, Grade_Level__c, Contact__c FROM Grade_Enrollment__c];
        System.assertEquals('Current', GradeEnroll.Status__c, 'A Grade Enrollment should have been created after a contact is inserted');
        System.assertEquals('Preschool', GradeEnroll.Grade_Level__c, 'Status should match Contact\'s Current Grade Level');
        System.assertEquals(testContact.Id, GradeEnroll.Contact__c, 'Grade Level should be linked to Contact');
        
        Grade_Enrollment__c testGradeEnroll = new Grade_Enrollment__c(Status__c = 'Current', Grade_Level__c = 'Prekindergarten', Contact__c = testContact.Id);
        insert testGradeEnroll;

        Grade_Enrollment__c testNewGradeEnroll = new Grade_Enrollment__c(Status__c = 'Current', Grade_Level__c = 'Transitional Kindergarten', Contact__c = testContact.Id);

        //Run the code
        Test.startTest();
        insert testNewGradeEnroll;
        testNewGradeEnroll.Grade_Level__c = 'Preschool';
        update testNewGradeEnroll;        
        Test.stopTest();

        //Assert the results
        List<Contact> resultContacts = [SELECT Current_Grade_Level__c FROM Contact];
        system.assertEquals(1, resultContacts.size(), 'There should be only one contact created');
        system.assertEquals('Preschool', resultContacts[0].Current_Grade_Level__c, 'The current grade level of the contact is not updated properly');

        List<Grade_Enrollment__c> resultGradeEnrollments= [SELECT Status__c FROM Grade_Enrollment__c];
        system.assertEquals(3, resultGradeEnrollments.size(), 'There should be two grade enrollments created');
        for (Grade_Enrollment__c ge : resultGradeEnrollments) {
            if (ge.Id == testNewGradeEnroll.Id) {
                system.assertEquals('Current', ge.Status__c, 'the new Grade Enrollment should be former');
            } else {
                system.assertEquals('Former', ge.Status__c, 'the old Grade Enrollment should be current');
            }
        }
    }

    /*********************************************************************************************************
    * @description Update the grade level of a former Grade Enrollment
    */
    @isTest
    public static void updateFormerGradeErollmentGradeLevel() {
        //Test data setup
        Contact testContact = hed.UTIL_UnitTestData_API.getContact();
        testContact.Current_Grade_Level__c = 'Preschool';
        insert testContact;
        
        Grade_Enrollment__c GradeEnroll = [SELECT Id, Status__c, Grade_Level__c, Contact__c FROM Grade_Enrollment__c];
        System.assertEquals('Current', GradeEnroll.Status__c, 'A Grade Enrollment should have been created after a contact is inserted');
        System.assertEquals('Preschool', GradeEnroll.Grade_Level__c, 'Status should match Contact\'s Current Grade Level');
        System.assertEquals(testContact.Id, GradeEnroll.Contact__c, 'Grade Level should be linked to Contact');
        
        Grade_Enrollment__c testGradeEnroll = new Grade_Enrollment__c(Status__c = 'Former', Grade_Level__c = 'Prekindergarten', Contact__c = testContact.Id);
        insert testGradeEnroll;

        Grade_Enrollment__c testNewGradeEnroll = new Grade_Enrollment__c(Status__c = 'Current', Grade_Level__c = 'Transitional Kindergarten', Contact__c = testContact.Id);
        insert testNewGradeEnroll;

        //Run the code
        Test.startTest();
        testGradeEnroll.Grade_Level__c = 'Preschool';
        update testGradeEnroll;        
        Test.stopTest();


        //Assert the results
        List<Contact> resultContacts = [SELECT Current_Grade_Level__c FROM Contact];
        system.assertEquals(1, resultContacts.size(), 'There should be only one contact created');
        system.assertEquals('Transitional Kindergarten', resultContacts[0].Current_Grade_Level__c, 'The current grade level of the contact is not updated properly');

        List<Grade_Enrollment__c> resultGradeEnrollments= [SELECT Status__c FROM Grade_Enrollment__c];
        system.assertEquals(3, resultGradeEnrollments.size(), 'There should be 3 grade enrollments created');
        for (Grade_Enrollment__c ge : resultGradeEnrollments) {
            if (ge.Id == testNewGradeEnroll.Id) {
                system.assertEquals('Current', ge.Status__c, 'the new Grade Enrollment should be former');
            } else {
                system.assertEquals('Former', ge.Status__c, 'the old Grade Enrollment should be current');
            }
        }
    }
}