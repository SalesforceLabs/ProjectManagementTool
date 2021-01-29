/******************************************************************************
 @ Trigger Name : PMT_ResourceAllocationTrigger
 @ Description : Trigger to revoke and give access to PMT project for resources
 @ Test Class : PMT_ResourceAllocationTriggerTest (84%)	
 * ***************************************************************************/
 
trigger PMT_ResourceAllocationTrigger on PMT_Resource_Allocation__c (after insert, before delete, after update) {
  //NOTE : Exceptional logic added to deactivate the trigger
  //Logic to block trigger if required using custom label
    Boolean isActive;
    try{
      isActive = PMT_Utility.getPMTSettings('Default').Allocation_Trigger_Status__c;
    }
    catch(Exception e){
        isActive = true;
    }
    
    //If the setting is active, run the trigger logic
    if(isActive){
        if(trigger.isbefore && trigger.isdelete)
        {
            //restrict Deletion If Task Is Assigned to resource
                PMT_ResourceAllocationTriggerHelper.restrictDeletionIfTaskIsAssigned(trigger.old);
            //Share project with project members
                PMT_ResourceAllocationTriggerHelper.revokeProjectAccess(trigger.old);            
        }
        if(trigger.isafter && trigger.isInsert)
        {
            //Share project with project members
                PMT_ResourceAllocationTriggerHelper.shareProjectWithEditAccess(trigger.new);        
        }
        
        if(trigger.isafter && trigger.isUpdate) 
        {
            //If project members get changed update sharing for them 
                PMT_ResourceAllocationTriggerHelper.updateSharingOnResourceChange(trigger.oldMap, trigger.newMap);        
        }
    }
}