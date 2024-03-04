/******************************************************************************
* Name: PMT_InstallHandler.apxc
* Description : Creates a dummy project after installation on a sandbox or dev edition
* Test class : PMT_Testcoverage(100%)
******************************************************************************/
global with sharing class PMT_InstallHandler implements InstallHandler {
    global void onInstall(InstallContext context) {
        Id organizationId = context.organizationId();
        Id userId = context.installerID();
        if(context.previousVersion() == null) {
            try{
                Organization org = [Select id,InstanceName, OrganizationType, isSandbox from Organization where id=:organizationId with security_enforced limit 1];
                if(org?.isSandbox || org?.OrganizationType=='Developer Edition'){
                    PMT_Program__c program = new PMT_Program__c(
                        Name = 'Program 1',
                        OwnerId= userId,
                        Program_Health__c = 'On Track');
                    SObjectAccessDecision securityDecision = Security.stripInaccessible(
                        AccessType.CREATABLE, new List<PMT_Program__c>{program});
                    insert securityDecision.getRecords();
                    
                    PMT_Project__c project = new PMT_Project__c(
                        Name = 'Demo Project', 
                        Portfolio__c = 'R2R',
                        OwnerId= userId,
                        Initial_End_Date__c = System.today()+30,
                        Initial_Start_Date__c = System.today(),
                        Program__c = securityDecision.getRecords()[0]?.Id,
                        Level_of_Effort__c = 'Small');
                    securityDecision = Security.stripInaccessible(AccessType.CREATABLE, new List<PMT_Project__c>{project});
                    insert securityDecision.getRecords();
                    
                    Id projectId = securityDecision.getRecords()[0]?.Id;
                    List<PMT_Phase__c> lstOfPhases = new List<PMT_Phase__c>();
                    List<PMT_Task__c> lstOfTasks = new List<PMT_Task__c>();
                    Integer resourceAvailability = Integer.valueOf(PMT_Utility.getPMTSettings('Default').Default_Availability_for_Scheduler__c);
                    //Create Phases
                    PMT_Phase__c phase1 = new PMT_Phase__c( Name = '0. Discovery',
                                                           Project__c = projectId);
                    
                    lstOfPhases.add(phase1);
                    
                    PMT_Phase__c phase2 = new PMT_Phase__c( Name = '1. Initiate',
                                                           Project__c = projectId);
                    
                    lstOfPhases.add(phase2);
                    
                    PMT_Phase__c phase3 = new PMT_Phase__c( Name = '2. Execute',
                                                           Project__c = projectId);
                    
                    lstOfPhases.add(phase3);
                    
                    PMT_Phase__c phase4 = new PMT_Phase__c( Name = '3. Transition',
                                                           Project__c = projectId);
                    
                    lstOfPhases.add(phase4);
                    
                    securityDecision = Security.stripInaccessible(AccessType.CREATABLE, lstOfPhases);
                    insert securityDecision.getRecords();
                    
                    //Create Tasks
                    PMT_Task__c task1 = new PMT_Task__c(
                        Name = '0.00 Project Start', 
                        Status__c = 'Completed',
                        Start_Date__c = System.today()-40, 
                        Due_Date__c = System.today()-10, 
                        Is_Milestone__c = true,
                        Assigned_to1__c = userId,
                        Phase__c = securityDecision.getRecords()[0]?.Id); 
                    lstOfTasks.add(task1);
                    
                    PMT_Task__c task2 = new PMT_Task__c(
                        Name ='1.1 Task 1', 
                        Status__c = 'In Progress',
                        Start_Date__c = System.today()-40, 
                        Due_Date__c = System.today()-10, 
                        Is_Milestone__c = false,
                        Phase__c = securityDecision.getRecords()[1]?.Id); 
                    lstOfTasks.add(task2);
                    
                    PMT_Task__c task3 = new PMT_Task__c(
                        Name = '2.1 Task 2', 
                        Status__c = 'Not Started',
                        Start_Date__c = System.today()-15, 
                        Due_Date__c = System.today(), 
                        Is_Milestone__c = false,
                        Assigned_to1__c = userId,
                        Phase__c = securityDecision.getRecords()[2]?.Id);
                    lstOfTasks.add(task3);
                    
                    PMT_Task__c task4 = new PMT_Task__c(
                        Name = '2.2 Task 3', 
                        Status__c = 'Not Started',
                        Start_Date__c = System.today()+40, 
                        Due_Date__c = System.today()+50, 
                        Is_Milestone__c = false, 
                        Phase__c = securityDecision.getRecords()[2]?.Id);
                    lstOfTasks.add(task4);
                    
                    PMT_Task__c task5 = new PMT_Task__c(
                        Name = '3.99 Project End', 
                        Status__c = 'Not Started',
                        Start_Date__c = System.today()+89, 
                        Due_Date__c = System.today()+90, 
                        Is_Milestone__c = false,
                        Assigned_to1__c = userId,
                        Phase__c = securityDecision.getRecords()[3]?.Id);
                    lstOfTasks.add(task5);
                    
                    securityDecision = Security.stripInaccessible(AccessType.CREATABLE, lstOfTasks);
                    insert securityDecision.getRecords();
                    
                    string fiscalYear = 'FY' + (Math.mod(system.today().year(), 1000)+1);
                    //Availability record
                    PMT_Resource_Availability__c resAvailwithUser = new PMT_Resource_Availability__c( User__c = userId,
                                                                                                     Fiscal_Year__c = fiscalYear,
                                                                                                     Jan__c = resourceAvailability, Feb__c = resourceAvailability, 
                                                                                                     Mar__c = resourceAvailability, Apr__c = resourceAvailability, 
                                                                                                     May__c = resourceAvailability, Jun__c = resourceAvailability, 
                                                                                                     Jul__c = resourceAvailability, Aug__c = resourceAvailability, 
                                                                                                     Sep__c = resourceAvailability, Oct__c = resourceAvailability,
                                                                                                     Nov__c = resourceAvailability, Dec__c = resourceAvailability);
                    
                    PMT_Resource_Availability__c resAvailWOUSer = new PMT_Resource_Availability__c(Fiscal_Year__c = fiscalYear,
                                                                                                   Jan__c = resourceAvailability, Feb__c = resourceAvailability, 
                                                                                                   Mar__c = resourceAvailability, Apr__c = resourceAvailability, 
                                                                                                   May__c = resourceAvailability, Jun__c = resourceAvailability, 
                                                                                                   Jul__c = resourceAvailability, Aug__c = resourceAvailability, 
                                                                                                   Sep__c = resourceAvailability, Oct__c = resourceAvailability,
                                                                                                   Nov__c = resourceAvailability, Dec__c = resourceAvailability);
                    securityDecision = Security.stripInaccessible(AccessType.CREATABLE, new List<PMT_Resource_Availability__c>{resAvailwithUser, resAvailWOUSer});
                    insert securityDecision.getRecords();
                    
                    List<PMT_Resource_Allocation__c> lstAllocation = new List<PMT_Resource_Allocation__c>();
                    
                    //Allocation records
                    PMT_Resource_Allocation__c resAllocation = new PMT_Resource_Allocation__c(Project__c = projectId,
                                                                                              Resource_Availability__c = securityDecision.getRecords()[1]?.Id,
                                                                                              Role__c = 'SME');
                    lstAllocation.add(resAllocation);
                    securityDecision = Security.stripInaccessible(AccessType.CREATABLE, lstAllocation);
                    insert securityDecision.getRecords();
                }
            }
            catch(Exception e){
                System.debug(e.getMessage());
            }
        }
    }
}