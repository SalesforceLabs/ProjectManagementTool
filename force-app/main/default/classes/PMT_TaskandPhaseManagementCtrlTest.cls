/*************************************************
* Name: PMT_TaskandPhaseManagementCtrlTest
* Test class for : PMT_TaskandPhaseManagementCtrl (84%)
* ***********************************************/
@isTest
public class PMT_TaskandPhaseManagementCtrlTest {
	@testSetup static void setup(){
		List<PMT_Task__c> lstOfTasks = new List<PMT_Task__c>();
        Integer resourceAvailability = Integer.valueOf(PMT_Utility.getPMTSettings('Default').Default_Availability_for_Scheduler__c);
        
        //PMT project record
		PMT_Project__c project = new PMT_Project__c(Name='Project Controller Test', 
													Portfolio__c='R2R',
													Initial_End_Date__c=System.today()+30,
													Initial_Start_Date__c=System.today(),
                                                   Level_of_Effort__c = 'Small');
        INSERT project;
		
		//PMT phase record
		PMT_Phase__c phases = new PMT_Phase__c(Name = 'Phase 1',
												Project__c = project.Id);
        INSERT phases;
		
		//PMT resource availability record
        PMT_Resource_Availability__c resAvail = new PMT_Resource_Availability__c( User__c = UserInfo.getUserId(),
                                                                                     Fiscal_Year__c = 'FY21',
                                                                                     Jan__c = resourceAvailability, Feb__c = resourceAvailability, 
                                                                                     Mar__c = resourceAvailability, Apr__c = resourceAvailability, 
                                                                                     May__c = resourceAvailability, Jun__c = resourceAvailability, 
                                                                                     Jul__c = resourceAvailability, Aug__c = resourceAvailability, 
                                                                                     Sep__c = resourceAvailability, Oct__c = resourceAvailability,
                                                                                     Nov__c = resourceAvailability, Dec__c = resourceAvailability);
																					 
		INSERT resAvail;
        
        //Allocation records
        PMT_Resource_Allocation__c resAllocation = new PMT_Resource_Allocation__c(Project__c = project.Id,
                                                                                  Resource_Availability__c = resAvail.Id,
                                                                                  Role__c = 'SME' );                                                                                        
        INSERT resAllocation;
        
        //PMT Task records
		PMT_Task__c task1 = new PMT_Task__c(Name = 'Task 1', 
											Status__c = 'Not Started',
											Start_Date__c = System.today(), 
											Due_Date__c = System.today()+30, 
											Assigned_To1__c = UserInfo.getUserId(),
											Is_Milestone__c = true,
											Phase__c = phases.Id); 
		lstOfTasks.add(task1);
		
        PMT_Task__c task2 = new PMT_Task__c(Name = 'Task 2', 
											Status__c = 'Not Started',
											Start_Date__c = System.today(), 
											Due_Date__c = System.today()+30, 
											Assigned_To1__c = UserInfo.getUserId(), 
											Is_Milestone__c = false, 
											Phase__c = phases.Id);
        lstOfTasks.add(task2);
		
		INSERT lstOfTasks;
	}
    
    static testmethod void getTasksForProjectTestCase(){
        User testUser = PMT_Testcoverage.createUser('Standard User', new List<String>{'PMT_User'});
        System.runAs(testUser){
            PMT_Project__c project = [SELECT Id FROM PMT_Project__c LIMIT 1];
            Test.startTest();
            List<PMT_Task__c> lstOfResult = PMT_TaskandPhaseManagementCtrl.getTasksForProject(project.Id);
            Test.stopTest();
            system.assertEquals(2, lstOfResult.size(), 'There should be 2 tasks present.');
        }
    }
	
	static testmethod void updateTaskTestCase(){
        User testUser = PMT_Testcoverage.createUser('Standard User', new List<String>{'PMT_User'});
        System.runAs(testUser){
            PMT_Task__c taskrec = [SELECT Id, Status__c FROM PMT_Task__c LIMIT 1];
            taskrec.Status__c = 'In Progress';
            
            Test.startTest();
            List<PMT_Task__c> lstOfResult = PMT_TaskandPhaseManagementCtrl.updateTasks(new List<PMT_Task__c>{taskrec});
            PMT_Task__c taskUpdated = [SELECT Id, Status__c FROM PMT_Task__c LIMIT 1];
            Test.stopTest();
            system.assertEquals('In Progress', taskUpdated.Status__c, 'Task status must be updated.');
        }
    }
    
