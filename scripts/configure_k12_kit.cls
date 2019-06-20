//set the configuration for K12 Kit
//once K12 has a managed package, this code should move
public static void initializeK12KitSettings() {
    hed__Hierarchy_Settings__c settings = hed.UTIL_CustomSettings_API.getSettings();
    settings.hed__Account_Processor__c = settings.hed__Household_Addresses_RecType__c;
    update settings;
}

//enables course connections (should be called by trail org flows only from cci)
//and sets the record types for Student and Faculty
public static void enableCourseConnections() {
    hed__Hierarchy_Settings__c settings = hed.UTIL_CustomSettings_API.getSettings();
    settings.hed__Enable_Course_Connections__c = true;
    List<RecordType> courseConnectionRecordTypes = [SELECT Id, DeveloperName, SObjectType
                                            FROM RecordType
                                            WHERE (DeveloperName = 'Faculty'
                                            OR DeveloperName = 'Student') 
                                            AND SObjectType = 'hed__Course_Enrollment__c'];

    if(!courseConnectionRecordTypes.isEmpty()) {
        
        for(RecordType rt : courseConnectionRecordTypes) {
            if(rt.DeveloperName == 'Faculty') {
                settings.hed__Faculty_RecType__c = rt.Id;
            } else if(rt.DeveloperName == 'Student') {
                settings.hed__Student_RecType__c = rt.Id;
            }
        }

        update settings;
    }
    
}