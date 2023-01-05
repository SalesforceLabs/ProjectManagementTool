/************************************************************************************************************
* Name: PMT_ClonePhaseTaskCtrl
* Description: Apex class for PMT Templates functionality which is invoked from "PMT Project Template" Flow
* Test class: PMT_ClonePhaseTaskCtrlTest(89%)
************************************************************************************************************/

global with sharing class PMT_ClonePhaseTaskCtrl {
    public class FlowInputs {
        @InvocableVariable
        public List<PMT_Phase__c> phases;
        
        @InvocableVariable
        public List<PMT_Task__c> tasks;
        
        @InvocableVariable
        public Id projectId;
        
        @InvocableVariable
        public Boolean phaseCheck;
        
        @InvocableVariable
        public String projectName;
        
        @InvocableVariable
        public Date projectStartDate;
    }
    
    public class FlowOutputs {
        @InvocableVariable
        public List<PMT_Task__c> outputTasks;
    }
    
    /**********************************************************************************************************************
    * Method Name : getTasks
    * Params : Accepts a wrapper to conditionally execute necessary functionality based on boolean values set from flow.
    * Return : NA
    * Description : Mutli usage method which gets "PMT Phases" OR "PMT Tasks" & clone the same based on user selection.
    * ********************************************************************************************************************/
    
    @InvocableMethod
    public static List<FlowOutputs> getTasks(List<FlowInputs> request) {
        
        List<Id> lstPhaseIds = new List<Id>();
        List<Id> lstTaskIds = new List<Id>();
        List<PMT_Project__c> lstClonedProjects = new List<PMT_Project__c> ();
        List<PMT_Error_Log__c> lstOfErrorLogs = new List<PMT_Error_Log__c> ();
        PMT_ClonePhaseTaskCtrl.FlowInputs phtask = new PMT_ClonePhaseTaskCtrl.FlowInputs();
        PMT_ClonePhaseTaskCtrl.FlowOutputs flowOut = new PMT_ClonePhaseTaskCtrl.FlowOutputs();
        
        List<FlowOutputs> lstFlowOut = new List<FlowOutputs> ();
        
        for (PMT_ClonePhaseTaskCtrl.FlowInputs req: request) {
            phtask.projectName = req.projectName;
            phtask.projectStartDate = req.projectStartDate;
            phtask.phases = req.phases;
            phtask.tasks = req.tasks;
            phtask.phaseCheck = req.phaseCheck;
            phtask.projectId = req.projectId;
        }
        
        //Get tasks for selected phases
        if (phtask.phases != null && phtask.phases.size() > 0 && phtask.phaseCheck == true) {
            
            List<Id> phaseIds = new List<Id> ();
            List<List<PMT_Task__c>> lstTasks = new List<List<PMT_Task__c>> ();
            
            for (PMT_Phase__c phase: phtask.phases) {
                phaseIds.add(phase.Id);
            }
            
            List<PMT_Task__c> tasks = [select Id, Name, Status__c, Description__c, Start_Days_Out__c, Duration_In_Days__c, Phase__c, Phase_Name__c, Start_Date__c, Due_Date__c, Percentage_Completion__c, CreatedDate from PMT_Task__c where Phase__c IN: phaseIds WITH SECURITY_ENFORCED ORDER BY Name limit:limits.getLimitQueryRows()];
            
            try {
                if (tasks.size() > 0) {
                    flowOut.outputTasks = tasks;
                    lstFlowOut.add(flowOut);
                }
            } catch (Exception ex) {
                if (Schema.sObjectType.PMT_Error_Log__c.isCreateable()) {
                    INSERT new PMT_Error_Log__c(Apex_Class__c = 'PMT_ClonePhaseTaskCtrl', Error_Message__c = ex.getMessage(), Method_Name__c = 'getTasks');
                }
            }
            return lstFlowOut;
        }
        
        //Clone project from project template
        if (phtask.phases != null && phtask.phases.size() > 0 && phtask.phaseCheck == false) {
            
            if(phtask.projectName!=null && phtask.projectStartDate!=null){
                PMT_Project__c proRecord = [Select id, Kickoff_formula__c, Deadline_formula__c, Level_of_Effort__c, Portfolio__c, Initial_Start_Date__c, 
                                            Initial_End_Date__c, Sponsor__c, Description__c, SOX_Impact__c, SOX_Comment__c, Release_Changes__c, Path_to_Green__c, SystemsImpacted__c, 
                                            Roadmap_Status__c, Project_Status__c, Project_Initiator__c, Project_Health__c, Project_Category__c, Processes_Impacted__c, Issues_Risk__c,
                                            In_Scope__c, Goal_Statement__c, Business_Case__c, Assumptions__c, Problem_Statement__c, Out_of_Scope__c, Health_Comment__c, Release_Date__c, Go_Live_Date__c from PMT_Project__c where id =: phtask.projectId WITH SECURITY_ENFORCED limit:limits.getLimitQueryRows()];
                
                PMT_Project__c projectClone = proRecord.clone(false,false,false,false); 
                projectClone.Name = phtask.projectName;
                lstClonedProjects.add(projectClone);
                
                if (lstClonedProjects.size() > 0) {
                    try {
                        Database.SaveResult[] srList = Database.INSERT(lstClonedProjects, false);
                        for (Database.SaveResult sr: srList) {
                            if (!sr.isSuccess()) {
                                // Operation failed, so get all errors                
                                for (Database.Error err: sr.getErrors()) {
                                    lstOfErrorLogs.add(new PMT_Error_Log__c(Apex_Class__c = 'PMT_ClonePhaseTaskCtrl', Error_Message__c = err.getMessage() + 'and fields that affected this error:' + err.getFields(), Method_Name__c = 'getTasks'));
                                }
                            }else{
                                phtask.projectId = lstClonedProjects[0].Id;
                            }
                        }
                    } catch (Exception ex) {
                        lstOfErrorLogs.add(new PMT_Error_Log__c(Apex_Class__c = 'PMT_ClonePhaseTaskCtrl', Error_Message__c = ex.getMessage(), Method_Name__c = 'getTasks'));
                    }
                    
                    //Calling util method to check CRUD
                    if (!lstOfErrorLogs.isEmpty() && Schema.sObjectType.PMT_Error_Log__c.isCreateable()) {
                        INSERT lstOfErrorLogs;
                    }
                }
            }
            
            for (PMT_Phase__c phase: phtask.phases) {
                lstPhaseIds.add(phase.Id);
            }
        }
        
        //Clone selected tasks & map them to newly created phases
        if (phtask.tasks != null && phtask.tasks.size() > 0 && phtask.phaseCheck == false) {
            for (PMT_Task__c task: phtask.tasks) {
                lstTaskIds.add(task.Id);
            }       
        }
        
        if(lstPhaseIds.size()>0 || lstTaskIds.size()>0){
            createPhasesTasks(lstPhaseIds, lstTaskIds, phtask.projectId, phtask.projectStartDate);
        }
        return new List<FlowOutputs> ();
    }
    
    
    /********************************************************************************************************************
    * Method Name : createPhasesTasks
    * Params : Accepts list of selected Phases/Task Ids & ProjectId
    * Return : NA
    * Description : Method to clone Phases/Tasks based on the user selection from flow UI.
    * ******************************************************************************************************************/
    @future
    public static void createPhasesTasks(List<Id> lstPhases, List<Id> lstTasks, Id projectId, Date projectStartDate) {
        List<PMT_Phase__c> lstClonedPhases = new List<PMT_Phase__c> ();
        List<PMT_Task__c> lstClonedTasks = new List<PMT_Task__c> ();
        List<PMT_Error_Log__c> lstOfErrorLogs = new List<PMT_Error_Log__c> ();
        List<String> holidaysSet = new List<String>();
        List<PMT_Setting__mdt> setting = [Select id, Holidays__c from PMT_Setting__mdt where DeveloperName='Default' limit 1];
        
        if(setting.size()>0 && setting[0].Holidays__c!=null){
            String sDays = setting[0].Holidays__c;
            
            if(sDays.contains(';')){
                holidaysSet = sDays.split(';');
            }else {
                holidaysSet.add(sDays);
            }
        } 
        
        //Cloning the selected Phase records
        if(lstPhases.size()>0){
            List<PMT_Phase__c> lstSelectedPhases = [Select Id, Name, Project__c, Phase_Health__c, Sum_of_tasks_count_child__c, Phase_Description__c, Start_date_from_child_project__c, End_date_from_child__c from PMT_Phase__c where Id IN: lstPhases WITH SECURITY_ENFORCED limit:limits.getLimitQueryRows()];
            
            for (PMT_Phase__c phase: lstSelectedPhases) {
                PMT_Phase__c phaseClone = phase.clone(false, false, false, false);
                phaseClone.Project__c = projectId;
                phaseClone.Phase_Health__c = 'Not Started';
                lstClonedPhases.add(phaseClone);
            }
            if (lstClonedPhases.size() > 0) {
                try {
                    Database.SaveResult[] srList = Database.INSERT(lstClonedPhases, false);
                    for (Database.SaveResult sr: srList) {
                        if (!sr.isSuccess()) {
                            // Operation failed, so get all errors                
                            for (Database.Error err: sr.getErrors()) {
                                lstOfErrorLogs.add(new PMT_Error_Log__c(Apex_Class__c = 'PMT_ClonePhaseTaskCtrl', Error_Message__c = err.getMessage() + 'and fields that affected this error:' + err.getFields(), Method_Name__c = 'createPhasesTasks'));
                            }
                        }
                    }
                } catch (Exception ex) {
                    lstOfErrorLogs.add(new PMT_Error_Log__c(Apex_Class__c = 'PMT_ClonePhaseTaskCtrl', Error_Message__c = ex.getMessage(), Method_Name__c = 'createPhasesTasks'));
                }
                
                //Calling util method to check CRUD
                if (!lstOfErrorLogs.isEmpty() && Schema.sObjectType.PMT_Error_Log__c.isCreateable()) {
                    INSERT lstOfErrorLogs;
                }
            }
        }
        
        //Cloning the selected Task records
        if(lstTasks.size()>0){
            Map<Id, Id> newOldPhases = new Map<Id, Id> ();
            
            for (PMT_Phase__c ph: lstClonedPhases) {
                newOldPhases.put(ph.getCloneSourceId(), ph.Id);
            }    
            
            List<PMT_Task__c> lstSelectedTasks = [Select Id, Name, Phase__c, Start_Days_Out__c, Duration_In_Days__c, Assigned_To1__c, Status__c, Percentage_Completion__c, 
                                                  On_Hold_Reason__c, Topic__c, Is_Milestone__c, Start_Date__c, Due_Date__c, Sign_off_status__c, Task_Level__c, Description__c, Is_Recurring__c, Checklist_Selected__c from PMT_Task__c where Id IN: lstTasks WITH SECURITY_ENFORCED limit:limits.getLimitQueryRows()];
            
            for (PMT_Task__c task: lstSelectedTasks) {
                PMT_Task__c taskClone = task.clone(false, false, false, false);
                taskClone.Phase__c = newOldPhases.get(task.Phase__c);
                taskClone.Assigned_To1__c = null;
                taskClone.Status__c = 'Not Started';
                taskClone.Percentage_Completion__c = null;
                taskClone.On_Hold_Reason__c = '';
                taskClone.Topic__c = '';
                taskClone.Is_Milestone__c = false;
                taskClone.Start_Date__c = null;
                taskClone.Due_Date__c = null;
                
                if(task.Start_Days_Out__c!=null && projectStartDate!=null && holidaysSet.size()>0){
                    taskClone.Start_Date__c = calculateStartEndDates(projectStartDate, Integer.valueOf(task.Start_Days_Out__c), holidaysSet);
                }else if(task.Start_Days_Out__c!=null && projectStartDate!=null){
                    taskClone.Start_Date__c  = projectStartDate.addDays(Integer.valueOf(task.Start_Days_Out__c));
                    }
                
                if(taskClone.Start_Date__c!=null && task.Duration_In_Days__c!=null && projectStartDate!=null && holidaysSet.size()>0){
                    taskClone.Due_Date__c = calculateStartEndDates(taskClone.Start_Date__c, Integer.valueOf(task.Duration_In_Days__c), holidaysSet);
                }else if(taskClone.Start_Date__c!=null && task.Duration_In_Days__c!=null && projectStartDate!=null){
                    taskClone.Due_Date__c = taskClone.Start_Date__c.addDays(Integer.valueOf(task.Duration_In_Days__c));
                }

                lstClonedTasks.add(taskClone);
            }
            
            if (lstClonedTasks.size() > 0) {
                try {
                    Database.SaveResult[] srList = Database.INSERT(lstClonedTasks, false);
                    for (Database.SaveResult sr: srList) {
                        if (!sr.isSuccess()) {
                            // Operation failed, so get all errors                
                            for (Database.Error err: sr.getErrors()) {
                                lstOfErrorLogs.add(new PMT_Error_Log__c(Apex_Class__c = 'PMT_ClonePhaseTaskCtrl', Error_Message__c = err.getMessage() + 'and fields that affected this error:' + err.getFields(), Method_Name__c = 'createPhasesTasks'));
                            }
                        }
                    }
                } catch (Exception ex) {
                    lstOfErrorLogs.add(new PMT_Error_Log__c(Apex_Class__c = 'PMT_ClonePhaseTaskCtrl', Error_Message__c = ex.getMessage(), Method_Name__c = 'createPhasesTasks'));
                }
                //Checking CRUD for error logging object
                if (!lstOfErrorLogs.isEmpty() && Schema.sObjectType.PMT_Error_Log__c.isCreateable()) {
                    INSERT lstOfErrorLogs;
                }
            }
        }
    }
    
    /********************************************************************************************************************
    * Method Name : calculateStartEndDates
    * Params : Accepts a Date, Count(Integer) & List<String> holidays
    * Return : Date
    * Description : Method to calculate Date based on date, DaysOut & holidays(configured in PMT settings) 
    * ******************************************************************************************************************/
    public static Date calculateStartEndDates(Date startDate, Integer daysOut, List<String> holidaysList)  
    {    
        Date newDate; 
        
        for(integer i=1; i <= daysOut; i++)  
        {  
            Date dt = startDate + i;  
            DateTime currDate = DateTime.newInstance(dt.year(), dt.month(), dt.day());  
            String todayDay = currDate.format('EEE');  
            if(!holidaysList.contains(todayDay))  
            {  
                newDate = dt;
            }else{
                daysOut = daysOut+1;
            }  
        }  
        return newDate;  
    }  
}