    static testmethod void updateTaskNegTestCase(){
        User testUser = PMT_Testcoverage.createUser('Standard User', new List<String>{'PMT_User'});
        System.runAs(testUser){
            PMT_Phase__c phase = [SELECT Id FROM PMT_Phase__c LIMIT 1];
            
            //Create Tasks        
            PMT_Task__c task = new PMT_Task__c(Name = 'Task 1', 
                                               Status__c = 'Not Started',
                                               Start_Date__c = System.today(), 
                                               Due_Date__c = System.today()+30, 
                                               Assigned_To1__c = UserInfo.getUserId(),
                                               Is_Milestone__c = true,
                                               Phase__c = phase.Id); 
            
            Test.startTest();
            try{
                List<PMT_Task__c> lstOfResult = PMT_TaskandPhaseManagementCtrl.updateTasks(new List<PMT_Task__c>{task});
            }catch(Exception e){
                System.assertEquals(true, e.getMessage().contains('error'),'The error should occur');
            }
            
            Test.stopTest();
        }
    }
    
    static testmethod void deleteRecordTestCase(){
        User testUser = PMT_Testcoverage.createUser('Standard User', new List<String>{'PMT_Global_Admin'});
        System.runAs(testUser){
            PMT_Task__c taskrec = [SELECT Id, Status__c FROM PMT_Task__c LIMIT 1];
            
            Test.startTest();
            Boolean result = PMT_TaskandPhaseManagementCtrl.deleteRecord(taskrec);
            List<PMT_Task__c> lstOfResult = [SELECT Id, Status__c FROM PMT_Task__c];
            Test.stopTest();
            system.assertEquals(1, lstOfResult.size(), 'Only 1 task should be present on delete.');
        }
    }
    
    static testmethod void deleteRecordNegTestCase(){
        User testUser = PMT_Testcoverage.createUser('Standard User', new List<String>{'PMT_Global_Admin'});
        System.runAs(testUser){
            PMT_Phase__c phase = [SELECT Id FROM PMT_Phase__c LIMIT 1];
            
            //Create Tasks        
            PMT_Task__c task = new PMT_Task__c(Name = 'Task 1', 
                                               Status__c = 'Not Started',
                                               Start_Date__c = System.today(), 
                                               Due_Date__c = System.today()+30, 
                                               Assigned_To1__c = UserInfo.getUserId(),
                                               Is_Milestone__c = true,
                                               Phase__c = phase.Id); 
            
            Test.startTest();
            Boolean result = PMT_TaskandPhaseManagementCtrl.deleteRecord(task);
            system.assertEquals(false, result, 'There should be error.');
            Test.stopTest();    
        }
    }
	
    static testmethod void savePhasesTestCase(){
        User testUser = PMT_Testcoverage.createUser('Standard User', new List<String>{'PMT_User'});
        System.runAs(testUser){
            PMT_Project__c project = [SELECT Id FROM PMT_Project__c LIMIT 1];
            
            //Create Phases        
            PMT_Phase__c phase = new PMT_Phase__c(Name='Phase 3', Project__c = project.Id);
            Test.startTest();
            PMT_TaskandPhaseManagementCtrl.savePhases(new List<PMT_Phase__c> {phase});
            
            PMT_Project__c projectUpdated = [SELECT Id, (SELECT Id FROM Project_Phases__r) FROM PMT_Project__c WHERE Id=: project.Id];			
            system.assertEquals(2, projectUpdated.Project_Phases__r.size(), 'There should be 2 phases available.');
            Test.stopTest();
        }
        
	}
    
    static testmethod void savePhasesNegTestCase(){
        User testUser = PMT_Testcoverage.createUser('Standard User', new List<String>{'PMT_User'});
        System.runAs(testUser){
            //Create Phases        
            PMT_Phase__c phase = new PMT_Phase__c(Name='Phase 3');
            Test.startTest();
            try{
                PMT_TaskandPhaseManagementCtrl.savePhases(new List<PMT_Phase__c> {phase});
            }catch(Exception e){
                System.assertEquals(true, e.getMessage().contains('error'),'The error should occur for negative test');
            }
            Test.stopTest();
        }
	}
    
