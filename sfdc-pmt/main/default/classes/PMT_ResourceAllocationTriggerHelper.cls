/******************************************************************************
@ ClassName : PMT_ResourceAllocationTriggerHelper
@ Description : Its a helper class for PMT_ResourceAllocationTrigger. It contains methods to revoke and give access to PMT project for resources
@ Test Class : PMT_ResourceAllocationTriggerTest (90%)
* ***************************************************************************/
public with sharing class PMT_ResourceAllocationTriggerHelper{
    
    /**********************************************************************************************
* Method Name: restrictDeletionIfTaskIsAssigned
* Params : List of Resource Allocation
* @description : check if task is assigned or not before deletion
* Returns : void
* **********************************************************************************************/
    public static void restrictDeletionIfTaskIsAssigned(List<PMT_Resource_Allocation__c> recs)
    {
        List<ID>userid=new list<id>();
        List<ID>projectid=new list<id>();
        try {
            for(PMT_Resource_Allocation__c rec : recs)
            {
                userid.add(rec.Allocated_Resource_Id__c);
                projectid.add(rec.Project__c);
            }
            //Calling util method to check CRUD
            List<String> lstOfTaskFields = new List<String>{'Assigned_To1__c', 'Name','Id', 'Project_Id__c'};
                if(PMT_Utility.validateCRUD('PMT_Task__c', lstOfTaskFields, 'isAccessible')){
                    List<PMT_Task__c> tasklist=[SELECT id,name,Assigned_To1__c,Phase__r.Project__c FROM PMT_Task__c WHERE Assigned_To1__c IN :userid AND Project_Id__c IN :projectid limit :Limits.getLimitQueries()];
                    for(PMT_Resource_Allocation__c rec : recs)
                    {
                        for(PMT_Task__c taskRec : tasklist)
                        {
                            if(!String.isEmpty(rec.Allocated_Resource_Id__c) && rec.Allocated_Resource_Id__c == taskRec.Assigned_To1__c && rec.Project__c == taskRec.Phase__r.Project__c){
                                rec.addError('Resource can not be deleted, as resource is assigned to a task');
                            }               
                        }
                    }
                }
        } catch(Exception e) {
            System.debug('Error in checkiftaskassigned: '+e.getMessage());
            throw new AuraHandledException('Record can not be deleted. As it is assigned to task');
        }
    }
    
    /**********************************************************************************************
* Method Name: updateSharingOnResourceChange
* Params : Map of old and new Resource allocations
* @description : Revoke access for resources who get removed and give access to who gets added as new
* Returns : void
* **********************************************************************************************/
    public static void updateSharingOnResourceChange(Map<Id, PMT_Resource_Allocation__c> mapOfOldRecs, Map<Id, PMT_Resource_Allocation__c> mapOfNewRecs)
    {
        List<PMT_Resource_Allocation__c> lstOfResourcesToRemoveAccess = new List<PMT_Resource_Allocation__c>();
        List<PMT_Resource_Allocation__c> lstOfResourcesToGiveAccess = new List<PMT_Resource_Allocation__c>();
        
        for(PMT_Resource_Allocation__c allocRec : mapOfNewRecs.values()){
            if(mapOfOldRecs.get(allocRec.Id).Resource_Availability__c != allocRec.Resource_Availability__c){
                lstOfResourcesToRemoveAccess.add(mapOfOldRecs.get(allocRec.Id));
                lstOfResourcesToGiveAccess.add(allocRec);
            }
        }
        
        if(!lstOfResourcesToRemoveAccess.isEmpty()){
            revokeProjectAccess(lstOfResourcesToRemoveAccess);
        }
        
        if(!lstOfResourcesToGiveAccess.isEmpty()){
            shareProjectWithEditAccess(lstOfResourcesToGiveAccess);
        }
    }
    
    /***********************************************************************************************
* Method Name:revokeProjectAccess
* Params : List of resource allocations
* @description : Revoke project access from old resources
* Returns : void
* *********************************************************************************************/
    public static void revokeProjectAccess(List<PMT_Resource_Allocation__c> lstOfResourcesToRemoveAccess){
        Map<Id,Id> mapOfResAllAndResAvail = new Map<Id,Id>();
        Map<Id,Id> mapOfResAllAndProject = new Map<Id,Id>();
        Map<Id,Id> mapOfResourceAvailAndUser = new Map<Id,Id>();
        List<PMT_Project__Share> lstOfShareRecToBeDeleted = new List<PMT_Project__Share>();
        List<PMT_Error_Log__c> lstOfErrorLogs = new List<PMT_Error_Log__c>();
        try {
            for(PMT_Resource_Allocation__c allocationRec : lstOfResourcesToRemoveAccess){
                mapOfResAllAndResAvail.put(allocationRec.Id, String.escapeSingleQuotes(allocationRec.Resource_Availability__c));
                mapOfResAllAndProject.put(allocationRec.Id, String.escapeSingleQuotes(allocationRec.Project__c));
            }
            
            for(PMT_Resource_Availability__c availabilityRec : [SELECT Id, User__c FROM PMT_Resource_Availability__c WHERE Id IN: mapOfResAllAndResAvail.values() limit :Limits.getLimitQueries()]){
                mapOfResourceAvailAndUser.put(availabilityRec.Id, availabilityRec.User__c);
            }
            
            for(PMT_Project__Share shareRec : [Select ParentId, UserOrGroupId from PMT_Project__Share where ParentId IN: mapOfResAllAndProject.values() and UserOrGroupId IN: mapOfResourceAvailAndUser.values() limit :Limits.getLimitQueries()]){
                for(PMT_Resource_Allocation__c allocationRec : lstOfResourcesToRemoveAccess){
                    if(allocationRec.Project__c == shareRec.ParentId && mapOfResourceAvailAndUser.get(mapOfResAllAndResAvail.get(allocationRec.Id)) == shareRec.UserOrGroupId){
                        lstOfShareRecToBeDeleted.add(shareRec);
                    }
                }
            }
            if(!lstOfShareRecToBeDeleted.isEmpty()){
                Database.DeleteResult[] srList = Database.Delete(lstOfShareRecToBeDeleted, false);
                for (Database.DeleteResult dr : srList) {
                    if (!dr.isSuccess()){ 
                        // Operation failed, so get all errors                
                        for(Database.Error err : dr.getErrors()) {
                            lstOfErrorLogs.add(new PMT_Error_Log__c(Apex_Class__c='PMT_ResourceAllocationTriggerHelper', Error_Message__c = err.getMessage() + 'and fields that affected this error:' + err.getFields(), Method_Name__c = 'revokeProjectAccess'));
                        }
                    }
                }
            }
        } catch(Exception e) {
            lstOfErrorLogs.add(new PMT_Error_Log__c(Apex_Class__c='PMT_ResourceAllocationTriggerHelper', Error_Message__c = e.getMessage() , Method_Name__c = 'revokeProjectAccess'));
        }
        
        if(!lstOfErrorLogs.isEmpty()){
            //Calling util method to check CRUD
            List<String> lstOfLogFields = new List<String>{'Apex_Class__c', 'Error_Message__c','Method_Name__c'};
                if(PMT_Utility.validateCRUD('PMT_Error_Log__c', lstOfLogFields, 'isCreatable')){
                    INSERT lstOfErrorLogs;
                }
        }			
    }
    
    /**********************************************************************************************
* Method Name:shareProjectWithEditAccess
* Params : List of resource allocations
* @description : Share project with new resources
* Returns : void
* *********************************************************************************************/
    public static void shareProjectWithEditAccess(List<PMT_Resource_Allocation__c> lstOfResourcesToRemoveAccess){
        Map<Id,Id> mapOfResAllAndResAvail = new Map<Id,Id>();
        Map<Id,Id> mapOfResourceAvailAndUser = new Map<Id,Id>();
        List<PMT_Error_Log__c> lstOfErrorLogs = new List<PMT_Error_Log__c>();
        try {
            List<PMT_Project__Share> lsToInsert = new List<PMT_Project__Share>();
            
            for(PMT_Resource_Allocation__c allocationRec : lstOfResourcesToRemoveAccess){
                mapOfResAllAndResAvail.put(allocationRec.Id, allocationRec.Resource_Availability__c);
            }
            
            for(PMT_Resource_Availability__c availabilityRec : [SELECT Id, User__c FROM PMT_Resource_Availability__c WHERE Id IN: mapOfResAllAndResAvail.values() limit :Limits.getLimitQueries()]){
                mapOfResourceAvailAndUser.put(availabilityRec.Id, availabilityRec.User__c);
            }
            
            for(PMT_Resource_Allocation__c allocationRec : lstOfResourcesToRemoveAccess){
                PMT_Project__Share projShareObj = new PMT_Project__Share();
                projShareObj.ParentId = allocationRec.Project__c;
                projShareObj.UserOrGroupId = mapOfResourceAvailAndUser.get(mapOfResAllAndResAvail.get(allocationRec.Id));				
                projShareObj.AccessLevel = 'Edit';
                projShareObj.RowCause = Schema.PMT_Project__Share.RowCause.Project_Member__c;
                lsToInsert.add(projShareObj);
            }
            
            if(!lsToInsert.isEmpty()){
                Database.SaveResult[] srList = Database.INSERT(lsToInsert, false);
                for (Database.SaveResult dr : srList) {
                    if (!dr.isSuccess()){ 
                        // Operation failed, so get all errors                
                        for(Database.Error err : dr.getErrors()) {
                            lstOfErrorLogs.add(new PMT_Error_Log__c(Apex_Class__c='PMT_ResourceAllocationTriggerHelper', Error_Message__c = err.getMessage() + 'and fields that affected this error:' + err.getFields(), Method_Name__c = 'shareProjectWithEditAccess'));
                        }
                    }
                }
            }
        } catch(Exception e) {
            lstOfErrorLogs.add(new PMT_Error_Log__c(Apex_Class__c='PMT_ResourceAllocationTriggerHelper', Error_Message__c = e.getMessage() , Method_Name__c = 'shareProjectWithEditAccess'));
        }
        
        if(!lstOfErrorLogs.isEmpty()){
            //Calling util method to check CRUD
            List<String> lstOfLogFields = new List<String>{'Apex_Class__c', 'Error_Message__c','Method_Name__c'};
                if(PMT_Utility.validateCRUD('PMT_Error_Log__c', lstOfLogFields, 'isCreatable')){
                    INSERT lstOfErrorLogs;
                }
        }			
    }
}