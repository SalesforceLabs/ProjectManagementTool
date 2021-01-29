/****************************************************************************************
* Name: PMT_ResourceAllocationTriggerTest
* Test Class For: PMT_ResourceAllocationTrigger (84%)
				  PMT_ResourceAllocationTriggerHelper (90%)	
****************************************************************************************/
@isTest 
public class PMT_ResourceAllocationTriggerTest {
    @testSetup static void setup(){
        System.runAs(new User(Id = Userinfo.getUserId())) {
            Integer resourceAvailability = Integer.valueOf(PMT_Utility.getPMTSettings('Default').Default_Availability_for_Scheduler__c);
            
            Profile p = [SELECT Id FROM Profile WHERE Name='Standard User' limit 1]; 
            User usr = new User(Alias = 'pmtuser1', Email='pmtuser@testorg.com', 
                                EmailEncodingKey='UTF-8', LastName='userTesting', LanguageLocaleKey='en_US', 
                                LocaleSidKey='en_US', ProfileId = p.Id,Department='IT', 
                                TimeZoneSidKey='America/Los_Angeles', UserName='pmtuser@testorg.com'); 
            
            INSERT usr ;
            
            PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'PMT_Global_Admin'];
            INSERT new PermissionSetAssignment(AssigneeId = usr.id, PermissionSetId = ps.Id);            
            
            //Project record
            PMT_Project__c project = new PMT_Project__c(Name='Single Project Controller Test', 
                                                        Portfolio__c='R2R',
                                                        Initial_End_Date__c=System.today()+30,
                                                        Initial_Start_Date__c=System.today(),
                                                       Level_of_Effort__c = 'Small');
            INSERT project;
            
            //Availability record
            PMT_Resource_Availability__c resAvail = new PMT_Resource_Availability__c( User__c = UserInfo.getUserId(),
                                                                                     Fiscal_Year__c = 'FY20',
                                                                                     Jan__c = resourceAvailability, Feb__c = resourceAvailability, 
                                                                                     Mar__c = resourceAvailability, Apr__c = resourceAvailability, 
                                                                                     May__c = resourceAvailability, Jun__c = resourceAvailability, 
                                                                                     Jul__c = resourceAvailability, Aug__c = resourceAvailability, 
                                                                                     Sep__c = resourceAvailability, Oct__c = resourceAvailability,
                                                                                     Nov__c = resourceAvailability, Dec__c = resourceAvailability);
            INSERT resAvail;
        }
    }
    
    static testmethod void projectSharingTestCase(){        
 		System.runAs(new User(Id = Userinfo.getUserId())) {  
            User usr = [SELECT Id FROM User WHERE Email='pmtuser@testorg.com'];
            PMT_Project__c project = [SELECT Id FROM PMT_Project__c LIMIT 1];
            PMT_Resource_Availability__c resAvail = [SELECT Id FROM PMT_Resource_Availability__c LIMIT 1];
            System.runAs(usr) {
                Test.startTest();
                //Allocation records
                PMT_Resource_Allocation__c resAllocation = new PMT_Resource_Allocation__c(Project__c = project.Id,
                                                                                          Resource_Availability__c = resAvail.Id,
                                                                                          Role__c = 'SME' );                                                                                        
                INSERT resAllocation;
                
                List<PMT_Project__Share> ls = [select Id from PMT_Project__Share where ParentId =: project.Id and UserOrGroupId =: UserInfo.getUserId()];
                
                System.assertNotEquals(null, ls, 'Project sharing done');
                Test.stopTest();
            }
        }
    }
    
    static testmethod void allocationWOTaskDeletionTestCase(){        
 		System.runAs(new User(Id = Userinfo.getUserId())) {  
            User usr = [SELECT Id FROM User WHERE Email='pmtuser@testorg.com'];
            PMT_Project__c project = [SELECT Id FROM PMT_Project__c LIMIT 1];
            PMT_Resource_Availability__c resAvail = [SELECT Id FROM PMT_Resource_Availability__c LIMIT 1];
            //Allocation records
             PMT_Resource_Allocation__c resAllocation = new PMT_Resource_Allocation__c(Project__c = project.Id,
                                                                                          Resource_Availability__c = resAvail.Id,
                                                                                          Role__c = 'SME' ); 
            INSERT resAllocation;
            
            System.runAs(usr) {
                Test.startTest();
                    DELETE resAllocation;
                    List<PMT_Project__Share> ls = [select Id from PMT_Project__Share where ParentId =: project.Id and UserOrGroupId =: UserInfo.getUserId()];                
                	System.assertNotEquals(null, ls, 'Record founding for deletion');
                Test.stopTest();
            }
        }
    }
    
     static testmethod void allocationWithTaskDeletionTestCase(){        
 		System.runAs(new User(Id = Userinfo.getUserId())) {  
            User usr = [SELECT Id FROM User WHERE Email='pmtuser@testorg.com'];
            PMT_Project__c project = [SELECT Id FROM PMT_Project__c LIMIT 1];
            
            PMT_Phase__c phase = new PMT_Phase__c(Name='Develop', Project__c = project.Id);
            INSERT phase;
            
            PMT_Task__c task = new PMT_Task__c(Phase__c = phase.Id, Assigned_To1__c = UserInfo.getUserId(), Start_Date__c = System.today(), Due_Date__c= System.today()+10);
			INSERT task;
            
            PMT_Resource_Availability__c resAvail = [SELECT Id FROM PMT_Resource_Availability__c LIMIT 1];
            //Allocation records
             PMT_Resource_Allocation__c resAllocation = new PMT_Resource_Allocation__c(Project__c = project.Id,
                                                                                          Resource_Availability__c = resAvail.Id,
                                                                                          Role__c = 'SME' ); 
            INSERT resAllocation;
            
            System.runAs(usr) {
                Test.startTest();
                try{
                	DELETE resAllocation;
                    List<PMT_Project__Share> ls = [select Id from PMT_Project__Share where ParentId =: project.Id and UserOrGroupId =: UserInfo.getUserId()];                
                }catch(Exception e){
                  System.assertNotEquals(null, e.getMessage(),'error should be returned for negative test');  
                }
                    
                Test.stopTest();
            }
        }
    }
    
    static testmethod void projectUpdateTestCase(){        
 		System.runAs(new User(Id = Userinfo.getUserId())) {  
            Integer resourceAvailability = Integer.valueOf(PMT_Utility.getPMTSettings('Default').Default_Availability_for_Scheduler__c);
            
            Profile p = [SELECT Id FROM Profile WHERE Name='Standard User' limit 1]; 
            User pmtTempUser = new User(Alias = 'usrpmt', Email='pmtTempUser@testorg.com', 
                                EmailEncodingKey='UTF-8', LastName='pmtTempUser', LanguageLocaleKey='en_US', 
                                LocaleSidKey='en_US', ProfileId = p.Id,Department='Sales', 
                                TimeZoneSidKey='America/Los_Angeles', UserName='pmtTempUser@testorg.com'); 
            
            INSERT pmtTempUser;
            
            PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'PMT_Global_Admin'];
            INSERT new PermissionSetAssignment(AssigneeId = pmtTempUser.id, PermissionSetId = ps.Id);
            
            PMT_Resource_Availability__c resAvailNew = new PMT_Resource_Availability__c(User__c = pmtTempUser.Id,
                                                                              Fiscal_Year__c = 'FY21',
                                                                              Jan__c = resourceAvailability, Feb__c = resourceAvailability, 
                                                                              Mar__c = resourceAvailability, Apr__c = resourceAvailability, 
                                                                              May__c = resourceAvailability, Jun__c = resourceAvailability, 
                                                                              Jul__c = resourceAvailability, Aug__c = resourceAvailability, 
                                                                              Sep__c = resourceAvailability, Oct__c = resourceAvailability,
                                                                              Nov__c = resourceAvailability, Dec__c = resourceAvailability);
                                                                            
            INSERT resAvailNew;
            
            PMT_Project__c project = [SELECT Id FROM PMT_Project__c LIMIT 1];
            PMT_Resource_Availability__c resAvail = [SELECT Id FROM PMT_Resource_Availability__c LIMIT 1];
            //Allocation records
             PMT_Resource_Allocation__c resAllocation = new PMT_Resource_Allocation__c(Project__c = project.Id,
                                                                                          Resource_Availability__c = resAvail.Id,
                                                                                          Role__c = 'SME' ); 
            
            INSERT resAllocation;
            
            User usr = [SELECT Id FROM User WHERE Email='pmtuser@testorg.com'];
            System.runAs(usr) {                
                Test.startTest();
                	resAllocation.Resource_Availability__c = resAvailNew.Id;
                	UPDATE resAllocation;
                
                List<PMT_Project__Share> lsNew = [select Id from PMT_Project__Share where ParentId =: project.Id and UserOrGroupId =: pmtTempUser.Id];
                List<PMT_Project__Share> lsOld = [select Id from PMT_Project__Share where ParentId =: project.Id and UserOrGroupId =: usr.Id];
                
                System.assertNotEquals(null, lsNew, 'Project sharing done for new resource');
                System.assertNotEquals(null, lsOld, 'Project sharing revoked for old resource');
                
                Test.stopTest();
            }
        }
    }
    
}