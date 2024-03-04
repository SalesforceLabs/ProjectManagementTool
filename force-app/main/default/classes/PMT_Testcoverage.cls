/******************************************************************************
* Name: PMT_Testcoverage
* Test class for: PMT_ProjectSummaryCtrl (85%)
				  PMT_Utility (96%)
				  PMT_ResourceManagementCtrl (93%)	
******************************************************************************/
@isTest
public class PMT_Testcoverage {
 
    @testSetup static void setup(){
		List<PMT_Phase__c> lstOfPhases = new List<PMT_Phase__c>();
		List<PMT_Task__c> lstOfTasks = new List<PMT_Task__c>();
		Integer resourceAvailability = Integer.valueOf(PMT_Utility.getPMTSettings('Default').Default_Availability_for_Scheduler__c);
        
    //Create Project
        PMT_Project__c project = new PMT_Project__c(
													Name = 'Project Controller Test', 
													Portfolio__c = 'R2R',
													Initial_End_Date__c = System.today()+30,
													Initial_Start_Date__c = System.today(),
        											Level_of_Effort__c = 'Small');
													
        INSERT project;
        
    //Create Phases
        PMT_Phase__c phase1 = new PMT_Phase__c( Name = 'Phase 1',
											    Project__c = project.Id);
        
		lstOfPhases.add(phase1);
       
        PMT_Phase__c phase2 = new PMT_Phase__c( Name = 'Phase 2',
											    Project__c = project.Id);
        
		lstOfPhases.add(phase2);
		INSERT lstOfPhases;
        
    //Create Tasks
        PMT_Task__c task1 = new PMT_Task__c(
											Name = 'Late Task 1', 
											Status__c = 'In Progress',
											Start_Date__c = System.today()-40, 
											Due_Date__c = System.today()-10, 
											Is_Milestone__c = true,
											Phase__c = lstOfPhases[0].Id); 
        lstOfTasks.add(task1);
        
        PMT_Task__c task2 = new PMT_Task__c(
										Name ='Late Task 2', 
										Status__c = 'In Progress',
										Start_Date__c = System.today()-40, 
										Due_Date__c = System.today()-10, 
										Is_Milestone__c = false,
										Phase__c = lstOfPhases[1].Id); 
        lstOfTasks.add(task2);

        PMT_Task__c task3 = new PMT_Task__c(
										Name = 'Current Task 1', 
										Status__c = 'Completed',
										Start_Date__c = System.today()-15, 
										Due_Date__c = System.today(), 
										Is_Milestone__c = false, 
										Phase__c = lstOfPhases[0].Id);
        lstOfTasks.add(task3);
        
        PMT_Task__c task4 = new PMT_Task__c(
										Name = 'Current Task 2', 
										Status__c = 'Completed',
										Start_Date__c = System.today(), 
										Due_Date__c = System.today()+10, 
										Is_Milestone__c = false, 
										Phase__c = lstOfPhases[1].Id);
        lstOfTasks.add(task4);
		INSERT lstOfTasks;
        
        //Availability record
            PMT_Resource_Availability__c resAvailwithUser = new PMT_Resource_Availability__c( User__c = UserInfo.getUserId(),
                                                                                     Fiscal_Year__c = 'FY21',
                                                                                     Jan__c = resourceAvailability, Feb__c = resourceAvailability, 
                                                                                     Mar__c = resourceAvailability, Apr__c = resourceAvailability, 
                                                                                     May__c = resourceAvailability, Jun__c = resourceAvailability, 
                                                                                     Jul__c = resourceAvailability, Aug__c = resourceAvailability, 
                                                                                     Sep__c = resourceAvailability, Oct__c = resourceAvailability,
                                                                                     Nov__c = resourceAvailability, Dec__c = resourceAvailability);
            INSERT resAvailwithUser;
        
       		PMT_Resource_Availability__c resAvailWOUSer = new PMT_Resource_Availability__c(Fiscal_Year__c = 'FY21',
                                                                                     Jan__c = resourceAvailability, Feb__c = resourceAvailability, 
                                                                                     Mar__c = resourceAvailability, Apr__c = resourceAvailability, 
                                                                                     May__c = resourceAvailability, Jun__c = resourceAvailability, 
                                                                                     Jul__c = resourceAvailability, Aug__c = resourceAvailability, 
                                                                                     Sep__c = resourceAvailability, Oct__c = resourceAvailability,
                                                                                     Nov__c = resourceAvailability, Dec__c = resourceAvailability);
            INSERT resAvailWOUSer;
        
         //Allocation records
             PMT_Resource_Allocation__c resAllocation = new PMT_Resource_Allocation__c(Project__c = project.Id,
                                                                                          Resource_Availability__c = resAvailwithUser.Id,
                                                                                          Role__c = 'SME' ); 
            INSERT resAllocation;
        
        
        //Create Cases for PMT Project
            List<case> lstOfCases = new List<Case>();
            Id caseRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get(System.Label.PMT_Project_Record_Type_on_Case).getRecordTypeId();
            for(Integer i=0; i<10; i++){
                lstOfCases.add(new Case(Subject='test case', RecordTypeId = caseRecordTypeId, PMT_Project__c = project.Id));            
            }
            INSERT lstOfCases;
        
    }
    
