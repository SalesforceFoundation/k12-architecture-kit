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

    /*********************************************************************************************************
    * @description Create a Grade Enrollment and related Contact does not have existing grade enrollments
    */
    @isTest
    public static void insertCurrentGradeErollment() {
        //Test data setup
        Contact testContact = hed.UTIL_UnitTestData_API.getContact();
        testContact.Current_Grade_Level__c = 'Preschool';
        insert testContact;

        Grade_Enrollment__c testGradeEnroll = new Grade_Enrollment__c(Status__c = 'Current', Grade_Level__c = 'Prekindergarten');

        //Test the code
        Test.startTest();
            insert testGradeEnroll;          
        Test.stopTest();

        //Assert the results
        List<Contact> resultContacts = [SELECT Current_Grade_Level__c FROM Contact];
        system.assertEquals(1, acresultContact.size(), 'There should be one and only one contact created');
        system.assertEquals('Prekindergarten', resultContacts[0].Current_Grade_Level__c, 'The current grade level of the contact is not updated properly');
    }
}