/***********************************************************************************************************
 * Name: PMT_ResourceAvailabilitySchedulerTest
 * Test Class for: PMT_CreateResourceAvailability (86%)
 *                 PMT_ResourceAvailabilityScheduler (100%)
 ***********************************************************************************************************/
@isTest 
Public class PMT_ResourceAvailabilitySchedulerTest{
    /*****************************************************************
     * Method Name : updateUserTestCase
     * Description : Test method for unit testing process automation written on User
     * **************************************************************/
    static testMethod void updateUserTestCase(){       
            User testUser = PMT_Testcoverage.createUser('System Administrator', new List<String>{'PMT_Resource_Planner'});
            System.runAs(testUser){
                Profile standardprofile = [SELECT Id FROM Profile WHERE Name='Standard User'];
                
                User pmtUsr = new User(Alias = 'PMT', Email='PMTUser@testClass.com', 
                EmailEncodingKey='UTF-8', LastName='User', LanguageLocaleKey='en_US', 
                LocaleSidKey='en_US', ProfileId = standardprofile.Id, 
                TimeZoneSidKey='America/Los_Angeles', UserName='PMTUser@testClass.com', IsActive = true);
                INSERT pmtUsr;
            
            
                Test.startTest();
                PMT_CreateResourceAvailability.createRAOnUserInsert(new List<Id>{pmtUsr.Id});
                Test.stopTest();
                List<PMT_Resource_Availability__c> lstOfResourceAvailability = [SELECT id FROM PMT_Resource_Availability__c WHERE User__c =: pmtUsr.Id];
                System.assertEquals(lstOfResourceAvailability.size()>0 , true, 'Resource availability should be created for user.');
           }     
          
    }
    
    /*****************************************************************
     * Method Name : updateUserTestCase
     * Description : Test method for unit testing scheduler which creates Resource availability for all PMT users
     * **************************************************************/
    static testMethod void apexSchedulerTestCase(){
   
            Profile standardprofile = [SELECT Id FROM Profile WHERE Name='Standard User'];
            
            User pmtUsr = new User(Alias = 'PMT', Email='PMTUser@testClass.com', 
            EmailEncodingKey='UTF-8', LastName='User', LanguageLocaleKey='en_US', 
            LocaleSidKey='en_US', ProfileId = standardprofile.Id, 
            TimeZoneSidKey='America/Los_Angeles', UserName='PMTUser@testClass.com', IsActive = true, Department='Sales', Is_PMT_User_consider_for_Availability__c = true);
            INSERT pmtUsr;
            
            User testUser = PMT_Testcoverage.createUser('Standard User', new List<String>{'PMT_Resource_Planner'});
            System.runAs(testUser){
                Test.startTest();             
                    PMT_ResourceAvailabilityScheduler scheduler = new PMT_ResourceAvailabilityScheduler();
                    scheduler.execute(null);            
                Test.stopTest();
                List<PMT_Resource_Availability__c> lstOfResourceAvailability = [SELECT id FROM PMT_Resource_Availability__c WHERE User__c =: pmtUsr.Id];
                System.assertEquals(lstOfResourceAvailability.size()>0 , true, 'Resource availability should be created for user.');
            }
           
    }
}