 	/*****************************************************************************************
    * Method Name: getSummaryWrapperTestCase
    * Class : PMT_ProjectSummaryCtrl
    * Description: Test method for getSummaryWrapper apex method which return wrapper of related phases and tasks
    * *****************************************************************************************/  
    static testmethod void getSummaryWrapperTestCase(){  
        User testUser = PMT_Testcoverage.createUser('Standard User', new List<String>{'PMT_User'});
        System.runAs(testUser){
            PMT_Project__c projectRec = [SELECT Id FROM PMT_Project__c LIMIT 1];
            
            Test.startTest();
            PMT_ProjectSummaryCtrl.createSummaryWrapper wrapperObj = PMT_ProjectSummaryCtrl.getSummaryWrapper(projectRec.Id);
            Test.stopTest();
            system.assertEquals(2, wrapperObj.phasesList.size(),'Check the size of the phase list');
            system.assertEquals(2, wrapperObj.lateTaskList.size(),'Check the size of the late task list');  
            system.assertEquals(2, wrapperObj.onGoingTaskList.size(),'Check the size of the onGoing task list');
            system.assertEquals(1, wrapperObj.milestoneTaskList.size(),'Check the size of the milestone task list'); 
        }
    }
        
    /*****************************************************************************************
    * Method Name: getCasesForProjectTestCase
    * Class : PMT_Utility
    * Description: Test method for getCasesForProject apex method which Search for cases related to project
    * *****************************************************************************************/   
    static testmethod void getCasesForProjectTestCase(){    
        User testUser = PMT_Testcoverage.createUser('Standard User', new List<String>{'PMT_User'});
        System.runAs(testUser){
            PMT_Project__c projectRec = [SELECT Id FROM PMT_Project__c LIMIT 1];
            Test.startTest();
                List<Case> lstOfResult = PMT_Utility.getCasesForProject(projectRec.Id);
            Test.stopTest();
            system.assertEquals(10, lstOfResult.size(), 'There must be 10 cases related to project.');
        }
    }
    
    /*****************************************************************************************
    * Method Name: getPMTSettingsTest
    * Class : PMT_Utility
    * Description: Test method for getPMTSettings apex method which Search for cases related to project
    * *****************************************************************************************/   
    static testmethod void getPMTSettingsTest(){    
        User testUser = PMT_Testcoverage.createUser('Standard User', new List<String>{'PMT_User'});
        System.runAs(testUser){
            PMT_Project__c projectRec = [SELECT Id FROM PMT_Project__c LIMIT 1];
            Test.startTest();
                PMT_Setting__mdt setting = PMT_Utility.getPMTSettings('Test');
            Test.stopTest();
            system.assertNotEquals(null, setting, 'A setting should be returned even if not found with the name test');
        }
    }
    
    
    /*****************************************************************************************
    * Method Name: getAllocationsForResourceTestCase
    * Class : PMT_ResourceManagementCtrl
    * Description: Test method for getAllocationsForResource apex method which Search for resource availability on allocations
    * *****************************************************************************************/    
    static testmethod void getAllocationsForResourceTestCase(){
        User testUser = PMT_Testcoverage.createUser('Standard User', new List<String>{'PMT_User'});
        System.runAs(testUser){
            PMT_Resource_Availability__c resource = [SELECT Id FROM PMT_Resource_Availability__c WHERE User__c !=''];
            
            Test.startTest();
            PMT_ResourceManagementCtrl.AvailabilityWrapper wrapper = PMT_ResourceManagementCtrl.getAllocationsForResource(resource.Id, 'FY21');
            Test.stopTest();
            system.assertEquals(1, wrapper.resourceAvailabilities.size(), 'There should be 1 availability present.');
        }
    }
    
