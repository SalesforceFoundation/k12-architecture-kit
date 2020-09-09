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
* @description Utilities class for default trigger handlers
**/
public without sharing class TDTM_DefaultConfig {
    public static List<hed.TDTM_Global_API.TdtmToken> getDefaultTokens() {
        List<hed.TDTM_Global_API.TdtmToken> tokens = new List<hed.TDTM_Global_API.TdtmToken>();

        for (hed__Trigger_Handler__c handler : TDTM_DefaultConfig.getDefaultHandlers()) {
            tokens.add(new hed.TDTM_Global_API.TdtmToken(
                        handler.hed__Class__c,
                        handler.hed__Object__c,
                        handler.hed__Trigger_Action__c,
                        handler.hed__Load_Order__c,
                        handler.hed__Active__c,
                        handler.hed__Asynchronous__c,
                        handler.hed__Filter_Field__c,
                        handler.hed__Filter_Value__c,
                        handler.hed__User_Managed__c,
                        handler.hed__Owned_by_Namespace__c,
                        handler.hed__Usernames_to_Exclude__c));
        }
        return tokens;
    }

    private static List<hed__Trigger_Handler__c> getDefaultHandlers() {
        List<hed__Trigger_Handler__c> handlers = new List<hed__Trigger_Handler__c>();

        // Events: Prevent Update of events associated with custom appointment object
        handlers.add(new hed__Trigger_Handler__c(
                        hed__Active__c = true,
                        hed__Asynchronous__c = false,
                        hed__Class__c = GRER_SyncGradeLevel_TDTM.class.toString(),
                        hed__Load_Order__c = 1,
                        hed__Object__c = Grade_Enrollment__c.SObjectType.getDescribe().getName(),
                        hed__Owned_by_Namespace__c = 'k12kit',
                        hed__Trigger_Action__c = 'AfterInsert;AfterUpdate;AfterDelete'));

        handlers.add(new hed__Trigger_Handler__c(
                        hed__Active__c = true,
                        hed__Asynchronous__c = false,
                        hed__Class__c = CON_CurrentGradeLevel_TDTM.class.toString(),
                        hed__Load_Order__c = 1,
                        hed__Object__c = Contact.SObjectType.getDescribe().getName(),
                        hed__Owned_by_Namespace__c = 'k12kit',
                        hed__Trigger_Action__c = 'AfterInsert;AfterUpdate')); 
                        
        handlers.add(new hed__Trigger_Handler__c(
                        hed__Active__c = true,
                        hed__Asynchronous__c = false,
                        hed__Class__c = EDUHIS_DataInteg_TDTM.class.toString(),
                        hed__Load_Order__c = 1,
                        hed__Object__c = hed__Education_History__c.SObjectType.getDescribe().getName(),
                        hed__Owned_by_Namespace__c = 'k12kit',
                        hed__Trigger_Action__c = 'BeforeInsert;BeforeUpdate'));

        return handlers;
    }
}