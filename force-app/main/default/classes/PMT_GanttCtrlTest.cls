/******************************************************************************************************
 * Name: PMT_GanttCtrlTest.apxc
 * Test class for : PMT_GanttCtrl (87%)
 * Version : 56 
 ******************************************************************************************************/

@isTest
public with sharing class PMT_GanttCtrlTest {
    /* Create Test Data */
    @testSetup static void setup() {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User'];

        User testUser = new User(Alias = 'standt', Email = 'standarduser@pmtgantt.com',
            EmailEncodingKey = 'UTF-8', LastName = 'Testing', LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US', ProfileId = p.Id,
            TimeZoneSidKey = 'America/Los_Angeles', UserName = 'standarduser@pmtgantt.com');

        insert testUser;

        List<PermissionSetAssignment> lstOfPSA = new List<PermissionSetAssignment>();

        for (PermissionSet psRec: [SELECT Id FROM PermissionSet WHERE Name IN('PMT_User')]) {
            PermissionSetAssignment psa = new PermissionSetAssignment(AssigneeId = testUser.Id, PermissionSetId = psRec.Id);
            lstOfPSA.add(psa);
        }

        INSERT lstOfPSA;

        System.runAs(testUser) {
            List<PMT_Task__c> lstOfTask = new List<PMT_Task__c>();

            //Project 1 setup
            PMT_Program__c pg1 = new PMT_Program__c();
            pg1.Name = 'Test Program 1';
            pg1.Program_Health__c = 'On Track';
            INSERT pg1;

            PMT_Project__c prj1 = new PMT_Project__c();
            prj1.Name = 'New project 1';
            prj1.Program__c = pg1.Id;
            prj1.Project_Status__c = 'Execute';
            prj1.Project_Category__c = 'IT';
            prj1.Level_of_Effort__c = 'Medium';
            prj1.Project_Health__c = 'On Track';
            INSERT prj1;

            PMT_Phase__c ph1 = new PMT_Phase__c();
            ph1.Name = 'test phase 1';
            ph1.Project__c = prj1.Id;
            INSERT ph1;

            PMT_Phase__c ph2 = new PMT_Phase__c();
            ph2.Name = 'test phase 2';
            ph2.Project__c = prj1.Id;
            INSERT ph2;

            PMT_Task__c tsk1 = new PMT_Task__c();
            tsk1.Name = 'Task 01 for project 1';
            tsk1.Phase__c = ph1.Id;
            tsk1.Assigned_To1__c = UserInfo.getUserId();
            lstOfTask.add(tsk1);

            //Project 2 setup
            PMT_Program__c pg2 = new PMT_Program__c();
            pg2.Name = 'Test Program 2';
            pg2.Program_Health__c = 'On Track';
            INSERT pg2;

            PMT_Project__c prj2 = new PMT_Project__c();
            prj2.Name = 'New project 2';
            prj2.Program__c = pg2.Id;
            prj2.Path_to_Green__c = 'Test';
            prj2.Level_of_Effort__c = 'Medium';
            prj2.Project_Status__c = 'Transition';
            prj2.Project_Category__c = 'Non IT';
            prj2.Project_Health__c = 'At Risk';
            INSERT prj2;

            PMT_Phase__c ph3 = new PMT_Phase__c();
            ph3.Name = 'test phase 2';
            ph3.Project__c = prj2.Id;
            INSERT ph3;

            PMT_Task__c tsk2 = new PMT_Task__c();
            tsk2.Name = 'Task 02 for project 2';
            tsk2.Phase__c = ph3.Id;
            tsk2.Assigned_To1__c = UserInfo.getUserId();
            tsk2.Start_Date__c = System.Today();
            tsk2.Due_Date__c = System.Today() + 300;
            lstOfTask.add(tsk2);

            INSERT lstOfTask;
        }
    }

    static testmethod void testDefaultFilters() {
        User testUser = [SELECT Id FROM User WHERE UserName = 'standarduser@pmtgantt.com'];
        System.runAs(testUser) {
            Test.startTest();
            List<PMT_GanttCtrl.GanttDataWrapper> result1 = PMT_GanttCtrl.fetchGanttData(92, System.Today(), '', 'All', 'All', 'All','' ,'All', 'All' , 'Start_Date__c Asc');
            List<PMT_GanttCtrl.GanttDataWrapper> result2 = PMT_GanttCtrl.fetchGanttData(31, System.Today(), '', 'All', 'All', 'All','project' ,'All', 'All' , 'Start_Date__c Desc');
			List<PMT_GanttCtrl.GanttDataWrapper> result3 = PMT_GanttCtrl.fetchGanttData(31, System.Today(), '', 'All', 'All', 'All','project' ,'All', 'All' , 'Due_Date__c Asc');
            
            system.assertEquals(true, result1.size() > 0);
            system.assertEquals(true, result2.size() > 0);
            system.assertEquals(true, result3.size() > 0);
            Test.stopTest();
        }
    }

    static testmethod void testOtherFilters() {
        User testUser = [SELECT Id FROM User WHERE UserName = 'standarduser@pmtgantt.com'];
        System.runAs(testUser) {

            Test.startTest();
            List<PMT_GanttCtrl.GanttDataWrapper> result = PMT_GanttCtrl.fetchGanttData(10, System.Today(), '', 'Execute', 'On Track', 'Inov8','' ,'Non IT', 'All','Due_Date__c Asc');

            system.assertEquals(true, result.size() == 0);
            Test.stopTest();
        }
    }

    static testmethod void testProgramFilter() {
        User testUser = [SELECT Id FROM User WHERE UserName = 'standarduser@pmtgantt.com'];
        System.runAs(testUser) {
            PMT_Program__c prg = [SELECT Id FROM PMT_Program__c WHERE Name = 'Test Program 1'];

            Test.startTest();
            List<PMT_GanttCtrl.GanttDataWrapper> result = PMT_GanttCtrl.fetchGanttData(10, System.Today(), '', 'Execute', 'All', 'All', '', 'All', String.valueOf(prg.Id),'Due_Date__c Desc');
            system.assertEquals(true, result.size() > 0);
            Test.stopTest();
        }
    }

    static testmethod void testUpdateTask() {
        User testUser = [SELECT Id FROM User WHERE UserName = 'standarduser@pmtgantt.com'];
        System.runAs(testUser) {
            PMT_Task__c task = [SELECT Id FROM PMT_Task__c WHERE Name = 'Task 01 for project 1'];
            Test.startTest();

            String result = PMT_GanttCtrl.saveTask(task.Id, System.Today(), System.Today()+30);
            Date start_Date = System.Today();
            Date end_Date = start_Date + 4 - 1;

            task = [SELECT Id, Start_Date__c, Due_Date__c FROM PMT_Task__c WHERE Name = 'Task 01 for project 1'];
            system.assertEquals(true, result == 'Task updated successfully.', 'Error updating Task');
            Test.stopTest();
        }
    }

    static testmethod void testUpdateTaskNegative() {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User'];

        User testUser = new User(Alias = 'standt', Email = 'standarduser@pmtgantt.com',
            EmailEncodingKey = 'UTF-8', LastName = 'Testing', LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US', ProfileId = p.Id,
            TimeZoneSidKey = 'America/Los_Angeles', UserName = 'standarduser@pmtgantttest.com');

        insert testUser;
        System.runAs(testUser) {
            try {
                PMT_Task__c task = [SELECT Id FROM PMT_Task__c WHERE Name = 'Task 01 for project 1'];
                Test.startTest();
                String result = PMT_GanttCtrl.saveTask(task.Id, System.Today()+10, System.Today());
                Test.stopTest();
            } catch (Exception ex) {}
        }
    }

    static testmethod void testFilterValues() {
        Map<String, String> mapOfHealthValues = PMT_Utility.getPicklistValues('PMT_Project__c', 'Project_Health__c');
        Map<String, String> mapOfCategoryValues = PMT_Utility.getPicklistValues('PMT_Project__c', 'Project_Category__c');
        Map<String, String> mapOfSystemValues = PMT_Utility.getPicklistValues('PMT_Project__c', 'SystemsImpacted__c');
        Map<String, String> mapOfProgressValues = PMT_Utility.getPicklistValues('PMT_Project__c', 'Project_Status__c');

        User testUser = [SELECT Id FROM User WHERE UserName = 'standarduser@pmtgantt.com'];

        System.runAs(testUser) {
            Test.startTest();
            PMT_GanttCtrl.GanttFliterWrapper result = PMT_GanttCtrl.getGanttFilters();

            system.assertEquals(true, result.prjhealth.size() == mapOfHealthValues.size(), 'All values of Project health must be fetched.');
            system.assertEquals(true, result.prjcategory.size() == mapOfCategoryValues.size(), 'All values of Project category must be fetched.');
            system.assertEquals(true, result.sysimpacted.size() == mapOfSystemValues.size(), 'All values of System impacted must be fetched.');
            system.assertEquals(true, result.prjprogress.size() == mapOfProgressValues.size(), 'All values of Project status must be fetched.');
            Test.stopTest();
        }
    }
}