    /*****************************************************************************************
    * Method Name: updateAllocationsTestCase
    * Class : PMT_ResourceManagementCtrl
    * Description: Test method for updateAllocations apex method which updates resource allocation record
    * *****************************************************************************************/    
    static testmethod void updateAllocationsTestCase(){
        User testUser = PMT_Testcoverage.createUser('Standard User', new List<String>{'PMT_Resource_Planner'});
        System.runAs(testUser){
            PMT_Resource_Allocation__c resource = [SELECT Id, Jan__c FROM PMT_Resource_Allocation__c WHERE UserId__c != ''];
            resource.Jan__c = 50;
            
            Test.startTest();
            List<PMT_Resource_Allocation__c> lstOfResult = PMT_ResourceManagementCtrl.updateAllocations(new List<PMT_Resource_Allocation__c>{resource});
            PMT_Resource_Allocation__c resourceUpdated = [SELECT Id, Jan__c FROM PMT_Resource_Allocation__c WHERE Id =: resource.Id];
            Test.stopTest();
            system.assertEquals(50, resourceUpdated.Jan__c, 'Jan allocation must be updated.');
        }
    }
    
    /*****************************************************************************************
    * Method Name: deleteRecordTestCase
    * Class : PMT_ResourceManagementCtrl
    * Description: Test method for deleteRecord apex method which deletes sObject record
    * *****************************************************************************************/    
    static testmethod void deleteRecordTestCase(){
        User testUser = PMT_Testcoverage.createUser('Standard User', new List<String>{'PMT_Resource_Planner'});
        System.runAs(testUser){
            PMT_Resource_Allocation__c resource = [SELECT Id, Jan__c FROM PMT_Resource_Allocation__c WHERE UserId__c != ''];
            
            Test.startTest();
            Boolean result = PMT_ResourceManagementCtrl.deleteRecord(resource);
            Test.stopTest();
            system.assertEquals(true, result, 'Allocation must be deleted.');
        }
    }
    
    /*****************************************************************************************
    * Method Name: deleteRecordNegTestCase
    * Class : PMT_ResourceManagementCtrl
    * Description: Negative Test method for deleteRecord apex method which deletes sObject record
    * *****************************************************************************************/    
    static testmethod void deleteRecordNegTestCase(){
        User testUser = PMT_Testcoverage.createUser('Standard User', new List<String>{'PMT_Resource_Planner'});
        System.runAs(testUser){
            PMT_Project__c project = [SELECT Id FROM PMT_Project__c LIMIT 1];
            PMT_Resource_Availability__c resAvail = [SELECT Id FROM PMT_Resource_Availability__c LIMIT 1]; 
            //Allocation records
            PMT_Resource_Allocation__c resAllocation = new PMT_Resource_Allocation__c(Project__c = project.Id,
                                                                                      Resource_Availability__c = resAvail.Id,
                                                                                      Role__c = 'SME' ); 
            
            Test.startTest();
            Boolean result = PMT_ResourceManagementCtrl.deleteRecord(resAllocation);
            Test.stopTest();
            system.assertEquals(false, result, 'Allocation must be deleted.');
        }
    }
    
    
    /*****************************************************************************************
    * Method Name: upsertDeleteAllocationTestCase
    * Class : PMT_ResourceManagementCtrl
    * Description: Test method for upsertDeleteAllocation apex method which deletes and upserts new allocations
    * *****************************************************************************************/    
    static testmethod void upsertDeleteAllocationTestCase(){
        User testUser = PMT_Testcoverage.createUser('Standard User', new List<String>{'PMT_Resource_Planner'});
        System.runAs(testUser){
            PMT_Project__c project = [SELECT Id FROM PMT_Project__c LIMIT 1];
            PMT_Resource_Availability__c resAvail = [SELECT Id FROM PMT_Resource_Availability__c LIMIT 1]; 
            //Allocation records
            PMT_Resource_Allocation__c resAllocation = new PMT_Resource_Allocation__c(Project__c = project.Id,
                                                                                      Resource_Availability__c = resAvail.Id,
                                                                                      Role__c = 'IT' );
            
            PMT_Resource_Allocation__c resAllToDelete = [SELECT Id FROM PMT_Resource_Allocation__c WHERE Resource_Availability__c =: resAvail.Id];
            
            Test.startTest();
            PMT_ResourceManagementCtrl.upsertDeleteAllocation(new List<SObject>{resAllocation}, new List<SObject>{resAllToDelete}, project);
            PMT_Resource_Allocation__c resAllInserted = [SELECT Id, Role__c FROM PMT_Resource_Allocation__c WHERE Resource_Availability__c =: resAvail.Id];
            Test.stopTest();
            System.assertEquals('IT', resAllInserted.Role__c, 'Role of allocation should be IT.');
        }
    }
    
