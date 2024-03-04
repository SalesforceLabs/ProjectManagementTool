/******************************************************************************
* Name: PMT_ProjectSummaryCtrl.apxc
* Used by: Used by PMT_ProjectSummaryPhaseTable.cmp
* Description : It contains methods to find out phases, tasks, milestones related to PMT project
* Test class : PMT_Testcoverage(85%)
******************************************************************************/

public with sharing class PMT_ProjectSummaryCtrl {

    /*************************************************
    * Name: createSummaryWrapper
    * Description: Create wrapper for lists
    * ***********************************************/
  
    public class CreateSummaryWrapper
    {
        @AuraEnabled public List<PMT_Phase__c> phasesList;
        @AuraEnabled public List<PMT_Task__c> lateTaskList;
        @AuraEnabled public List<PMT_Task__c> onGoingTaskList;
        @AuraEnabled public List<PMT_Task__c> milestoneTaskList;
        @AuraEnabled public integer fiscalMonthOffset;
    }
    
    /************************************************
    * Method Name: getSummaryWrapper 
    * Description: Wrapper for getPhasesForProject and getTasksForProject methods
    * Parameters : recordId
    * Return Values: list of Tasks and list of phases
    * ***********************************************/    
    @AuraEnabled
    public static CreateSummaryWrapper getSummaryWrapper(Id recordId)
    {
		CreateSummaryWrapper summaryWrapper = new CreateSummaryWrapper();
        //Calling util method to check CRUD
		List<String> lstOfPhaseFields = new List<String>{'Name', 'Health_Icon__c', 'Phase_Completion__c', 'Phase_Completion_Image__c', 'Project__c','Kickoff_formula__c'};
		if (PMT_Utility.validateCRUD('PMT_Phase__c', lstOfPhaseFields, 'isAccessible') ){ 
			summaryWrapper.phasesList = getPhasesForProject(recordId);
		}else{
			throw new AuraHandledException('You don\'t have access to PMT Phases. Please contact system administrator.');
		}
		
        //Calling util method to check CRUD
		List<String> lstOfTaskFields = new List<String>{'Name', 'Status_Icon__c', 'Start_Date__c', 'Due_Date__c', 'Is_Milestone__c', 'Phase__c', 'Days_Late__c', 'Project_Id__c'};
		if (PMT_Utility.validateCRUD('PMT_Task__c', lstOfTaskFields, 'isAccessible') ){ 
			summaryWrapper.lateTaskList = getLateTasksForProject(recordId);
			
			summaryWrapper.onGoingTaskList = getOnGoingTasksForProject(recordId);
			
			summaryWrapper.milestoneTaskList = getMilestoneTasksForProject(recordId);
		}else{
			throw new AuraHandledException('You don\'t have access to PMT Task. Please contact system administrator.');
		}		
		
        //Get PMT Settings
        summaryWrapper.fiscalMonthOffset = Integer.valueOf(PMT_Utility.getPMTSettings('Default').Start_Month_of_Fiscal_Year__c);
		return summaryWrapper;      
    }
    
    /*************************************************
    * Method Name: getPhasesForProject
    * Description: Get list of Phases for a project
    * Parameters : recordId
    * Return Values: list of phases
    * ***********************************************/  
    private static List<PMT_Phase__c> getPhasesForProject(Id recordId)
    {
		return [SELECT id,Name,Health_Icon__c,Phase_Completion__c, Phase_Completion_Image__c,Kickoff_formula__c FROM PMT_Phase__c 
                WHERE Project__c=:recordId ORDER BY Kickoff_formula__c ASC limit: limits.getLimitQueryRows()];                    
	}

    /*************************************************
    * Method Name: getLateTasksForProject
    * Description: Get list of Tasks for a project
    * Parameters : recordId
    * Return Values: list of late tasks
    * ***********************************************/  
    private static List<PMT_Task__c> getLateTasksForProject(Id recordId)
    {
		return [SELECT id,Name,Status_Icon__c,Start_Date__c,Due_Date__c,Is_Milestone__c,Phase__c,Days_Late__c FROM PMT_Task__c 
				WHERE Project_Id__c=:recordId AND Days_Late__C > 0 order by Due_Date__c ASC, Name ASC limit: limits.getLimitQueryRows()];
    }

    /*************************************************
    * Method Name: getOnGoingTasksForProject
    * Description: Get list of OnGoing Tasks set for a project
    * Parameters : recordId
    * Return Values: list of ongoing tasks (not Late)
    * ***********************************************/  
    private static List<PMT_Task__c> getOnGoingTasksForProject(Id recordId)
    {
		return [SELECT id,Name,Status_Icon__c,Start_Date__c,Due_Date__c,Is_Milestone__c,Phase__c,Phase__r.Name,    Days_Late__c FROM PMT_Task__c 
				WHERE Project_Id__c=:recordId AND Days_Late__C <= 0 order by Due_Date__c ASC, Name ASC limit: limits.getLimitQueryRows()];					      
    }

    /*************************************************
    * Method Name: getMilestoneTasksForProject
    * Description: Get list of Milestone Tasks set for a project
    * Parameters : recordId
    * Return Values: list of Milestone tasks
    * ***********************************************/  
    private static List<PMT_Task__c> getMilestoneTasksForProject(Id recordId)
    {
		return [SELECT id,Name,Status_Icon__c,Due_Date__c FROM PMT_Task__c 
				WHERE Project_Id__c=:recordId AND Is_Milestone__c=true order by Due_Date__c ASC, Name ASC limit: limits.getLimitQueryRows()];					
		 
    }
    
}