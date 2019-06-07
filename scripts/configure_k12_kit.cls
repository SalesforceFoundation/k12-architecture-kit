//set the configuration for K12 Kit
//once K12 has a managed package, this code should move
public static void initializeK12KitSettings() {
    hed__Hierarchy_Settings__c settings = hed__.UTIL_CustomSettings_API.getSettings();
    settings.hed__Account_Processor__c = settings.hed__Household_Addresses_RecType__c;
    update settings;
}