    /*****************************************************************************************
    * Method Name: getResourceDetailsWrapperTestCase
    * Class : PMT_ResourceManagementCtrl
    * Description: Test method for getResourceDetailsWrapper apex method which search for availabilities, allocations
    * *****************************************************************************************/    
    static testmethod void getResourceDetailsWrapperTestCase(){
        User testUser = PMT_Testcoverage.createUser('Standard User', new List<String>{'PMT_User'});
        System.runAs(testUser){
            PMT_Project__c project = [SELECT Id,Start_Fiscal_Year__c,End_Fiscal_Year__c FROM PMT_Project__c LIMIT 1];
            system.debug(project);
            system.debug([select id, project__r.name from PMT_Resource_Allocation__c]);
            system.debug([select id, User__r.name from PMT_Resource_Availability__c]);
            
            Test.startTest();
            PMT_ResourceManagementCtrl.ResourceDetail resDetails = PMT_ResourceManagementCtrl.getResourceDetailsWrapper(project);
            system.debug(resDetails);
            system.assertEquals(1, resDetails.ResourceAllocations.size(), '1 allocation should be found');
            system.assertEquals(1, resDetails.ResourceAvailabilities.size(), '1 availability should be found');
            system.assertEquals(1, resDetails.dummyAvailabilities.size(), '1 Dummy availability should be found');
            Test.stopTest();
        }
    }
    
    /*****************************************************************************************
    * Method Name: getFiltersTest
    * Class : PMT_ResourceManagementCtrl
    * Description: Test method for getFilters apex method which returns picklist filters
    * *****************************************************************************************/    
    static testmethod void getFiltersTest(){
        User testUser = PMT_Testcoverage.createUser('Standard User', new List<String>{'PMT_User'});
        System.runAs(testUser){
            Test.startTest();
        	List<List<String>> filters= PMT_ResourceManagementCtrl.getFilters();
            system.assertEquals(3, filters.size(), '2 filters departments and years + fiscal year offset should be found');
            system.assert(filters[0].size()>0, 'More than 1 dept filter should be found');
            system.assertEquals(1, filters[1].size(), '1 year should be found');
            Test.stopTest();
        }
    }
    
    /*****************************************************************************************
    * Method Name: getResourceAllocationsTest1
    * Class : PMT_ResourceManagementCtrl
    * Description: Test method for getResourceAllocations apex method which returns picklist filters
    * *****************************************************************************************/    
    static testmethod void getResourceAllocationsTest1(){
        User testUser = PMT_Testcoverage.createUser('Standard User', new List<String>{'PMT_User'});
        String department = [select Department from User where id = :userInfo.getUserId() limit 1].Department;
        System.runAs(testUser){
            Test.startTest();
            PMT_Project__c project = [SELECT Id,Start_Fiscal_Year__c,End_Fiscal_Year__c FROM PMT_Project__c LIMIT 1];
        	PMT_ResourceManagementCtrl.ResourceDataWrapper wrapper = PMT_ResourceManagementCtrl.getResourceAllocations('FY21',department , null, null, project.Id);
            system.assertEquals(1, wrapper.resourceAvailabilities.size(), '1 availability should be found');
            system.assertEquals(1, wrapper.resourceAllocations.size(), '1 resourceAllocations should be found');
            Test.stopTest();
        }
    }
    