    static testmethod void saveTasksTestCase(){
        User testUser = PMT_Testcoverage.createUser('Standard User', new List<String>{'PMT_User'});
        System.runAs(testUser){
            PMT_Phase__c phase = [SELECT Id FROM PMT_Phase__c LIMIT 1];
            
            //Create Tasks        
            PMT_Task__c task = new PMT_Task__c(Name = 'Task 1', 
                                               Status__c = 'Not Started',
                                               Start_Date__c = System.today(), 
                                               Due_Date__c = System.today()+30, 
                                               Assigned_To1__c = UserInfo.getUserId(),
                                               Is_Milestone__c = true,
                                               Phase__c = phase.Id); 
            
            Test.startTest();
            PMT_TaskandPhaseManagementCtrl.saveTasks(new List<PMT_Task__c> {task});
            
            PMT_Phase__c phaseUpdated = [SELECT Id, (SELECT Id FROM Project_Tasks__r) FROM PMT_Phase__c WHERE Id =: phase.Id];		
            Test.stopTest();
            system.assertEquals(3, phaseUpdated.Project_Tasks__r.size(), 'There should be 3 task available.');
        }
        
	}
    
    static testmethod void saveTasksNegTestCase(){
        User testUser = PMT_Testcoverage.createUser('Standard User', new List<String>{'PMT_User'});
        System.runAs(testUser){
            //Create Tasks        
            PMT_Task__c task = new PMT_Task__c(Name = 'Task 1', 
                                               Status__c = 'Not Started',
                                               Start_Date__c = System.today(), 
                                               Due_Date__c = System.today()+30, 
                                               Assigned_To1__c = UserInfo.getUserId(),
                                               Is_Milestone__c = true); 
            
            Test.startTest();
            try{	
                PMT_TaskandPhaseManagementCtrl.saveTasks(new List<PMT_Task__c> {task});
            }catch(Exception e){
                System.assertEquals(true, e.getMessage().contains('error'),'The error should occur for negative test');
            }					
            Test.stopTest();
        }
	}
    
    static testmethod void getPicklistvaluesTestCase(){
        User testUser = PMT_Testcoverage.createUser('Standard User', new List<String>{'PMT_User'});
        System.runAs(testUser){
            Test.startTest();
            List<String> lstOfResult = PMT_TaskandPhaseManagementCtrl.getPicklistvalues('PMT_Task__c','Status__c', false);
            Test.stopTest();
            system.assertEquals(5, lstOfResult.size(), 'There should be 5 task status available.');
        }
	}
    
    static testmethod void getTaskWrapperTestCase(){
        User testUser = PMT_Testcoverage.createUser('Standard User', new List<String>{'PMT_User'});
        System.runAs(testUser){
            PMT_Project__c project = [SELECT Id FROM PMT_Project__c LIMIT 1];
            Test.startTest();
            PMT_TaskandPhaseManagementCtrl.createTasksWrapper options = PMT_TaskandPhaseManagementCtrl.getTaskWrapper(project.Id);
            Test.stopTest();
            system.assertEquals(1, options.phasesList.size(), 'There should be 1 phase available.');
            system.assertEquals(1, options.memberList.size(), 'There should be 1 member available.');
        }
	}
    
    static testmethod void getTasksListTestCase(){
        User testUser = PMT_Testcoverage.createUser('Standard User', new List<String>{'PMT_User'});
        System.runAs(testUser){
            PMT_Task__c taskrec = [SELECT Id FROM PMT_Task__c LIMIT 1]; 
            
            Test.startTest();
            List<PMT_Task__c> lstOfResult = PMT_TaskandPhaseManagementCtrl.getTasksList(new List<ID>{taskrec.Id});
            Test.stopTest();
            system.assertEquals(true, lstOfResult[0].Assigned_To1__c != null, 'Assigned to field must be queried.');
        }
	}
    
    static testmethod void submitTaskForApprovalTestCase(){
        User testUser = PMT_Testcoverage.createUser('Standard User', new List<String>{'PMT_User'});
        System.runAs(testUser){
            PMT_Task__c taskrec = [SELECT Id FROM PMT_Task__c LIMIT 1]; 		
            Test.startTest();
            Boolean result = PMT_TaskandPhaseManagementCtrl.submitTaskForApproval(taskrec.Id);
            Test.stopTest();
            system.assertEquals(false, result, 'No approval process found'); //NOTE: Need to update assert on set up of approval process
        }
	}
	
}