/********************************************************
* Name: PMT_ClonePhaseTaskCtrlTest
* Test class for : PMT_ClonePhaseTaskCtrl (85%)
* Version : 56
* *******************************************************/

@isTest
public class PMT_ClonePhaseTaskCtrlTest {
    
    @testSetup static void setup() {
        
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User'];
        
        User usr = new User(Alias = 'standt', Email = 'standarduser@pmttemplate.com',
                            EmailEncodingKey = 'UTF-8', LastName = 'Testing', LanguageLocaleKey = 'en_US',
                            LocaleSidKey = 'en_US', ProfileId = p.Id,
                            TimeZoneSidKey = 'America/Los_Angeles', UserName = 'standarduser@pmtdeepclone.com');
        
        insert usr;
        
        List<PermissionSetAssignment> lstOfPSA = new List<PermissionSetAssignment> ();
        
        for (PermissionSet psRec: [SELECT Id FROM PermissionSet WHERE Name IN('PMT_User')]) {
            PermissionSetAssignment psa = new PermissionSetAssignment(AssigneeId = usr.Id, PermissionSetId = psRec.Id);
            lstOfPSA.add(psa);
        }
        
        INSERT lstOfPSA;
        
        System.runAs(usr) {
            
            List<PMT_Task__c > lstOfTasks = new List<PMT_Task__c > ();
            
            //PMT project record
            PMT_Project__c project = new PMT_Project__c(Name = 'Clone Phases/Tasks Test',
                                                        Portfolio__c = 'R2R',
                                                        Initial_End_Date__c = System.today() + 30,
                                                        Initial_Start_Date__c = System.today(),
                                                        Level_of_Effort__c = 'Medium'
                                                        //TShirtSize__c = 'Explorer'
                                                       );
            INSERT project;
            
            //PMT project template record
            PMT_Project__c templateProject = new PMT_Project__c(Name = 'Template Project',
                                                                Portfolio__c = 'R2R',
                                                                Initial_End_Date__c = System.today() + 30,
                                                                Initial_Start_Date__c = System.today(),
                                                                Level_of_Effort__c = 'Medium',
                                                                IsTemplate__c = true
                                                                //TShirtSize__c = 'Explorer'
                                                               );
            INSERT templateProject;
            
            //PMT phase record
            PMT_Phase__c phases = new PMT_Phase__c(Name = 'Phase 1',
                                                   Project__c = project.Id, Phase_Health__c = 'On Track');
            INSERT phases;
            
            //PMT phase record
            PMT_Phase__c phases1 = new PMT_Phase__c(Name = 'Phase Template',
                                                    Project__c = templateProject.Id, Phase_Health__c = 'On Track');
            INSERT phases1;
            
            //PMT Task records
            PMT_Task__c task3 = new PMT_Task__c(Name = 'Task Template',
                                                Status__c = 'Not Started',
                                                Start_Date__c = System.today(),
                                                Due_Date__c = System.today() + 30,
                                                Is_Milestone__c = true,
                                                Start_Days_Out__c = 2,
                                                Duration_In_Days__c = 5,
                                                Phase__c = phases1.Id);
            lstOfTasks.add(task3);
            
            //PMT Task records
            PMT_Task__c task1 = new PMT_Task__c(Name = 'Task 1',
                                                Status__c = 'Not Started',
                                                Start_Date__c = System.today(),
                                                Due_Date__c = System.today() + 30,
                                                Is_Milestone__c = true,
                                                Phase__c = phases.Id);
            lstOfTasks.add(task1);
            
            PMT_Task__c task2 = new PMT_Task__c(Name = 'Task 2',
                                                Status__c = 'Not Started',
                                                Start_Date__c = System.today(),
                                                Due_Date__c = System.today() + 30,
                                                Is_Milestone__c = false,
                                                Phase__c = phases.Id);
            lstOfTasks.add(task2);
            
            INSERT lstOfTasks;
        }
    }
    
/*****************************************************************
* Method Name: getTasksforSelectedPhases 
* Class : PMT_ClonePhaseTaskCtrl 
******************************************************************/
    static testmethod void getTasksforSelectedPhases() {
        
        User testUser = [select id from User where Email = 'standarduser@pmttemplate.com'];
        
        System.runAs(testUser) {
            
            Test.startTest();
            
            List<PMT_Task__c> lstTasks;
            List<PMT_Project__c> lstProj = [select id from PMT_Project__c where Name = 'Clone Phases/Tasks Test'];
            
            PMT_ClonePhaseTaskCtrl.FlowInputs wrap = new PMT_ClonePhaseTaskCtrl.FlowInputs();
            wrap.phases = [select id from PMT_Phase__c where Project__c=:lstProj[0].Id];
            wrap.projectId = lstProj[0].Id;
            wrap.phaseCheck = true;
            
            List<PMT_ClonePhaseTaskCtrl.FlowInputs > paramList = new List<PMT_ClonePhaseTaskCtrl.FlowInputs > ();
            paramList.add(wrap);
            
            List<PMT_ClonePhaseTaskCtrl.FlowOutputs > outputList = PMT_ClonePhaseTaskCtrl.getTasks(paramList);
            
            for(PMT_ClonePhaseTaskCtrl.FlowOutputs tasks: outputList){
                lstTasks = tasks.outputTasks;
            }
            System.assertEquals(2, lstTasks.size(), 'There should be 2 tasks returned.');
            Test.stopTest();
        }
    }
    
/*****************************************************************
* Method Name: cloneProjectFromTemplates
* Class : PMT_ClonePhaseTaskCtrl 
******************************************************************/
    static testmethod void cloneProjectFromTemplates() {
        User testUser = [select id from User where Email = 'standarduser@pmttemplate.com'];
        
        System.runAs(testUser) {
            
            Test.startTest();
            
            List<PMT_Project__c> lstProj = [select id from PMT_Project__c where IsTemplate__c=true];
            
            PMT_ClonePhaseTaskCtrl.FlowInputs wrap = new PMT_ClonePhaseTaskCtrl.FlowInputs();
            wrap.phases = [select id, Name, Project__c, Phase_Health__c from PMT_Phase__c where Project__c=:lstProj[0].Id];
            wrap.tasks = [select id from PMT_Task__c where Name='Task Template'];
            wrap.projectId = lstProj[0].Id;
            wrap.phaseCheck = false;
            wrap.projectName = 'Test Template Project';
            wrap.projectStartDate = System.Today();
            
            List<PMT_ClonePhaseTaskCtrl.FlowInputs > paramList = new List<PMT_ClonePhaseTaskCtrl.FlowInputs > ();
            paramList.add(wrap);
            
            PMT_ClonePhaseTaskCtrl.getTasks(paramList);
            
            List<PMT_Project__c> lstProj1 = [select id from PMT_Project__c where Name='Test Template Project'];
            
            system.assertEquals(1, lstProj1.size(), 'There should be 1 new Project created from Template');
            
            Test.stopTest();
        }
    }
    
/*****************************************************************
* Method Name: cloneSelectedPhases
* Class : PMT_ClonePhaseTaskCtrl 
******************************************************************/
    static testmethod void cloneSelectedPhases() {
        User testUser = [select id from User where Email = 'standarduser@pmttemplate.com'];
        
        System.runAs(testUser) {
            
            Test.startTest();
            
            List<PMT_Project__c> lstProj = [select id from PMT_Project__c where Name='Clone Phases/Tasks Test'];
            
            PMT_ClonePhaseTaskCtrl.FlowInputs wrap = new PMT_ClonePhaseTaskCtrl.FlowInputs();
            wrap.phases = [select id, Name, Project__c, Phase_Health__c from PMT_Phase__c where Name='Phase 1'];
            wrap.projectId = lstProj[0].Id;
            wrap.phaseCheck = false;
            
            List<PMT_ClonePhaseTaskCtrl.FlowInputs > paramList = new List<PMT_ClonePhaseTaskCtrl.FlowInputs > ();
            paramList.add(wrap);
            
            PMT_ClonePhaseTaskCtrl.getTasks(paramList);
            
            Test.stopTest();
            List<PMT_Phase__c> lstPhases = [select id, Phase_Health__c from PMT_Phase__c where Name='Phase 1'];
            
            system.assertEquals(2, lstPhases.size(), 'There should be 2 phases returned.');
        }
    }
    
/*****************************************************************
* Method Name: cloneSelectedTasks
* Class : PMT_ClonePhaseTaskCtrl 
******************************************************************/
    static testmethod void cloneSelectedTasks() {
        User testUser = [select id from User where Email = 'standarduser@pmttemplate.com'];
        
        System.runAs(testUser) {
            
            Test.startTest();
            
            List<PMT_Project__c> lstProj = [select id from PMT_Project__c];
            
            PMT_ClonePhaseTaskCtrl.FlowInputs wrap = new PMT_ClonePhaseTaskCtrl.FlowInputs();
            wrap.phases = [select id from PMT_Phase__c where Name='Phase 1'];
            wrap.tasks = [select id, Phase__c from PMT_Task__c where Name='Task 1'];
            wrap.projectId = lstProj[0].Id;
            wrap.phaseCheck = false;
            
            List<PMT_ClonePhaseTaskCtrl.FlowInputs > paramList = new List<PMT_ClonePhaseTaskCtrl.FlowInputs > ();
            paramList.add(wrap);
            
            PMT_ClonePhaseTaskCtrl.getTasks(paramList);
            
            Test.stopTest();
            
            List<PMT_Task__c> lstTasks = [select id from PMT_Task__c where Name='Task 1'];
            system.assertEquals(2, lstTasks.size(), 'There should be 2 tasks returned.');
        }
    }
    
/*****************************************************************
* Method Name: cloneSelectedPhasesNegative
* Class : PMT_ClonePhaseTaskCtrl 
******************************************************************/
    static testmethod void cloneSelectedPhasesNegative() {
        User testUser = [select id from User where Email = 'standarduser@pmttemplate.com'];
        
        System.runAs(testUser) {
            
            Test.startTest();
            
            PMT_ClonePhaseTaskCtrl.FlowInputs wrap = new PMT_ClonePhaseTaskCtrl.FlowInputs();
            wrap.phases = [select id from PMT_Phase__c];
            wrap.phaseCheck = false;
            
            List<PMT_ClonePhaseTaskCtrl.FlowInputs > paramList = new List<PMT_ClonePhaseTaskCtrl.FlowInputs > ();
            paramList.add(wrap);
            
            PMT_ClonePhaseTaskCtrl.getTasks(paramList);
            
            wrap.phases = new List<PMT_Phase__c > ();
            wrap.tasks = [select id, Phase__c from PMT_Task__c];
            wrap.projectStartDate = System.Today();
            
            PMT_ClonePhaseTaskCtrl.getTasks(paramList);
            
            Test.stopTest();
            
            List<PMT_Phase__c> lstPhases = [select id from PMT_Phase__c where Name='Phase 1'];
            System.assertEquals(1, lstPhases.size(), 'There should be only 1 Phase returned due to failure');
        }
    }
}