    /*****************************************************************************************
    * Method Name: getResourceAllocationsTest2
    * Class : PMT_ResourceManagementCtrl
    * Description: Test method for getResourceAllocations apex method which returns picklist filters
    * *****************************************************************************************/    
    static testmethod void getResourceAllocationsTest2(){
        User testUser = PMT_Testcoverage.createUser('Standard User', new List<String>{'PMT_User'});
        System.runAs(testUser){
            Test.startTest();
        	PMT_ResourceManagementCtrl.ResourceDataWrapper wrapper = PMT_ResourceManagementCtrl.getResourceAllocations('FY21', 'A'+System.currentTimeMillis() , null, null, null);
            system.assertEquals(0, wrapper.resourceAvailabilities.size(), 'No availabilities should be found');
            system.assertEquals(0, wrapper.resourceAllocations.size(), 'No resourceAllocations should be found');
            Test.stopTest();
        }
    }
    
    /*****************************************************************************************
    * Method Name: testInstallScript
    * Class : PMT_InstallHandler
    * Description: Test method for getResourceAllocations apex method which returns picklist filters
    * *****************************************************************************************/ 
    @isTest
    static void testInstallScript() {
        PMT_InstallHandler installHandlerScript = new PMT_InstallHandler();
        Test.testInstall(installHandlerScript, null);
        Test.startTest();
        List<PMT_Program__c> programs = [select id from PMT_Program__c];
        List<PMT_Project__c> projects = [select id from PMT_Project__c];
        List<PMT_Phase__c> phases = [select id from PMT_Phase__c];
        List<PMT_Task__c> tasks = [select id from PMT_Task__c];
        List<PMT_Resource_Availability__c> avails = [select id from PMT_Resource_Availability__c];
        List<PMT_Resource_Allocation__c> allocs = [select id from PMT_Resource_Allocation__c];
        System.assert(programs.size()>0, 'Program records should be present');
        System.assert(projects.size()>0, 'Project records should be present');
        System.assert(phases.size()>0, 'Phase records should be present');
        System.assert(tasks.size()>0, 'Task records should be present');
        System.assert(avails.size()>0, 'Availability records should be present');
        System.assert(allocs.size()>0, 'Allocation records should be present');
        Test.stopTest();
    }

    /*****************************************************************************
     * Name : createUser
     * Description : Method to create User with permission sets assigned
     * Parameters : Profile name which to be assigned to new user and list of permission sets assigned to him
     * Output : User record  
     * **************************************************************************/
    public static User createUser(String profileName, List<String> lstOfPermissionSets){
        List<PermissionSetAssignment> lstOfPSA = new List<PermissionSetAssignment>();
        String userName = 'testUser';
        String userEmail = userName + Math.random()+'@test.com.invalid';        
        User userRecord;       
        
        Id profileId = [SELECT Id FROM Profile WHERE Name =:profileName limit 1].Id;
        userRecord = new User(
            profileId = profileId,
            LastName = 'last',
            Email = userEmail,
            Username = userName +'@testOrg.' + System.currentTimeMillis(),
            CompanyName = 'TEST',
            Title = 'title',
            Alias = userName,
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US'
        );
        INSERT userRecord;
        
        for(PermissionSet psRec : [SELECT Id FROM PermissionSet WHERE Name IN: lstOfPermissionSets]){
            PermissionSetAssignment psa = new PermissionSetAssignment(AssigneeId = userRecord.Id, PermissionSetId = psRec.Id);
            lstOfPSA.add(psa);
        }                        
        INSERT lstOfPSA; 
            
        return userRecord;
    }
}