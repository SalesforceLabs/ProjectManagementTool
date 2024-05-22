/*************************************************
* Name: PMT_ResourceManagementCtrl
* Description: Lightning component helper for resource allocation
* Author : Salesforce.com
* Used By : pmtResourceManagementTab (LWC),
            PMT_MassResourceAllocationContainer.cmp, 
            PMT_MassResourceAllocation.cmp, 
            PMT_ResourceAvailabilityDataTable.cmp
* Test class : PMT_Testcoverage(93%)
* ***********************************************/
public with sharing class PMT_ResourceManagementCtrl {
    
    Public class ResourceDetail
    {
        @AuraEnabled
        public List<PMT_Resource_Availability__c> ResourceAvailabilities; //All the available resources
        @AuraEnabled
        public List<PMT_Resource_Allocation__c> ResourceAllocations; //Allocations for the project
        @AuraEnabled
        public List<PMT_Resource_Availability__c> dummyAvailabilities; //dummy availabilities with no user
        @AuraEnabled
        public List<String> roles;  //Roles for picklist
        @AuraEnabled
        public Boolean isCreatable;
        @AuraEnabled
        public Integer fiscalYearOffset;
    }
    
    /*****************************************************************
    * Method Name : getResourceDetailsWrapper
    * Params : project record
    * Retrun : ResourceDetailWrapper
    * Description : Get data using SOQL and transform to wrapper
    * **************************************************************/
    @AuraEnabled
    public static ResourceDetail getResourceDetailsWrapper(PMT_Project__c project)
    {
        try{                
            //Generate wrapper
            ResourceDetail resource = new ResourceDetail();
            
            List<String> lstOfAllocationFields = new List<String>{'Id','Role__c','Resource_Availability__c', 'Jan__c','Feb__c','Mar__c','Apr__c','May__c','Jun__c','Jul__c','Aug__c','Sep__c','Oct__c','Nov__c','Dec__c','Fiscal_Year__c','Project__c'};
                
                List<String> lstOfAvailabilityFields = new List<String>{'User__c','Feb_Remaining__c','Mar_Remaining__c','Apr_Remaining__c','May_Remaining__c','Jun_Remaining__c','Jul_Remaining__c','Aug_Remaining__c','Sep_Remaining__c','Oct_Remaining__c','Nov_Remaining__c','Dec_Remaining__c', 'Jan_Remaining__c','Id','fiscal_year__c', 'Start_Date__c', 'End_Date__c'};
                    
                    List<String> lstOfUsersFields = new List<String>{'Name','SmallPhotoURL','ManagerId','IsActive'};
                        List<String> lstOfProjectFields = new List<String>{'Start_Fiscal_Year__c','End_Fiscal_Year__c','Deadline_formula__c','Kickoff_formula__c'};
            
                            if(PMT_Utility.validateCRUD('PMT_Resource_Allocation__c', lstOfAllocationFields, 'isAccessible') && 
                               PMT_Utility.validateCRUD('PMT_Resource_Availability__c', lstOfAvailabilityFields, 'isAccessible') && 
                               PMT_Utility.validateCRUD('User', lstOfUsersFields, 'isAccessible') && 
                               PMT_Utility.validateCRUD('PMT_Project__c', lstOfProjectFields, 'isAccessible')){
                                   
                                   resource.ResourceAllocations = getResourceAllocation(project.Id);
                                   
                                   //calculate fiscal years using start and end
                                   Integer startFiscal = Integer.valueOf(project.Start_Fiscal_Year__c.mid(2,2));
                                   Integer endFiscal = Integer.valueOf(project.End_Fiscal_Year__c.mid(2,2));
                                   Integer difference = endFiscal - startFiscal;
                                   List<String> years = new List<String>();
                                   for(integer i=0;i<=difference;i++){
                                       years.add('FY' + (startFiscal+i));
                                   }
                                   
                                   resource.ResourceAvailabilities = getAvailibility(years, project);
                                   resource.dummyAvailabilities = getDummyAvailabilities(years, project);
                                   resource.roles = getRolesPickVals();
                                   resource.isCreatable = Schema.sObjectType.PMT_Resource_Allocation__c.isCreateable();
                                   resource.fiscalYearOffset = Integer.valueOf(getPMTSettings().Start_Month_of_Fiscal_Year__c);
                                   return resource;
                               }else{
                                   throw new AuraHandledException('Access restricted. Please contact system administrator.');          
                               }
        }
        catch(Exception e){
            system.debug(e.getStackTraceString());
            List<String> lstOfLogFields = new List<String>{'Apex_Class__c', 'Error_Message__c','Method_Name__c'};
                if(PMT_Utility.validateCRUD('PMT_Error_Log__c', lstOfLogFields, 'isCreatable')){
                    INSERT new PMT_Error_Log__c(Apex_Class__c='PMT_ResourceManagementCtrl', Error_Message__c = e.getMessage() , Method_Name__c = 'getResourceDetailsWrapper');
                }
            return null;
        }
    }
    
    /*****************************************************************
    * Method Name : upsertDeleteAllocation
    * Params : List of allocations to save, list of allocations to delete
    * Retrun : n/a
    * Description : upsert/delete the allocation records
    * **************************************************************/
    @AuraEnabled
    public static void upsertDeleteAllocation(List<SObject> allocationsToSave, List<SObject> allocationsToDelete, PMT_Project__c project){
        //Calling util method to check CRUD
        if(PMT_Utility.validateCRUD('PMT_Resource_Allocation__c', null, 'isCreateable') && PMT_Utility.validateCRUD('PMT_Resource_Allocation__c', null, 'isUpdateable')){   
            //check if anything to upsert
            if(allocationsToSave!=null){
                List<PMT_Resource_Allocation__c> allocations = new List<PMT_Resource_Allocation__c>();
                allocations.addAll((List<PMT_Resource_Allocation__c>)allocationsToSave);
                try{
                    UPSERT allocations;
                }catch(Exception e){
                    List<String> lstOfLogFields = new List<String>{'Apex_Class__c', 'Error_Message__c','Method_Name__c'};
                        if(PMT_Utility.validateCRUD('PMT_Error_Log__c', lstOfLogFields, 'isCreatable')){
                            INSERT new PMT_Error_Log__c(Apex_Class__c='PMT_ResourceManagementCtrl', Error_Message__c = e.getMessage() , Method_Name__c = 'upsertDeleteAllocation');
                        }
                }
            }
        }else{
            throw new AuraHandledException('You don\'t have access to update/Insert PMT resource allocation. Please contact system administrator.');            
        }
        
        //Calling util method to check CRUD
        if(PMT_Utility.validateCRUD('PMT_Resource_Allocation__c', null, 'isDeletable') ){       
            //Check if anything to delete
            if(allocationsToDelete!=null){
                DELETE allocationsToDelete;
            }
        }else{
            throw new AuraHandledException('You don\'t have access to delete PMT resource allocation. Please contact system administrator.');       
        }       
        
    }
    
    /*****************************************************************
    * Method Name : getRolesPickVals
    * Params : n/a
    * Retrun : List of picklist values
    * Description : Get picklist values of role from resource allocations
    * **************************************************************/
    private static List<String> getRolesPickVals(){
        //call resusable method
        return PMT_TaskandPhaseManagementCtrl.getPicklistvalues('PMT_Resource_Allocation__c', 'Role__c', false);
    }
    
    /*****************************************************************
    * Method Name : getResourceAllocation
    * Params : project record Id
    * Retrun : List of resource allocations
    * Description : Get allocations using SOQL and transform to wrapper
    * **************************************************************/
    private static List<PMT_Resource_Allocation__c> getResourceAllocation(Id projectId)
    {
        List<PMT_Resource_Allocation__c> allocations = new List<PMT_Resource_Allocation__c>();       
        allocations = [select id,Role__c,Resource_Availability__r.User__c,Resource_Availability__r.is_Dummy_Availability__c,
                       Resource_Availability__r.User__r.Name,Resource_Availability__r.User_Id__c, Resource_Availability__r.User__r.SmallPhotoURL,
                       Resource_Availability__r.User__r.ManagerId,Project__r.Start_Fiscal_Year__c,
                       Project__r.End_Fiscal_Year__c,Project__r.Deadline_formula__c,Project__r.Kickoff_formula__c,
                       Jan__c,Feb__c,Mar__c,Apr__c,May__c,Jun__c,Jul__c,Aug__c,Sep__c,Oct__c,
                       Nov__c,Dec__c,Fiscal_Year__c
                       from PMT_Resource_Allocation__c where Project__c=:projectId order by Role__c desc limit :limits.getLimitQueryRows()];
        
        return allocations;
    }
    
    
    /*****************************************************************
    * Method Name : getAvailibility
    * Params : project record
    * Retrun : list of reousrce availability
    * Description : Get availabilities using SOQL and transform to wrapper
    * **************************************************************/
    private static List<PMT_Resource_Availability__c> getAvailibility(List<String> years, PMT_Project__c project)
    {
        List<PMT_Resource_Availability__c> ls = new List<PMT_Resource_Availability__c>();
        
        ls = [select User_Id__c,is_Dummy_Availability__c, Feb_Remaining__c,Mar_Remaining__c,Apr_Remaining__c,
              May_Remaining__c,Jun_Remaining__c,Jul_Remaining__c,
              Aug_Remaining__c,Sep_Remaining__c,Oct_Remaining__c,
              Nov_Remaining__c,Dec_Remaining__c, Jan_Remaining__c,
              id,User__c, User__r.name,User__r.SmallPhotoUrl,User__r.ManagerId,
              fiscal_year__c, Start_Date__c, End_Date__c from PMT_Resource_Availability__c
              where fiscal_year__c in :years and User_Name__c!='' and User_IsActive__c = true order by User_Name__c limit :limits.getLimitQueryRows()];
        return ls;
    }
    
    /*****************************************************************
    * Method Name : getDummyAvailabilities
    * Params : project record
    * Retrun : list of availabilities with no user
    * Description : Get availabilities using SOQL and transform to wrapper
    * **************************************************************/
    private static List<PMT_Resource_Availability__c> getDummyAvailabilities(List<String> years, PMT_Project__c project)
    {
        List<PMT_Resource_Availability__c> dummyAvailablities = new List<PMT_Resource_Availability__c>();
        
        dummyAvailablities = [select Id,User__c,User__r.Name,User__r.SmallPhotoUrl,User__r.Id, 
                              Fiscal_Year__c from PMT_Resource_Availability__c
                              WHERE User__c = '' AND Fiscal_Year__c IN: years limit :limits.getLimitQueryRows()];
        
        return dummyAvailablities;
    }
    
    /*************************************************
    * Name: AvailabilityWrapper
    * Description: Wrapper for Avaialbility and whether records are editble. It is used in PMT_ResourceAvailabilityDataTable.cmp
    * ***********************************************/
    public class AvailabilityWrapper{
        @AuraEnabled
        public boolean isResourcePlanner;
        @AuraEnabled
        public List<PMT_Resource_Allocation__c> resourceAvailabilities;
    }
    
    /************************************************
    * Method Name: getAllocationsForResource 
    * Description: Get allocations for resource. It is used in PMT_ResourceAvailabilityDataTable.cmp
    * Parameters : resourceid, fiscalYear
    * Return Values: list of allocation
    * ***********************************************/    
    @AuraEnabled
    public static AvailabilityWrapper getAllocationsForResource(Id resourceId, String fiscalYear)
    {
        List<String> lstOfAllocationFields = new List<String>{'Id','Name','Role__c','Project_Owner__c','Resource_Availability__c','Project__c','Project_Name__c','Fiscal_Year__c','Resource_Name__c','Feb__c','Mar__c','Apr__c','May__c','Jun__c','Jul__c','Aug__c','Sep__c','Oct__c','Nov__c','Dec__c','Jan__c'};
            //Calling util method to check CRUD
            if(PMT_Utility.validateCRUD('PMT_Resource_Allocation__c', lstOfAllocationFields, 'isAccessible')){
                AvailabilityWrapper wrapper = new AvailabilityWrapper();
                wrapper.resourceAvailabilities = [SELECT id,Name,Role__c,Project_Owner__c,Resource_Availability__c,Project__c,Project_Name__c,  Fiscal_Year__c,Resource_Name__c,Feb__c,Mar__c,Apr__c,May__c,Jun__c,Jul__c,Aug__c,Sep__c,Oct__c,Nov__c,Dec__c,Jan__c FROM PMT_Resource_Allocation__c WHERE Resource_Availability__c=:resourceId And Fiscal_Year__c=:fiscalYear order by Project_Name__c ASC, Name ASC limit: limits.getLimitQueryRows()];                                    
                
                wrapper.isResourcePlanner = Schema.sObjectType.PMT_Resource_Availability__c.isCreateable();
                return wrapper;
            }else{
                throw new AuraHandledException('You don\'t have access to PMT resource allocations. Please contact system administrator.');
            }   
    }
    
    /*************************************************
    * Method Name: updateAllocations
    * Description: Update allocations. It is used in PMT_ResourceAvailabilityDataTable.cmp
    * Parameters : allocations
    * Return Values: list of allocations
    * ***********************************************/
    @AuraEnabled
    public static List<PMT_Resource_Allocation__c> updateAllocations(List<PMT_Resource_Allocation__c> allocations){
        //Calling util method to check CRUD
        if(PMT_Utility.validateCRUD('PMT_Resource_Allocation__c', null, 'isUpdateable')){   
            try {               
                UPDATE allocations;
                return allocations;
            } catch(Exception e) {
                //Calling util method to check CRUD
                List<String> lstOfLogFields = new List<String>{'Apex_Class__c', 'Error_Message__c','Method_Name__c'};
                    if(PMT_Utility.validateCRUD('PMT_Error_Log__c', lstOfLogFields, 'isCreatable')){
                        INSERT new PMT_Error_Log__c(Apex_Class__c='PMT_ResourceManagementCtrl', Error_Message__c = e.getMessage() , Method_Name__c = 'updateAllocations');
                    }
                return null;
            }
        }else{
            throw new AuraHandledException('You don\'t have access to update PMT resource allocations. Please contact system administrator.');
        }   
    }  
    
    /*************************************************
    * Method Name: deleteRecord
    * Description: delete records. It is used in PMT_ResourceAvailabilityDataTable.cmp
    * Parameters : recordToDelete
    * Return Values: null
    * ***********************************************/
    @auraEnabled
    public static Boolean deleteRecord(sObject recordToDelete) {
        //Calling util method to check CRUD
        if(PMT_Utility.validateCRUD('PMT_Resource_Allocation__c', null, 'isDeletable')){    
            try {
                delete recordToDelete;
                return true;
            } catch(Exception e) {
                //Calling util method to check CRUD
                List<String> lstOfLogFields = new List<String>{'Apex_Class__c', 'Error_Message__c','Method_Name__c'};
                    if(PMT_Utility.validateCRUD('PMT_Error_Log__c', lstOfLogFields, 'isCreatable')){
                        INSERT new PMT_Error_Log__c(Apex_Class__c='PMT_ResourceManagementCtrl', Error_Message__c = e.getMessage() , Method_Name__c = 'deleteRecord');
                    }
                return false;
            }
        }else{
            throw new AuraHandledException('You don\'t have access to delete PMT resource allocations. Please contact system administrator.');
        }   
    }
    
    /*************************************************
    * Method Name: getPMTSettings
    * Description: gets the settings for the PMT. It is used in PMT_ResourceAvailibilityDisplay.cmp
    * Parameters : N/A
    * Return Values: PMT_Setting__mdt
    * ***********************************************/
    @AuraEnabled
    public static PMT_Setting__mdt getPMTSettings() {
        return PMT_Utility.getPMTSettings('Default');
    }
    
    /************************** RESOURCE MANAGEMENT TAB **********************************/
    /*************************************************
    * Method Name: getFilters
    * Description: get the filter Values to be displayed in the picklists
    * Parameters : n/a
    * Return Values: list of list of values
    * ***********************************************/
    @AuraEnabled(cacheable=true)
    public static List<List<string>> getFilters(){
        List<String> lstOfAvailabilityFields = new List<String>{'User__c','Fiscal_Year__c','User_IsActive__c','User_Name__c'};
        List<String> lstOfUserFields = new List<String>{'Department'};
        if(PMT_Utility.validateCRUD('PMT_Resource_Availability__c', lstOfAvailabilityFields, 'isAccessible') && PMT_Utility.validateCRUD('User', lstOfUserFields, 'isAccessible')){
            List<List<string>> filters = new List<List<string>>();
            //PMT Department Values
            Set<String> picklistPMTDepartments = new Set<string>();
            //Fiscal Years
            Set<string> fiscalYears = new Set<string>();
            //Aggregate query to get all the utilized values for regions, fiscal years and departments from availability
            for(AggregateResult ar : [select count(Id),Fiscal_Year__c year,User__r.Department dept from PMT_Resource_Availability__c group by Fiscal_Year__c, User__r.Department limit :limits.getLimitQueryRows()]){
                fiscalYears.add((String)ar.get('year'));
                picklistPMTDepartments.add((String)ar.get('dept'));
            }
            filters.add(new List<string>(picklistPMTDepartments));
            filters.add(new List<string>(fiscalYears));
            filters.add(new List<string>{String.valueOf(getPMTSettings().Start_Month_of_Fiscal_Year__c)});
            return filters;
        }
        else{
            throw new AuraHandledException('You don\'t have necessary access to PMT resource allocations. Please contact system administrator.');
        }
    }
    
    /*************************************************
    * Method Name: getResourceAllocations
    * Description: get the resource availabilities and allocations based on the values selected
    * Parameters : fiscal year, department, manager id, user id and project id
    * Return Values: wrapper with allocation and availabilities
    * ***********************************************/
    @AuraEnabled(cacheable=true)
    public static ResourceDataWrapper getResourceAllocations(String fiscalYear, String selectedDept, String selectedManagerId, String selectedUserId, String selectedProjectId) {
        List<String> lstOfAllocationFields = new List<String>{'Id','Name','Role__c','Project_Owner__c','Resource_Availability__c','Project__c','Project_Name__c','Fiscal_Year__c','Resource_Name__c','Feb__c','Mar__c','Apr__c','May__c','Jun__c','Jul__c','Aug__c','Sep__c','Oct__c','Nov__c','Dec__c','Jan__c'};
        List<String> lstOfAvailabilityFields = new List<String>{'User__c','Feb_Remaining__c','Mar_Remaining__c','Apr_Remaining__c','May_Remaining__c','Jun_Remaining__c','Jul_Remaining__c','Aug_Remaining__c','Sep_Remaining__c','Oct_Remaining__c','Nov_Remaining__c','Dec_Remaining__c', 'Jan_Remaining__c','Id','fiscal_year__c', 'Start_Date__c', 'End_Date__c'};
        //Calling util method to check CRUD
        if(PMT_Utility.validateCRUD('PMT_Resource_Availability__c', lstOfAvailabilityFields, 'isAccessible') && PMT_Utility.validateCRUD('PMT_Resource_Allocation__c', lstOfAllocationFields, 'isAccessible')){
            FINAL integer queryRowLimit = limits.getLimitQueryRows();
            FINAL string dummyAllocationUserName = '';
            ResourceDataWrapper wrapper = new ResourceDataWrapper();
            
            String query = 'select Id, Apr_Allocation__c, Aug_Allocation__c, Dec_Allocation__c, Feb_Allocation__c, Jan_Allocation__c, Jul_Allocation__c, Jun_Allocation__c, Mar_Allocation__c, May_Allocation__c, Nov_Allocation__c, Oct_Allocation__c,';
            query += 'Sep_Allocation__c, Apr_Remaining__c, Aug_Remaining__c, Dec_Remaining__c, Feb_Remaining__c, Jan_Remaining__c, Jul_Remaining__c, Jun_Remaining__c, Mar_Remaining__c, May_Remaining__c, Nov_Remaining__c, Oct_Remaining__c,';
            query += 'Sep_Remaining__c, Fiscal_Year__c, User_Name__c, Apr__c, Aug__c, Dec__c, Feb__c, Jan__c, Jul__c, Jun__c, Mar__c, May__c, Nov__c, Oct__c, Sep__c, Start_Date__c, End_Date__c,User_Department__c from PMT_Resource_Availability__c where ';
            query += 'User__r.IsActive=true and User__r.Name!=:dummyAllocationUserName and Fiscal_Year__c=:fiscalYear ';
            if(String.isNotEmpty(selectedManagerId)){
                query += 'and User__r.ManagerId = :selectedManagerId ';
            }
            if(String.isNotEmpty(selectedUserId)){
                query += 'and User__c = :selectedUserId ';
            }
            
            query += 'and User_Department__c = :selectedDept ';
            query += 'with security_enforced order by Name limit :queryRowLimit';
            //Esacpe single quotes for SOQL Injection
            query = String.escapeSingleQuotes(query);
            wrapper.resourceAvailabilities = database.query(query);
            
            query = 'select id,Role__c,Resource_Availability__r.User__c, Project_Name__c,Resource_Availability__c,';
            query += 'Project__c,Jan__c,Feb__c,Mar__c,Apr__c,May__c,Jun__c,Jul__c,Aug__c,Sep__c,Oct__c,';
            query += 'Nov__c,Dec__c,Fiscal_Year__c,User_Name__c from PMT_Resource_Allocation__c where User_Department__c = :selectedDept and Fiscal_Year__c=:fiscalYear ';
            if(String.isNotEmpty(selectedManagerId)){
                query += 'and Resource_Availability__r.User__r.ManagerId = :selectedManagerId ';
            }
            if(String.isNotEmpty(selectedUserId)){
                query += 'and Resource_Availability__r.User__c = :selectedUserId ';
            }
            if(String.isNotEmpty(selectedProjectId)){
                query += 'and Project__c = :selectedProjectId ';
            }
            query += 'with security_enforced order by Name limit :queryRowLimit';
            //Esacpe single quotes for SOQL Injection
            query = String.escapeSingleQuotes(query);
            wrapper.resourceAllocations = database.query(query);
            return wrapper;
        }
        else{
            throw new AuraHandledException('You don\'t have access to PMT resource allocations. Please contact system administrator.');
        }
    }
    
    /*
     * Name : ResourceDataWrapper
     * Description : Wrapper class used by the resource management tab
     * */
    public class ResourceDataWrapper{
        @AuraEnabled
        public List<PMT_Resource_Availability__c> resourceAvailabilities;
        @AuraEnabled
        public List<PMT_Resource_Allocation__c> resourceAllocations;
    }
}