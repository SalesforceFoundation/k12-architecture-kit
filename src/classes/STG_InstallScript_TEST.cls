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
* @group Settings
* @group-content ../../ApexDocContent/Settings.htm
* @description Tests for STG_InstallScript class*/
@isTest
private class STG_InstallScript_TEST {

    /*********************************************************************************************************
    * @description Test fresh install
    */
    @isTest
	public static void freshInstall() {
        //Run the code
        Test.startTest();
        Test.testInstall(new STG_InstallScript(), null);
        Test.stopTest();

        ////Assert the results
        List<hed__Trigger_Handler__c> triggerHandlers = [SELECT hed__Owned_by_Namespace__c FROM hed__Trigger_Handler__c];
        System.assertEquals(TDTM_DefaultConfig.getDefaultTokens().size(), triggerHandlers.size());

        for (hed__Trigger_Handler__c triggerHandler : triggerHandlers) {
            // Verify Owned by namespace field set on first item in list
            System.assertEquals('k12kit', triggerHandler.hed__Owned_by_Namespace__c, 'Namespace does not match');
        }
	}

    /*********************************************************************************************************
    * @description Test push Upgrade
    */
    @isTest
	public static void pushUpgrade() {
        //Run the code
        Test.startTest();
        Test.testInstall(new STG_InstallScript(), new Version(1,0), true);
        Test.stopTest();

        ////Assert the results
        List<hed__Trigger_Handler__c> triggerHandlers = [SELECT hed__Owned_by_Namespace__c FROM hed__Trigger_Handler__c];
        System.assertEquals(TDTM_DefaultConfig.getDefaultTokens().size(), triggerHandlers.size());

        for (hed__Trigger_Handler__c triggerHandler : triggerHandlers) {
            // Verify Owned by namespace field set on first item in list
            System.assertEquals('k12kit', triggerHandler.hed__Owned_by_Namespace__c, 'Namespace does not match');
        }
	}

}