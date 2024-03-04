/*******************************************************************************************
* Name: PMT_CreateResourceAvailability2
* Description: This class can be called from a flow and create resource availability.
* Test class: PMT_ResourceAvailabilitySchedulerTest (84%)
*******************************************************************************************/
global with sharing class PMT_CreateResourceAvailability2{
    
    global class FlowInputs {
        @InvocableVariable
        global List<User> lstUser;
    }
    
    /*****************************************************************
    * Method Name : createRAOnUserInsert
    * Params : List of users
    * Return : NA
    * Description : Using PMT_CreateResourceAvailability.insertResourceAvailability method creates resource availability for mentioned users
    * **************************************************************/
    @InvocableMethod(label='Create PMT Resource Availability on User creation')
    global static void createRAOnUserInsert(List<FlowInputs> listFlowInputs){
        PMT_CreateResourceAvailability2.FlowInputs listInputs = new PMT_CreateResourceAvailability2.FlowInputs();
        Map<Id,Set<String>> mapOfResourceAndFiscalyearList = new Map<Id,Set<String>>();
        

        for (PMT_CreateResourceAvailability2.FlowInputs objInputs: listFlowInputs) {
            listInputs.lstUser = objInputs.lstUser;
        }


        for(User objUser : listInputs.lstUser){
            mapOfResourceAndFiscalyearList.put(objUser.Id, new Set<String>());
        }
        
        PMT_CreateResourceAvailability.insertResourceAvailability(JSON.serialize(mapOfResourceAndFiscalyearList));
    }
}