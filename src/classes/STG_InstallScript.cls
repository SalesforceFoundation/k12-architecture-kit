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
* @description Installs Script for the K12 Kit package.
*/
global without sharing class STG_InstallScript implements InstallHandler {

    /*******************************************************************************************************
    * @description Runs on package install.
    * @param context The install context.
    * @return void
    */
    global void onInstall(InstallContext context) {

            //Initial installation.
            if(context.previousVersion() == null) {
                insertMappings();
            
            //Updates, manual or pushed by publisher.
            } else if(context.isUpgrade() || context.isPush()) {

            }
    }

    /*******************************************************************************************************
    * @description Inserts the default Affiliation Mappings.
    * @return void
    */
    global static void insertMappings() {
        List<hed__Affl_Mappings__c> mappings = new List<hed__Affl_Mappings__c>();
        mappings.add(new hed__Affl_Mappings__c(Name = 'Grade Level', hed__Account_Record_Type__c = 'Grade Level', hed__Primary_Affl_Field__c = 'Current Grade Level'));
        insert mappings;
    }
}