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
    
    // Get Namespace
    Static String namespace = UTIL_Namespace.getNamespace();
    Static String prefix = (String.isNotBlank(namespace)) ? namespace + '.' : '';
    Static String gradeEnrollClass = prefix+'GRER_SyncGradeLevel_TDTM';
    
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
        System.assertEquals(1, resultContacts.size(), 'There should be only one contact created');
        System.assertEquals('Prekindergarten', resultContacts[0].Current_Grade_Level__c, 'The current grade level of the contact is not updated properly');
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
        System.assertEquals(1, resultContacts.size(), 'There should be only one contact created');
        System.assertEquals('Transitional Kindergarten', resultContacts[0].Current_Grade_Level__c, 'The current grade level of the contact is not updated properly');

        List<Grade_Enrollment__c> resultGradeEnrollments= [SELECT Status__c FROM Grade_Enrollment__c];
        System.assertEquals(3, resultGradeEnrollments.size(), 'There should be 3 grade enrollments created');
        for (Grade_Enrollment__c ge : resultGradeEnrollments) {
            if (ge.Id == testNewGradeEnroll.Id) {
                System.assertEquals('Current', ge.Status__c, 'the new Grade Enrollment should be current');
            } else {
                System.assertEquals('Former', ge.Status__c, 'the old Grade Enrollment should be former');
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
        System.assertEquals(1, resultContacts.size(), 'There should be only one contact created');
        System.assertEquals('Prekindergarten', resultContacts[0].Current_Grade_Level__c, 'The current grade level of the contact is not updated properly');

        List<Grade_Enrollment__c> resultGradeEnrollments= [SELECT Status__c FROM Grade_Enrollment__c];
        System.assertEquals(3, resultGradeEnrollments.size(), 'There should be two grade enrollments created');
        for (Grade_Enrollment__c ge : resultGradeEnrollments) {
            if (ge.Id != testGradeEnroll.Id) {
                System.assertEquals('Former', ge.Status__c, 'the Old Grade Enrollment should be former');
            } else {
                System.assertEquals('Current', ge.Status__c, 'the New Grade Enrollment should be current');
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
        System.assertEquals(1, resultContacts.size(), 'There should be only one contact created');
        System.assertEquals('Preschool', resultContacts[0].Current_Grade_Level__c, 'The current grade level of the contact is not updated properly');

        List<Grade_Enrollment__c> resultGradeEnrollments= [SELECT Status__c FROM Grade_Enrollment__c];
        system.assertEquals(3, resultGradeEnrollments.size(), 'There should be two grade enrollments created');
        for (Grade_Enrollment__c ge : resultGradeEnrollments) {
            if (ge.Id == testNewGradeEnroll.Id) {
                System.assertEquals('Current', ge.Status__c, 'the new Grade Enrollment should be former');
            } else {
                System.assertEquals('Former', ge.Status__c, 'the old Grade Enrollment should be current');
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
        System.assertEquals(1, resultContacts.size(), 'There should be only one contact created');
        System.assertEquals('Transitional Kindergarten', resultContacts[0].Current_Grade_Level__c, 'The current grade level of the contact is not updated properly');

        List<Grade_Enrollment__c> resultGradeEnrollments= [SELECT Status__c FROM Grade_Enrollment__c];
        System.assertEquals(3, resultGradeEnrollments.size(), 'There should be 3 grade enrollments created');
        for (Grade_Enrollment__c ge : resultGradeEnrollments) {
            if (ge.Id == testNewGradeEnroll.Id) {
                System.assertEquals('Current', ge.Status__c, 'the new Grade Enrollment should be former');
            } else {
                System.assertEquals('Former', ge.Status__c, 'the old Grade Enrollment should be current');
            }
        }
    }

    /*********************************************************************************************************
    * @description This method ensures Current Grade Level is cleared when Grade Enrollment's status is changed
    * from current
    */
    @isTest
    private static void clearCurrentGradeEnrollment() {
        
        // Insert Contact
        Contact testContact = hed.UTIL_UnitTestData_API.getContact();
        insert testContact;
        
        // Insert Grade Enrollment
        Grade_Enrollment__c testGradeEnroll = new Grade_Enrollment__c(Status__c = 'Current', Grade_Level__c = 'Prekindergarten', Contact__c = testContact.Id);
        insert testGradeEnroll;
        
        // Ensure Current Grade Level is populated on Contact
        Contact conAfterUpdate1 = [SELECT Id, Current_Grade_Level__c FROM CONTACT];
        System.assertEquals(conAfterUpdate1.Current_Grade_Level__c, 'Prekindergarten', 'Current Grade Level should be populated');
        
        // Ensure Current Grade Level is cleared on Contact when its related Grade Level Enrollment is cleared     
        Test.startTest();
            testGradeEnroll.Status__c = 'Former';
            update testGradeEnroll;
        Test.stopTest();
        
        Contact conAfterUpdate = [SELECT Id, Current_Grade_Level__c FROM CONTACT];
        System.assertEquals('NotApplicable', conAfterUpdate.Current_Grade_Level__c, 'Current Grade Level should change to not applicable');

    } 
    
    /*********************************************************************************************************
    * @description This method ensures an error is shown when a Contact's Current Grade Enrollment is changed
    * when there are multiple Current Grade Enrollments
    */
    @isTest
    private static void currentGradeEnrollmentError() {
        
        // Insert Contact
        Contact testContact = hed.UTIL_UnitTestData_API.getContact();
        insert testContact;

        // Insert Grade Enrollment        
        Grade_Enrollment__c testGradeEnroll = new Grade_Enrollment__c(Status__c = 'Current', Grade_Level__c = 'Prekindergarten', Contact__c = testContact.Id);
        insert testGradeEnroll;
        
        // Ensure Current Grade Level is populated on Contact
        Contact conAfterUpdate1 = [SELECT Id, Current_Grade_Level__c FROM CONTACT];
        System.assertEquals(conAfterUpdate1.Current_Grade_Level__c, 'Prekindergarten', 'Current Grade Level should be populated');
        
        // Turn off Trigger handler
        hed__Trigger_Handler__c handler = [SELECT Id, hed__Active__c , hed__Trigger_Action__c  
                                  FROM hed__Trigger_Handler__c  WHERE hed__Class__c = :gradeEnrollClass LIMIT 1];        
        handler.hed__Active__c = False;
        update handler;
        
        // Insert multiple Current Grade Enrollments 
        Grade_Enrollment__c testGradeEnroll1 = new Grade_Enrollment__c(Status__c = 'Current', Grade_Level__c = 'First Grade', Contact__c = testContact.Id);
        Grade_Enrollment__c testGradeEnroll2 = new Grade_Enrollment__c(Status__c = 'Current', Grade_Level__c = 'Second Grade', Contact__c = testContact.Id);
        
        insert new Grade_Enrollment__c[] {testGradeEnroll1, testGradeEnroll2};
        
        // Ensure error is thrown when there are multiple Current Garde Enrollments
        try {
             Test.startTest();
                 hed__Trigger_Handler__c handlerUpdate = [SELECT Id, hed__Active__c , hed__Trigger_Action__c  
                                                          FROM hed__Trigger_Handler__c  WHERE 
                                                          hed__Class__c = :gradeEnrollClass LIMIT 1];        
                 handlerUpdate.hed__Active__c = True;
                 update handlerUpdate;
        
                 Grade_Enrollment__c currentGradeEnroll = [SELECT Id, Status__c FROM Grade_Enrollment__c WHERE Id = :testGradeEnroll.Id];
                 currentGradeEnroll.Status__c = 'Former';
                 update currentGradeEnroll;
             Test.stopTest();
            } catch(Exception error) {
                  System.assert(error.getMessage().contains(Label.MultipleCurrentGradeEnrollmentsError));
              }                   
    }
    
    /*********************************************************************************************************
    * @description This method ensures Current Grade Level is changed when there is one additional Current Grade 
    * Enrollment 
    */
    @isTest
    private static void changeCurrentGradeEnrollment() {
        
        // Insert Contact
        Contact testContact = hed.UTIL_UnitTestData_API.getContact();
        insert testContact;

        // Insert Grade Enrollment        
        Grade_Enrollment__c testGradeEnroll = new Grade_Enrollment__c(Status__c = 'Current', Grade_Level__c = 'Prekindergarten', Contact__c = testContact.Id);
        insert testGradeEnroll;
        
        // Ensure Current Grade Level is populated on Contact
        Contact conAfterUpdate1 = [SELECT Id, Current_Grade_Level__c FROM CONTACT];
        System.assertEquals(conAfterUpdate1.Current_Grade_Level__c, 'Prekindergarten', 'Current Grade Level should be populated');
        
        // Turn off Trigger handler
        hed__Trigger_Handler__c handler = [SELECT Id, hed__Active__c , hed__Trigger_Action__c  
                                  FROM hed__Trigger_Handler__c  WHERE hed__Class__c = :gradeEnrollClass LIMIT 1];        
        handler.hed__Active__c = False;
        update handler;
        
        // Insert a Current Grade Enrollment 
        Grade_Enrollment__c anotherGradeEnroll = new Grade_Enrollment__c(Status__c = 'Current', Grade_Level__c = 'First Grade', Contact__c = testContact.Id);
        insert anotherGradeEnroll;
        
        // Ensure Current Grade Enrollment is changed
        Test.startTest();
            hed__Trigger_Handler__c handlerUpdate = [SELECT Id, hed__Active__c , hed__Trigger_Action__c  
                                                     FROM hed__Trigger_Handler__c  WHERE 
                                                     hed__Class__c = :gradeEnrollClass LIMIT 1];        
            handlerUpdate.hed__Active__c = True;
            update handlerUpdate;
                 
            testGradeEnroll.Status__c = 'Former';
            update testGradeEnroll;
        Test.stopTest();
        
        Contact contactAfterUpdate = [SELECT Id, Current_Grade_Level__c FROM CONTACT];
        System.assertEquals('First Grade', contactAfterUpdate.Current_Grade_Level__c, 'Current Grade Level should change from Prekindergarten to First Grade');
       
    } 
    
    /*********************************************************************************************************
    * @description This method ensures bulk updates are successfully run
    */
    @isTest
    private static void gradeEnrollmentBulkCheck() {
        
        // Insert Contacts
        Contact testContact1 = hed.UTIL_UnitTestData_API.getContact();
        Contact testContact2 = hed.UTIL_UnitTestData_API.getContact();
        Contact testContact3 = hed.UTIL_UnitTestData_API.getContact();
        
        insert new Contact[] {testContact1, testContact2, testContact3};
        
        // Insert Grade Enrollments
        Grade_Enrollment__c testGradeEnroll1 = new Grade_Enrollment__c(Status__c = 'Current', Grade_Level__c = 'Prekindergarten', Contact__c = testContact1.Id);
        Grade_Enrollment__c testGradeEnroll2 = new Grade_Enrollment__c(Status__c = 'Current', Grade_Level__c = 'Prekindergarten', Contact__c = testContact2.Id);
        Grade_Enrollment__c testGradeEnroll3 = new Grade_Enrollment__c(Status__c = 'Current', Grade_Level__c = 'Prekindergarten', Contact__c = testContact3.Id);
        
        insert new Grade_Enrollment__c[] {testGradeEnroll1, testGradeEnroll2, testGradeEnroll3};
        
        // Ensure Current Grade Level is populated
        List<Contact> contactList = [SELECT Id, Current_Grade_Level__c FROM Contact];
        for (Contact eachCon: contactList) {
            System.assertEquals('Prekindergarten', eachCon.Current_Grade_Level__c, 'Current Grade Level should be populated');                
        }
        
        // Turn off Trigger handler
        hed__Trigger_Handler__c handler = [SELECT Id, hed__Active__c , hed__Trigger_Action__c  
                                           FROM hed__Trigger_Handler__c  WHERE hed__Class__c = :gradeEnrollClass LIMIT 1];        
        handler.hed__Active__c = False;
        update handler;
        
        // Insert multiple Grade Enrollments
        Grade_Enrollment__c testGradeEnroll4 = new Grade_Enrollment__c(Status__c = 'Former', Grade_Level__c = 'First Grade', Contact__c = testContact1.Id);
        Grade_Enrollment__c testGradeEnroll5 = new Grade_Enrollment__c(Status__c = 'Current', Grade_Level__c = 'First Grade', Contact__c = testContact2.Id);
        Grade_Enrollment__c testGradeEnroll6 = new Grade_Enrollment__c(Status__c = 'Current', Grade_Level__c = 'First Grade', Contact__c = testContact3.Id);
        Grade_Enrollment__c testGradeEnroll7 = new Grade_Enrollment__c(Status__c = 'Current', Grade_Level__c = 'Second Grade', Contact__c = testContact3.Id);
        Grade_Enrollment__c testGradeEnroll8 = new Grade_Enrollment__c(Status__c = 'Current', Grade_Level__c = 'Third Grade', Contact__c = testContact3.Id);
                
        insert new Grade_Enrollment__c[] {testGradeEnroll4, testGradeEnroll5, testGradeEnroll6, testGradeEnroll7, testGradeEnroll8};
        
        hed__Trigger_Handler__c handlerUpdate = [SELECT Id, hed__Active__c , hed__Trigger_Action__c  
                                                 FROM hed__Trigger_Handler__c  WHERE hed__Class__c = :gradeEnrollClass LIMIT 1];        
        handlerUpdate.hed__Active__c = True;
        update handlerUpdate;
        
        // Ensure bulk updates run successfully
        try {
            Test.startTest();
                List<Grade_Enrollment__c> updateList = new List<Grade_Enrollment__c>();        
        	    List<Grade_Enrollment__c> allEnrollments = [SELECT Id, Status__c FROM Grade_Enrollment__c
                                                            WHERE Status__c = 'Current' AND (Grade_Level__c = 'Prekindergarten'
                                                            OR Grade_Level__c = 'Third Grade')];
                for (Grade_Enrollment__c eachEnrollment : allEnrollments) {            
                    eachEnrollment.Status__c = 'Former';
                    updateList.add(eachEnrollment);
                } 
                Database.update(updateList, false);        
            Test.stopTest();
        } catch(Exception error) {
              System.assert(error.getMessage().contains(Label.MultipleCurrentGradeEnrollmentsError));            
          }
        
        Contact updateContact1 = [SELECT Id, Current_Grade_Level__c FROM Contact WHERE Current_Grade_Level__c = 'NotApplicable'];        
        Contact updateContact2 = [SELECT Id, Current_Grade_Level__c FROM Contact WHERE Current_Grade_Level__c = 'First Grade'];
        Contact updateContact3 = [SELECT Id, Current_Grade_Level__c FROM Contact WHERE Current_Grade_Level__c = 'Prekindergarten'];
        
        System.assertEquals('NotApplicable', updateContact1.Current_Grade_Level__c, 'Current Grade Level should change to Not Applicable from Prekindergarten');
        System.assertEquals('First Grade', updateContact2.Current_Grade_Level__c, 'Current Grade Level should change to First Grade from Prekindergarten');
        System.assertEquals('Prekindergarten', updateContact3.Current_Grade_Level__c,'Current Grade Level should remain same');
    }

    /*********************************************************************************************************
    * @description This method Contact's Current Grade Enrollment is updated when one grade enrollment is marked
    * as current and one is marked as former in the same execution.
    * when there are multiple Current Grade Enrollments
    */
    @isTest
    private static void concurrentUpdates() {
        
        // Insert Contact
        Contact testContact = hed.UTIL_UnitTestData_API.getContact();
        insert testContact;

        // Insert Grade Enrollment        
        Grade_Enrollment__c currentGradeEnroll = new Grade_Enrollment__c(Status__c = 'Current', Grade_Level__c = 'First Grade', Contact__c = testContact.Id);
        Grade_Enrollment__c formerGradeEnroll = new Grade_Enrollment__c(Status__c = 'Former', Grade_Level__c = 'Second Grade', Contact__c = testContact.Id);
        insert new Grade_Enrollment__c[] {currentGradeEnroll, formerGradeEnroll};
        
        // Ensure Current Grade Level is populated on Contact
        Contact conAfterUpdate1 = [SELECT Id, Current_Grade_Level__c FROM CONTACT];
        System.assertEquals(conAfterUpdate1.Current_Grade_Level__c, 'First Grade');
        
        /* Ensure Current Grade Enrollment is updated when one grade enrollment is marked
           as current and one is marked as former in the same execution. */
        Test.startTest();
            List<Grade_Enrollment__c> gradeEnrollList = new List<Grade_Enrollment__c>();
            currentGradeEnroll.Status__c = 'Former';
            formerGradeEnroll.status__c = 'Current';
            gradeEnrollList.add(currentGradeEnroll);
            gradeEnrollList.add(formerGradeEnroll);
            update gradeEnrollList;
        Test.stopTest();
        
        Contact updatedContact = [SELECT Id, Current_Grade_Level__c FROM Contact];
        System.assertEquals('Second Grade', updatedContact.Current_Grade_Level__c, 'Current Grade Level should change from First Grade to Second Grade');       
    }           
}