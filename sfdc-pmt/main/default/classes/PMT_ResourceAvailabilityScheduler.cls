/*******************************************************************************************
* Name: PMT_ResourceAvailabilityScheduler
* Description: It's a scheduler class which queries PMT users and creates resource availability for them
* Test class: PMT_ResourceAvailabilitySchedulerTest (100%)
*******************************************************************************************/
global with sharing class PMT_ResourceAvailabilityScheduler implements Schedulable {
    /*****************************************************************
     * Method Name : execute
     * Params : SchedulableContext 
     * Return : NA
     * Description :  Find out users and Using insertResourceAvailability method creates resource availability for them
     * **************************************************************/
    global void execute(SchedulableContext SC) {        
		Map<Id,Set<String>> mapOfResourceAndFiscalyearList = new Map<Id,Set<String>>();
		
        //Find out all Salesforce profile users present		
		for(User userRec : [SELECT Id FROM User WHERE IsActive=true AND Is_PMT_User_consider_for_Availability__c = true limit :Limits.getLimitQueryRows()]){
			mapOfResourceAndFiscalyearList.put(userRec.Id, new Set<String>());
		}
		
        PMT_CreateResourceAvailability.insertResourceAvailability(JSON.serialize(mapOfResourceAndFiscalyearList));
    }
}