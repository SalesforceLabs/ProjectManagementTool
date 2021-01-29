/*******************************************************************************************
* Name: PMT_CreateResourceAvailability
* Description: It creates Resource availability for users for future years in advance when scheduler runs.
* Test class: PMT_scheduerResourceAvailabilityTest (86%)
*******************************************************************************************/
public with sharing class PMT_CreateResourceAvailability{
    /*****************************************************************
    * Method Name : insertResourceAvailability
    * Params : String of JSON consist of Map of UserId's and respective fiscal year list 
    * Return : NA
    * Description : Creates resource availability for all mentioned users for next n fiscal years.
    * **************************************************************/
    @future
    public static void insertResourceAvailability(String jsonOfResourceAndFiscalyearList){
        Map<Id,Set<String>> mapOfResourceAndFiscalyearList = (Map<Id,Set<String>>) JSON.deserialize(String.escapeSingleQuotes(jsonOfResourceAndFiscalyearList), Map<Id,Set<String>>.class);
        Set<String> setOfFutureYRAvailabilityRequired;
        List<PMT_Resource_Availability__c> lstOfNewResourceAvailability = new List<PMT_Resource_Availability__c>();
        List<PMT_Error_Log__c> lstOfErrorLogs = new List<PMT_Error_Log__c>();
        List<String> lstOfDummyAvailabilityPresent = new List<String>();
        
        Integer resourceAvailability = 100; //  Default resource availability will be set to 100
        //
        try{ 
            //Find out resource availability should be present
            resourceAvailability = Integer.valueOf(PMT_Utility.getPMTSettings('Default').Default_Availability_for_Scheduler__c);
            setOfFutureYRAvailabilityRequired = getFutureAvailabilityYears(mapOfResourceAndFiscalyearList);
            //Check for each user availability is present as per required for future years
            for(Id userId : mapOfResourceAndFiscalyearList.keySet()){
                for(String fiscalYearRequired : setOfFutureYRAvailabilityRequired){
                    if(!mapOfResourceAndFiscalyearList.get(userId).contains(fiscalYearRequired)){
                        PMT_Resource_Availability__c resARec = new PMT_Resource_Availability__c(Fiscal_Year__c = fiscalYearRequired, User__c = userId,
                                                                                                Jan__c = resourceAvailability, Feb__c = resourceAvailability, 
                                                                                                Mar__c = resourceAvailability, Apr__c = resourceAvailability, 
                                                                                                May__c = resourceAvailability, Jun__c = resourceAvailability, 
                                                                                                Jul__c = resourceAvailability, Aug__c = resourceAvailability, 
                                                                                                Sep__c = resourceAvailability, Oct__c = resourceAvailability,
                                                                                                Nov__c = resourceAvailability, Dec__c = resourceAvailability);
                        lstOfNewResourceAvailability.add(resARec);
                    }
                }
            }
            
            //For each FY create availability without user
            for(PMT_Resource_Availability__c availabilityRec : [SELECT Id,User__c,Fiscal_Year__c FROM PMT_Resource_Availability__c WHERE Fiscal_Year__c IN: setOfFutureYRAvailabilityRequired AND User__c = '' limit :Limits.getLimitQueryRows()]){
                lstOfDummyAvailabilityPresent.add(availabilityRec.Fiscal_Year__c);
            }
            
            for(String fiscalYearRequired : setOfFutureYRAvailabilityRequired){
                if(!lstOfDummyAvailabilityPresent.contains(fiscalYearRequired)){
                    PMT_Resource_Availability__c resARec = new PMT_Resource_Availability__c(Fiscal_Year__c = fiscalYearRequired,
                                                                                            Jan__c = resourceAvailability, Feb__c = resourceAvailability, 
                                                                                            Mar__c = resourceAvailability, Apr__c = resourceAvailability, 
                                                                                            May__c = resourceAvailability, Jun__c = resourceAvailability, 
                                                                                            Jul__c = resourceAvailability, Aug__c = resourceAvailability, 
                                                                                            Sep__c = resourceAvailability, Oct__c = resourceAvailability,
                                                                                            Nov__c = resourceAvailability, Dec__c = resourceAvailability);
                    
                    lstOfNewResourceAvailability.add(resARec);
                }
            }
            
            List<String> lstOfAvailabilityFields = new List<String>{'Fiscal_Year__c', 'Jan__c','Feb__c','Mar__c','Apr__c','May__c','Jun__c','Jul__c','Aug__c','Sep__c','Oct__c','Nov__c','Dec__c'};
            
            if(!lstOfNewResourceAvailability.isEmpty() && PMT_Utility.validateCRUD('PMT_Resource_Availability__c', lstOfAvailabilityFields, 'isCreatable')){				
                Database.SaveResult[] srList = Database.INSERT(lstOfNewResourceAvailability,false);
                for (Database.SaveResult sr : srList) {
                    if (!sr.isSuccess()){ 
                        // Operation failed, so get all errors                
                        for(Database.Error err : sr.getErrors()) {
                            lstOfErrorLogs.add(new PMT_Error_Log__c(Apex_Class__c='PMT_CreateResourceAvailability', Error_Message__c = err.getMessage() + 'and fields that affected this error:' + err.getFields(), Method_Name__c = 'insertResourceAvailability'));
                            
                        }
                    }
                }                
            }
        }catch(Exception e){
            lstOfErrorLogs.add(new PMT_Error_Log__c(Apex_Class__c='PMT_CreateResourceAvailability', Error_Message__c = e.getMessage() , Method_Name__c = 'insertResourceAvailability'));
        }
        
        List<String> lstOfLogFields = new List<String>{'Apex_Class__c', 'Error_Message__c','Method_Name__c'};
            //Calling util method to check CRUD
            if(!lstOfErrorLogs.isEmpty() && PMT_Utility.validateCRUD('PMT_Error_Log__c', lstOfLogFields, 'isCreatable')){
                INSERT lstOfErrorLogs;
            }
    }
    
    /*****************************************************************
    * Method Name : getFutureAvailabilityYears
    * Params : map of resource and fiscal year
    * Return : returns the set of years to setup the availability
    * **************************************************************/
    public static Set<String> getFutureAvailabilityYears(Map<Id,Set<String>> mapOfResourceAndFiscalyearList){
        Set<String> setOfFutureYRAvailabilityRequired = new Set<String>();
        Integer fiscalYearStartMonth =  Integer.valueOf(PMT_Utility.getPMTSettings('Default').Start_Month_of_Fiscal_Year__c);
        Integer futureAvailabilityRequired = Integer.valueOf(PMT_Utility.getPMTSettings('Default').Resource_Planning_Years_in_Advance__c);
        Integer futureYearAvailabilityRequired = Integer.valueOf(PMT_Utility.getPMTSettings('Default').Default_Availability_for_Scheduler__c);
        
        //Find out current financial year running and next years for which need to create availability
        Integer currentRunningMonth = Date.Today().Month();
        Integer currentRunningYear = Date.Today().Year();            
        Integer currentfiscalYear;
        //IF start of the year is January, it should show the same year and not with +1
        if(fiscalYearStartMonth==1 || currentRunningMonth < fiscalYearStartMonth){
            currentfiscalYear = currentRunningYear;
        }else{
            currentfiscalYear = currentRunningYear + 1;
        }
        
        for(Integer i=currentfiscalYear; i<=currentfiscalYear+futureAvailabilityRequired; i++){
            setOfFutureYRAvailabilityRequired.add('FY'+String.valueOf(i).substring(2, 4));
        }
        
        //Find out User wise availability still present **Verify filters
        for(PMT_Resource_Availability__c availabilityRec : [SELECT Id,User__c,Fiscal_Year__c FROM PMT_Resource_Availability__c WHERE Fiscal_Year__c IN: setOfFutureYRAvailabilityRequired AND User__c IN: mapOfResourceAndFiscalyearList.keySet() limit :Limits.getLimitQueryRows()]){ 
            if(mapOfResourceAndFiscalyearList.containsKey(availabilityRec.User__c)){
                Set<String> setOfFiscalYear = mapOfResourceAndFiscalyearList.get(availabilityRec.User__c);
                setOfFiscalYear.add((availabilityRec.Fiscal_Year__c).touppercase());
                mapOfResourceAndFiscalyearList.put(availabilityRec.User__c, setOfFiscalYear);
            }
        }
        return setOfFutureYRAvailabilityRequired;
    }
    
    /*****************************************************************
    * Method Name : createRAOnUserInsert
    * Params : List of UserId's 
    * Return : NA
    * Description : Using insertResourceAvailability method creates resource availability for mentioned users
    * **************************************************************/
    @InvocableMethod(label='Create PMT Resource Availability on User creation')
    public static void createRAOnUserInsert(List<Id> lstOfUserIds){
        Map<Id,Set<String>> mapOfResourceAndFiscalyearList = new Map<Id,Set<String>>();
        
        for(Id userId : lstOfUserIds){
            mapOfResourceAndFiscalyearList.put(userId, new Set<String>());
        }
        
        insertResourceAvailability(JSON.serialize(mapOfResourceAndFiscalyearList));
    }
}