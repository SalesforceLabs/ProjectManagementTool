/*****************************************************************************************
* Name: PMT_Utility
* Referenced components: 
- PMT_CaseDataTable.cmp
* Test class : PMT_Testcoverage (96%)
******************************************************************************************/
public with sharing class PMT_Utility {
    /*****************************************************************************************
* Method Name: getCasesForProject
* Description: Get list of Cases for a project for the Case Datatable on Project Summary page. Used in PMT_CaseDataTable component
* Parameters : Project recordId
* Return Values: list of cases
* *****************************************************************************************/  
    @AuraEnabled
    public static List<Case> getCasesForProject(Id recordId){    
        List<case> cases = new List<case>();
        //Calling util method to check CRUD
        List<String> lstOfCaseFields = new List<String>{'CaseNumber', 'Subject', 'PMT_Days_Open__c', 'Description', 'Type', 'Status', 'Priority', 'PMT_Project__c'};        
        boolean hasAccess = validateCRUD('Case', lstOfCaseFields, 'isAccessible');
        
        if(hasAccess){  
            cases = [SELECT id,CaseNumber,Subject,PMT_Days_Open__c,Description,Type,Status,Priority,PMT_Project__c FROM Case 
                     WHERE PMT_Project__c =:recordId AND RecordType.DeveloperName =: System.Label.PMT_Project_Record_Type_on_Case ORDER BY Priority ASC, Type ASC limit: limits.getLimitQueryRows()];                                     
            return cases;
            
        }else{
            throw new AuraHandledException('You don\'t have access to related Cases. Please contact system administrator.');
        } 
    }
    
    /*****************************************************************************************
    * Method Name: validateCRUD
    * Description: Generic method to check CRUD access on object and fields
    * Parameters : sObject API name, list of fields, type of access to check
    * Return Values: boolean
    * *****************************************************************************************/  
    public static boolean validateCRUD(String sObjectName, List<String> lstOfFieldAPIs, String accessCheck){    
        
        Schema.DescribeSobjectResult[] result = Schema.describeSObjects(new String[]{sObjectName});
        
        Map<String, Schema.SObjectField> fieldMap = result[0].fields.getMap();
        
        if(lstOfFieldAPIs == null ){ // Check object level access
            if( (accessCheck.equalsIgnoreCase('isDeletable') && result[0].isDeletable()) ||
               (accessCheck.equalsIgnoreCase('isUpdateable') && result[0].isUpdateable()) ||
               (accessCheck.equalsIgnoreCase('isCreateable') && result[0].isCreateable()) ||
               (accessCheck.equalsIgnoreCase('isAccessible') && result[0].isAccessible())) {
                   return true;
               }else{
                   return false;
               }
        } else if(lstOfFieldAPIs != null){// Check field level access 
            for (String field : lstOfFieldAPIs) {
                if (accessCheck.equalsIgnoreCase('isAccessible') && !fieldMap.get(field).getDescribe().isAccessible()) {
                    return false;
                }else if (accessCheck.equalsIgnoreCase('isUpdateable') && !fieldMap.get(field).getDescribe().isUpdateable()) {
                    return false;
                }else if (accessCheck.equalsIgnoreCase('isCreateable') && !fieldMap.get(field).getDescribe().isCreateable()) {
                    return false;
                }
            }
            return true;
        }else{
            return false;
        }        
    }
    
    /*****************************************************************************************
    * Method Name: getPMTSettings
    * Description: Get settings stored in mdt
    * Parameters : settingName
    * Return Values: PMT_Setting__mdt
    * *****************************************************************************************/    
    public static PMT_Setting__mdt getPMTSettings(String settingName){
        PMT_Setting__mdt settings;
        try{
            settings = [select id, MasterLabel, DeveloperName, Allocation_Trigger_Status__c, Default_Availability_for_Scheduler__c, Resource_Planning_Years_in_Advance__c, Start_Month_of_Fiscal_Year__c from PMT_Setting__mdt where DeveloperName=:settingName with security_enforced limit 1];
        }
        catch(Exception e){
            //If settings not found, create record to return
            settings = new PMT_Setting__mdt();
            settings.MasterLabel='Default';
            settings.DeveloperName='Default';
            settings.Allocation_Trigger_Status__c = false;
            settings.Default_Availability_for_Scheduler__c = 100;
            settings.Resource_Planning_Years_in_Advance__c = 2;
            settings.Start_Month_of_Fiscal_Year__c = 2;
            
            List<String> lstOfLogFields = new List<String>{'Apex_Class__c', 'Error_Message__c','Method_Name__c'};
                if(PMT_Utility.validateCRUD('PMT_Error_Log__c', lstOfLogFields, 'isCreatable')){
                    INSERT new PMT_Error_Log__c(Apex_Class__c='PMT_Utility', Error_Message__c = e.getMessage() , Method_Name__c = 'getPMTSettings');
                }
        }
        return settings;
    }
}