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
* @group Contacts
* @group-content ../../ApexDocContent/Contact.htm
* @description Tests for CON_CurrentGradeLevel_TDTM class*/

@isTest
private class CON_CurrentGradeLevel_TEST {

    @testSetup
    static void setup() {
        //Insert HEDA Trigger Handlers
        List<hed.TDTM_Global_API.TdtmToken> hedaTokens = hed.TDTM_Global_API.getDefaultTdtmConfig();
        hed.TDTM_Global_API.setTdtmConfig(hedaTokens);

        //Insert K12 trigger handlers
        STG_InstallScript.setK12kitDefaultTriggerHandlers();
    }
    
    /*********************************************************************************************************
    * @description This test method ensures creation of new Grade Enrollments when a Contact with Current Grade
    * Level is inserted.
    */
    @isTest
    public static void newGradeEnrollmentCreation() {
        
        // Insert 3 Contacts with Current Grade Level, 1 with no Current Grade Level and 1 Contact with Current Grade Level 'Not Applicable'
        Test.startTest();
            List<Contact> contactsToInsert = new List<Contact>();
            for (Integer i = 0; i < 3; i++) {
                Contact testContact = hed.UTIL_UnitTestData_API.getContact();
                testContact.Current_Grade_Level__c = 'Preschool';
                contactsToInsert.add(testContact);    
            }
            Contact testContact1 = hed.UTIL_UnitTestData_API.getContact();
            Contact testContact2 = hed.UTIL_UnitTestData_API.getContact();
            testContact2.Current_Grade_Level__c = 'NotApplicable';
            contactsToInsert.add(testContact1);
            contactsToInsert.add(testContact2);
        
            if (contactsToInsert != NULL && contactsToInsert.size() > 0) {
                insert contactsToInsert;    
            }
        Test.stopTest();
        
        // Make sure Grade Enrollments are created only for the Contacts with Current Grade Level Populated
        List<Grade_Enrollment__c> gradeEnrollList = [SELECT Id, Contact__c, Status__c FROM Grade_Enrollment__c];
        System.assertEquals(3, gradeEnrollList.size());
        
        // Make sure COntact is populated on the Grade Enrollments and their status is set to 'Current'
        for (Grade_Enrollment__c each: gradeEnrollList) {
            System.assertNotEquals(NULL, each.Contact__c);
            System.assertEquals('Current', each.Status__c);       
        }        
    }
    /*********************************************************************************************************
    * @description This test method ensures creation of new Grade Enrollments when a Contact with Current Grade
    * Level is updated. It also tests that older Current Grade Enrollments are changed to 'Former'
    */
    @isTest
    public static void gradeEnrollmentCreationForContactUpdated() {

        List<Contact> contactsToInsert = new List<Contact>();

        Contact testContact1 = hed.UTIL_UnitTestData_API.getContact();
        testContact1.Current_Grade_Level__c = 'Preschool';
        Contact testContact2 = hed.UTIL_UnitTestData_API.getContact();
        testContact2.Current_Grade_Level__c = 'First Grade';
        Contact testContact3 = hed.UTIL_UnitTestData_API.getContact();
        testContact3.Current_Grade_Level__c = 'NotApplicable';
         
        contactsToInsert.add(testContact1);
        contactsToInsert.add(testContact2);
        contactsToInsert.add(testContact3);
         
        insert contactsToInsert;
         
        // Make sure Grade Enrollments are created only for the Contacts with Current Grade Level Populated
        List<Grade_Enrollment__c> gradeEnrollList = [SELECT Id, Contact__c, Status__c FROM Grade_Enrollment__c];
        System.assertEquals(2, gradeEnrollList.size());
        
        // Make sure Contact is populated on the Grade Enrollments and their status is set to 'Current'
        for (Grade_Enrollment__c each: gradeEnrollList) {
            System.assertNotEquals(NULL, each.Contact__c);
            System.assertEquals('Current', each.Status__c);       
        }
        
        Test.startTest();
            List<Contact> contactsToUpdate = new List<Contact>();

            testContact1.Current_Grade_Level__c = 'First Grade';
            testContact2.Current_Grade_Level__c = 'NotApplicable';
            testContact3.Current_Grade_Level__c = 'Preschool';
        
            contactsToUpdate.add(testContact1);
            contactsToUpdate.add(testContact2);
            contactsToUpdate.add(testContact3);
        
            update contactsToUpdate;
        Test.stopTest();
        
        // Ensure new Grade Enrollment record is created with Status 'Current' and old Grade Enrollment is changed to 'Former'
        Contact conAfterUpdate1 = [SELECT Id, Current_Grade_Level__c, (SELECT Id, Status__c, Grade_Level__c FROM Grade_Enrollments__r
                                                                        ORDER BY Status__c ASC)
                                    FROM Contact WHERE Id = :testContact1.Id];
        System.assertEquals('First Grade', conAfterUpdate1.Current_Grade_Level__c);
        System.assertEquals(2, conAfterUpdate1.Grade_Enrollments__r.size());
        System.assertEquals('First Grade', conAfterUpdate1.Grade_Enrollments__r[0].Grade_Level__c);
        System.assertEquals('Preschool', conAfterUpdate1.Grade_Enrollments__r[1].Grade_Level__c);
        System.assertEquals('Current', conAfterUpdate1.Grade_Enrollments__r[0].Status__c);
        System.assertEquals('Former', conAfterUpdate1.Grade_Enrollments__r[1].Status__c);
        
        // Ensure no new Grade Enrollment records are created and Status on Grade Enrollment record is updated to 'Former'
        Contact conAfterUpdate2 = [SELECT Id, Current_Grade_Level__c, (SELECT Id, Status__c, Grade_Level__c FROM Grade_Enrollments__r)
                                    FROM Contact WHERE Id = :testContact2.Id];
        System.assertEquals('NotApplicable', conAfterUpdate2.Current_Grade_Level__c);
        System.assertEquals(1, conAfterUpdate2.Grade_Enrollments__r.size());
        System.assertEquals('Former', conAfterUpdate2.Grade_Enrollments__r[0].Status__c);
        
        // Ensure new Grade Enrollment records is created with Status 'Current'
        Contact conAfterUpdate3 = [SELECT Id, Current_Grade_Level__c, (SELECT Id, Status__c, Grade_Level__c FROM Grade_Enrollments__r)
                                    FROM Contact WHERE Id = :testContact3.Id];
        System.assertEquals('Preschool', conAfterUpdate3.Current_Grade_Level__c);
        System.assertEquals(1, conAfterUpdate3.Grade_Enrollments__r.size());
        System.assertEquals('Current', conAfterUpdate3.Grade_Enrollments__r[0].Status__c);
        System.assertEquals('Preschool', conAfterUpdate3.Grade_Enrollments__r[0].Grade_Level__c);
    }
}