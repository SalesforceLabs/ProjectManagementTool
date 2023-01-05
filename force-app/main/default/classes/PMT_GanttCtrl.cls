/******************************************************************************************************
 * Name: PMT_GanttCtrl.apxc
 * Test class : PMT_GanttCtrlTest (87%)
 * Used by: Used by LWC pmtGantt.cmp & pmtGanttdata.cmp
 * Description : Class to get required filters and the data for PMT Gantt LWC components
 * Version     : 56 
 ******************************************************************************************************/

public with sharing class PMT_GanttCtrl {

    /***********************************************************************************************************************************************************************************************************************************
     * Method Name: fetchGanttData
     * Description: It queries data as per filters provided to show on gantt chart
     * Parameter : It accepts filters which is selected by user like project Progress, project Health. system Impacted. project Category, program and projectId if chart is displayed on specific project record page
     * Returns : String
     ***********************************************************************************************************************************************************************************************************************************/
     @AuraEnabled(cacheable = true)
    public static List<GanttDataWrapper> fetchGanttData(Integer slotSize, Date startTime, String projectId, String projectProgress, String projectHealth, String systemImpacted, String projectCategory, String program) {
        List<GanttDataWrapper> lstOfGanttDataWrapper = new List<GanttDataWrapper>();
        List<Id> projIds = new List<Id>();
        Id loginUserId = UserInfo.getUserId();
        Set<Id> setOfProjOwners = new Set<Id>();
        Set<Id> followIds = new Set<Id>();
        Set<Id> setOfTasksAssignedToMe = new Set<Id>();
        List<GanttDataWrapper> lstOfWrapper = new List<GanttDataWrapper>();
        Map<Id, List<PMT_Phase__c>> mapOfMilestoneToPhases = new Map<Id, List < PMT_Phase__c>>();
        Map<Id, List<PMT_Task__c>> mapOfPhaseToTasks = new Map<Id, List<PMT_Task__c>>();

        List<String> lstOfprojectFields = new List<String> {'Id', 'OwnerId', 'Name', 'Kickoff_formula__c', 'Duration__c', 'Deadline_formula__c', 'Project_Status__c', 'Project_Health__c', 'Health_Icon__c', 'Project_Category__c', 'Program_Text__c', 'SystemsImpacted__c'};

        slotSize = Integer.valueOf(slotSize);
        Date startDate = startTime;
        

        if (PMT_Utility.validateCRUD('PMT_Project__c', lstOfprojectFields, 'isAccessible')) {

            List<PMT_Project__c> projects = getProjects(projectId, projectProgress, projectHealth, systemImpacted, projectCategory, program);

            if (projects != null && projects.size() != 0) {
                List < PMT_Project__c > projects_clone = projects.clone();
                projects.clear();
                Integer size = (projects_clone.size() > 1000) ? 1000 : projects_clone.size();

                for (Integer i = 0; i < size; i++) {
                    PMT_Project__c prj = projects_clone[i];
                    projects.add(prj);
                    projIds.add(prj.Id);
                    setOfProjOwners.add(prj.ownerId);
                }

                List<String> lstOfEntitySubscrFields = new List<String> {'Id', 'ParentId', 'SubscriberId'};
                    
                if (PMT_Utility.validateCRUD('EntitySubscription', lstOfEntitySubscrFields, 'isAccessible')) {
                    followIds = getFollowIds(projects);
                } else {
                    throw new AuraHandledException('Access restricted to check following project, please contact system administrator.');
                }

                // fetching PMT Phases
                List<String> lstOfPhaseFields = new List<String> {'Id', 'Name', 'Kickoff_formula__c', 'Duration__c', 'Deadline_formula__c', 'Health_Icon__c', 'Project__c'};

                if (PMT_Utility.validateCRUD('PMT_Phase__c', lstOfPhaseFields, 'isAccessible')) {
                    Map<Id, PMT_Phase__c> mapOfPhases = getPhases(projIds);

                    // fetching PMT Tasks
                    List<String> lstOfTaskFields = new List<String> {'Name', 'Start_Date__c', 'Due_Date__c', 'Duration__c', 'Percentage_Completion__c', 'Assigned_To1__c', 'Status__c', 'Phase__c', 'Is_Milestone__c'};

                    if (PMT_Utility.validateCRUD('PMT_Task__c', lstOfTaskFields, 'isAccessible')) {
                        Map<Id, PMT_Task__c> mapOfTasks = getTasks(mapOfPhases.keySet());
                        //Boolean isAssignedToMe = false;
                        for (PMT_Task__c tsk: mapOfTasks.values()) {
                            if (tsk.Assigned_To1__c == loginUserId) {
                                setOfTasksAssignedToMe.add(tsk.Id);
                                setOfTasksAssignedToMe.add(tsk.Phase__r.Id);
                                setOfTasksAssignedToMe.add(tsk.Phase__r.Project__r.Id);
                            }

                            if (mapOfPhaseToTasks.containsKey(tsk.Phase__c)) {
                                List<PMT_Task__c> lstOfTasks = mapOfPhaseToTasks.get(tsk.Phase__c);
                                lstOfTasks.add(tsk);
                                mapOfPhaseToTasks.put(tsk.Phase__c, lstOfTasks);
                            } else {
                                mapOfPhaseToTasks.put(tsk.Phase__c, new List<PMT_Task__c> {tsk});
                            }
                        }
                    } else {
                        throw new AuraHandledException('You don\'t have access to PMT task. Please contact system administartor.');
                    }

                    for (PMT_Phase__c phs: mapOfPhases.values()) {
                        if (mapOfMilestoneToPhases.containsKey(phs.Project__c)) {
                            List<PMT_Phase__c> lstOfPhases = mapOfMilestoneToPhases.get(phs.Project__c);
                            lstOfPhases.add(phs);
                            mapOfMilestoneToPhases.put(phs.Project__c, lstOfPhases);
                        } else {
                            mapOfMilestoneToPhases.put(phs.Project__c, new List<PMT_Phase__c>{phs}); 
                        }
                    }
                } else {
                    throw new AuraHandledException('You don\'t have access to PMT Phases or tasks. Please contact system administartor.');
                }

                for (PMT_Project__c prj: projects) {

                    GanttDataWrapper pmtProject = getGanttDataWrapper(slotSize, startDate, prj.Id, prj.Name, prj.Kickoff_formula__c, prj.Deadline_formula__c, prj.Duration__c, '', 'PMT_Project__c', prj.Health_Icon__c, (followIds.contains(prj.Id)) ? true : false, (setOfTasksAssignedToMe.contains(prj.Id)) ? true : false, (prj.OwnerId==loginUserId) ? true : false, formatDate(prj.Deadline_formula__c, 'dd-MM-yyyy'), false);

                    if (mapOfMilestoneToPhases.containsKey(prj.Id)) {
                        List<GanttDataWrapper> lstOfPhases = new List<GanttDataWrapper>();

                        for (PMT_Phase__c phs: mapOfMilestoneToPhases.get(prj.Id)) {
                            GanttDataWrapper pmtPhase = getGanttDataWrapper(slotSize, startDate, phs.Id, phs.Name, phs.Kickoff_formula__c, phs.Deadline_formula__c, phs.Duration__c, phs.Project__c, 'PMT_Phase__c', phs.Health_Icon__c, (followIds.contains(phs.Project__r.Id)) ? true : false, (setOfTasksAssignedToMe.contains(phs.Id)) ? true : false, (setOfProjOwners.contains(loginUserId)) ? true : false, null, false);

                            if (mapOfPhaseToTasks.containsKey(phs.Id)) {
                                List<GanttDataWrapper> lstOfTasks = new List<GanttDataWrapper>();

                                for (PMT_Task__c tsk: mapOfPhaseToTasks.get(phs.Id)) {
                                    GanttDataWrapper pmtTask = getGanttDataWrapper(slotSize, startDate, tsk.Id, tsk.Name, tsk.Start_Date__c, tsk.Due_Date__c, tsk.Duration__c, tsk.Phase__c, 'PMT_Task__c', tsk.Status_Icon__c, (followIds.contains(tsk.Phase__r.Project__r.Id)) ? true : false, (setOfTasksAssignedToMe.contains(tsk.Id)) ? true : false, (setOfProjOwners.contains(loginUserId)) ? true : false, null, tsk.Is_Milestone__c);
                                    pmtTask.lstOfChilds = new List<GanttDataWrapper>();
                                    lstOfTasks.add(pmtTask);
                                }
                                pmtPhase.lstOfChilds = lstOfTasks;
                            }
                            lstOfPhases.add(pmtPhase);
                        }
                        pmtProject.lstOfChilds = lstOfPhases;
                    }
                    lstOfWrapper.add(pmtProject);
                }
            }
        } else {
            throw new AuraHandledException('You don\'t have access to PMT Project. Please contact system administartor.');
        }
        return lstOfWrapper;
    }

    /****************************************************************************************************************************************
    * Method Name: GanttDataWrapper is a wrapper class
    * Description: It is used to form tasks list with pre-defined attributes which are going to use to show data on gantt chart
    *****************************************************************************************************************************************/
    public class GanttDataWrapper {
        @AuraEnabled
        public Id id {get;set;}
            
        @AuraEnabled
        public String text {get;set;}
            
        @AuraEnabled
        public Date start_date {get;set;}
            
        @AuraEnabled
        public Date end_date {get;set;}
        
        @AuraEnabled
        public String parent {get;set;}
            
        @AuraEnabled
        public Decimal duration {get;set;}
            
        @AuraEnabled
        public String objAPIName {get;set;}
        
        @AuraEnabled
        public String statusIcon {get;set;}

        @AuraEnabled
        public Boolean isFollow {get;set;}
            
        @AuraEnabled
        public Boolean isAssignedToMe {get;set;}
            
        @AuraEnabled
        public Boolean isMyProject {get;set;}
            
        @AuraEnabled
        public String deadline {get;set;}
        
        @AuraEnabled
        public Boolean isMilestone {get;set;}
            
        @AuraEnabled
        public Decimal left {get;set;}

        @AuraEnabled
        public Decimal right {get;set;}
            
        @AuraEnabled
        public List<GanttDataWrapper> lstOfChilds {get;set;}        
    }

    /*********************************************************************************************************************************************
     * Method Name: getGanttDataWrapper
     * Description: Method to form the response based on the parameters passed & calcudate the left & right value based on slotsize
     * Parameter : Mutilple parameters
     * Returns : GanttDataWrapper
     **********************************************************************************************************************************************/
    public static GanttDataWrapper getGanttDataWrapper(Integer slotSize, Date sDate, Id recId, String name, Date startDate, Date endDate, Decimal duration, String parentId, String objAPIName, String statusIcon, Boolean isFollow, Boolean isAssignedToMe, Boolean isMyProject, String prjDeadline, Boolean isMilestone) {
        try{
        GanttDataWrapper wrapperRecord = new GanttDataWrapper();
        wrapperRecord.id = recId;
        wrapperRecord.text = name;
        wrapperRecord.start_date = startDate;
        wrapperRecord.end_date = endDate;
        wrapperRecord.duration = duration;
        wrapperRecord.parent = parentId;
        wrapperRecord.objAPIName = objAPIName;
        wrapperRecord.statusIcon = statusIcon; 
        wrapperRecord.isFollow = isFollow;
        wrapperRecord.isAssignedToMe = isAssignedToMe;
        wrapperRecord.isMyProject = isMyProject;
        wrapperRecord.deadline = prjDeadline;
        wrapperRecord.isMilestone = isMilestone;

        Decimal leftW = slotSize;
        Decimal rightW = slotSize;

        if (slotSize == 92) {
            Date newStartDate;
            Date newEndDate;
            Decimal leftQtrs = 0;
            Decimal rightQtrs = 0;
            Date tempStart = sDate;
            tempStart = tempStart.addDays(1);
            sDate = sDate.addDays(1);

            for (Date tDate = tempStart.addMonths(3); tDate <= endDate; tDate = tDate.addMonths(3)) {
                if (tDate <= startDate) {
                    leftQtrs = leftQtrs + 1;

                    if (tDate == startDate) {
                        newStartDate = tDate.addDays(-1);
                    } else {
                        newStartDate = tDate;
                    }
                }
                rightQtrs = rightQtrs + 1;
                if (tDate == endDate) {
                    newEndDate = tDate.addDays(-1);
                } else {
                    newEndDate = tDate;
                }
            }
            
            if (newStartDate != null) {
                Decimal leftTotalDays = sDate.daysBetween(newStartDate);
                Decimal leftAvg = leftTotalDays / leftQtrs;
                leftW = leftAvg;
            } else {
                leftW = 91.4;
            }

            if (newEndDate != null) {
                Decimal rightTotalDays = sDate.daysBetween(newEndDate);
                Decimal rightAvg = rightTotalDays / rightQtrs;
                rightW = rightAvg;
            } else {
                rightW = 91.4;
            }
        }
        if(startDate!=null){
            Decimal leftV = Decimal.valueOf(sDate.daysBetween(startDate)) / leftW;
            wrapperRecord.left = leftV.round(System.RoundingMode.FLOOR);
        }
        if(endDate!=null){
            Decimal rightV = Decimal.valueOf(sDate.daysBetween(endDate)) / rightW;
            wrapperRecord.right = rightV.round(System.RoundingMode.FLOOR);
        }  

        return wrapperRecord;
        }catch (Exception e) {
            List<String> lstOfLogFields = new List<String> {'Apex_Class__c', 'Error_Message__c', 'Method_Name__c'};
            
            //Calling util method to check CRUD
            if (PMT_Utility.validateCRUD('PMT_Error_Log__c', lstOfLogFields, 'isCreatable')) {
                INSERT new PMT_Error_Log__c(Apex_Class__c = 'PMT_GanttCtrl', Error_Message__c = e.getMessage(), Method_Name__c = 'getGanttDataWrapper');
            }
            return new GanttDataWrapper();
        }        
    }

    /**********************************************************************
     * Method Name: formatDate
     * Description: It formats date to specific format
     * Parameter : Date and Format string
     * Returns : String
     **********************************************************************/
    private static String formatDate(Date d, String format) {
        if (d == null) {
            return null;
        }
        Datetime dt = Datetime.newInstance(d.year(), d.month(), d.day());
        return dt.format(format);
    }

    /********************************************************************************************************************************************
     * Method Name:getProjects
     * Description : Search for PMT projects with search filters
     * Parameter : Project Id, project Progress, project Health, systems Impacted, project Category and program to filter records
     * Returns : List of projects
     * ******************************************************************************************************************************************/
    private static List < PMT_Project__c > getProjects(String projectId, String projectProgress, String projectHealth, String systemImpacted, String projectCategory, String program) {
        
        String selectStr = '';
        selectStr = 'SELECT Id,OwnerId, Name, Kickoff_formula__c, Duration__c, Deadline_formula__c,' +
            '  Project_Status__c, Project_Health__c,Health_Icon__c,Project_Category__c,Program_Text__c,SystemsImpacted__c ';
        
        String fromStr = 'FROM PMT_Project__c';
        boolean isWhere = false;
        String whereStr = '';
        
        whereStr = ' WHERE isTemplate__c=false';
        if (projectId != null && projectId != '') {
            isWhere = true;
            whereStr = whereStr + ' AND Id=\'' + string.escapeSingleQuotes(projectId) + '\'';
            
        }
        
        if (projectProgress != null && projectProgress != 'All') {
            whereStr = whereStr + ' AND Project_Status__c=\'' + string.escapeSingleQuotes(projectProgress) + '\'';
        }
        
        if (projectHealth != null && projectHealth != '' && projectHealth != 'All') {
            
            whereStr = whereStr + ' AND Project_Health__c=\'' + string.escapeSingleQuotes(projectHealth) + '\'';
            
        }
        
        if (systemImpacted != null && systemImpacted != '' && !systemImpacted.contains('All')) {
            
            whereStr = whereStr + ' AND SystemsImpacted__c includes (\'' + string.escapeSingleQuotes(systemImpacted) + '\')';
            
        }
        
        if (projectCategory != null && projectCategory != '' && projectCategory != 'All') {
            
            whereStr = whereStr + ' AND Project_Category__c=\'' + string.escapeSingleQuotes(projectCategory) + '\'';
            
        }
        
        if (program != null && program != '' && program != 'All') {
            
            whereStr = whereStr + ' AND Program__c=\'' + string.escapeSingleQuotes(program) + '\'';
            
        }
        
        String orderByStr = 'ORDER BY Name, Kickoff_formula__c, Deadline_formula__c  ASC LIMIT 30';
        String query = selectStr + ' ' + fromStr + ' ' + whereStr + ' ' + orderByStr;
        return Database.query(query);
    }

    /*****************************************************************************************************************
     * Method Name:getPhases
     * Description : Search for PMT phases related to list of projects which is given as input parameter
     * Parameter : List of projects Id's
     * Returns : List of PMT Phases
     * ***************************************************************************************************************/
    private static Map<Id, PMT_Phase__c> getPhases(List<Id> lstOfProjIds) {
        Map<Id, PMT_Phase__c> mapOfPhases = new Map<Id, PMT_Phase__c>();

        for (PMT_Phase__c phaseRec: [SELECT Id, Name, Kickoff_formula__c, Duration__c, Project__c, Deadline_formula__c, Health_Icon__c, Project__r.Id FROM PMT_Phase__c WHERE Project__c IN: lstOfProjIds limit: limits.getLimitQueryRows()]) {
            mapOfPhases.put(phaseRec.Id, phaseRec);
        }

        return mapOfPhases;
    }

    /*********************************************************************************************************
     * Method Name:getTasks
     * Description : Search for PMT tasks related to set of phases which is given as input parameter
     * Parameter : Set of phase Id's
     * Returns : List of PMT tasks
     * *******************************************************************************************************/
    private static Map<Id, PMT_Task__c> getTasks(Set<Id> setOfPhaseIds) {
        Map<Id, PMT_Task__c> mapOftasks = new Map<Id, PMT_Task__c>();

        for (PMT_Task__c taskRec: [SELECT Id, Name, Start_Date__c, Duration__c, Phase__c, Due_Date__c, Status_Icon__c, Phase__r.Project__r.Id, Assigned_To1__c, Phase__r.Id, Is_Milestone__c FROM PMT_Task__c WHERE Phase__c IN: setOfPhaseIds limit: limits.getLimitQueryRows()]) {
            mapOftasks.put(taskRec.Id, taskRec);
        }

        return mapOftasks;
    }

    /**********************************************************************
     * Method Name: getFollowIds
     * Description: It sets default search options
     * Parameter : List of PMT projects
     * Returns : Set of follow up Id's
     **********************************************************************/
    private static Set<Id> getFollowIds(List < PMT_Project__c > projects) {
        Set<Id> proIds = new Set<Id>();

        for (PMT_Project__c p: projects) {
            proIds.add(p.Id);
        }

        Set<Id> followProjectId = new Set<Id>();

        List<EntitySubscription> eList = [SELECT Id, ParentId, SubscriberId FROM EntitySubscription WHERE ParentId IN: proIds AND SubscriberId =: UserInfo.getUserId() LIMIT 1000];

        for (EntitySubscription e: eList) {
            followProjectId.add(e.ParentId);
        }

        return followProjectId;
    }

    /**********************************************************************
     * Method Name: GanttFliterWrapper is wrapper class
     * Description: It is used to show filters on gantt page    
     **********************************************************************/
    public class GanttFliterWrapper {
        @AuraEnabled
        public List<Filter> prjhealth; // List of project health's available
        
        @AuraEnabled
        public List<Filter> prjcategory; // List of project categories available
        
        @AuraEnabled
        public List<Filter> sysimpacted; // List of values available for system's impacted on project
        
        @AuraEnabled
        public List<Filter> prjprogress; // List of project progress available
    }

    /***************************************************************************************
     * Method Name: Filter is wrapper class
     * Description: It is used for storing value and label of picklist values 
     ***************************************************************************************/
    public class Filter {
        @AuraEnabled
        public string label;

        @AuraEnabled
        public string value;

        public Filter(string label, string value) {
            this.label = label;
            this.value = value;
        }
    }

    /******************************************************************************************************
     * Method Name: getGanttFilters
     * Description: It creates fliters to show on gantt chart as per values available on object fields
     * Parameter : NA
     * Returns : GanttFliterWrapper wrapper instance
     ******************************************************************************************************/
    @AuraEnabled(cacheable = true)
    public static GanttFliterWrapper getGanttFilters() {
        try {
            List<String> lstOfprojectFields = new List<String> {'Project_Health__c', 'Project_Category__c', 'SystemsImpacted__c', 'Project_Status__c'};
                        
            if (PMT_Utility.validateCRUD('PMT_Project__c', lstOfprojectFields, 'isAccessible')) {

                List<Filter> prjhealth = new List<Filter>();
                Map<String, String> mapOfHealthValues = PMT_Utility.getPicklistValues('PMT_Project__c', 'Project_Health__c');

                for (String key: mapOfHealthValues.keySet()) {
                    prjhealth.add(new Filter(key, mapOfHealthValues.get(key)));
                }

                List<Filter> prjcategory = new List<Filter>();
                Map<String, String> mapOfCategoryValues = PMT_Utility.getPicklistValues('PMT_Project__c', 'Project_Category__c');

                for (String key: mapOfCategoryValues.keySet()) {
                    prjcategory.add(new Filter(key, mapOfCategoryValues.get(key)));
                }

                List<Filter> sysimpacted = new List<Filter>();
                Map<String, String> mapOfSystemValues = PMT_Utility.getPicklistValues('PMT_Project__c', 'SystemsImpacted__c');

                for (String key: mapOfSystemValues.keySet()) {
                    sysimpacted.add(new Filter(key, mapOfSystemValues.get(key)));
                }

                List<Filter> prjprogress = new List<Filter>();
                Map<String, String> mapOfProgressValues = PMT_Utility.getPicklistValues('PMT_Project__c', 'Project_Status__c');

                for (String key: mapOfProgressValues.keySet()) {
                    prjprogress.add(new Filter(key, mapOfProgressValues.get(key)));
                }

                GanttFliterWrapper filter = new GanttFliterWrapper();
                filter.prjhealth = prjhealth;
                filter.prjcategory = prjcategory;
                filter.sysimpacted = sysimpacted;
                filter.prjprogress = prjprogress;

                return filter;
            } else {
                throw new AuraHandledException('You don\'t have access to PMT Project filters. Please contact system administartor.');
            }
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    /************************************************************************************************
     * Method Name: saveTask
     * Description: It Updates PMT task start date and due date as updated on gantt chart
     * Parameter : PMT Task Id, startDate and endDate
     * Returns : String message
     ************************************************************************************************/
    @AuraEnabled(cacheable = false)
    public static string saveTask(String taskId, Date startDate, Date endDate) {
        try {
            List<String> lstOftasksFields = new List<String> {'Id', 'Start_Date__c', 'Due_Date__c'};
            Id taskRecId = Id.valueOf(taskId);

            if (PMT_Utility.validateCRUD('PMT_Task__c', lstOftasksFields, 'isAccessible')) {
                PMT_Task__c task = new PMT_Task__c(Id = taskRecId, Start_Date__c = startDate, Due_Date__c = endDate);

                if (PMT_Utility.validateCRUD('PMT_Task__c', null, 'isUpdateable')) {
                    update task;
                    return 'Task updated successfully.';
                } else {
                    throw new AuraHandledException('You don\'t have access to update PMT Task. Please contact system administartor.');
                }
            } else {
                throw new AuraHandledException('You don\'t have access to PMT task. Please contact system administartor.');
            }
        } catch (Exception e) {
            List<String> lstOfLogFields = new List<String> {'Apex_Class__c', 'Error_Message__c', 'Method_Name__c'};
            
            //Calling util method to check CRUD
            if (PMT_Utility.validateCRUD('PMT_Error_Log__c', lstOfLogFields, 'isCreatable')) {
                INSERT new PMT_Error_Log__c(Apex_Class__c = 'PMT_GanttCtrl', Error_Message__c = e.getMessage(), Method_Name__c = 'updateTask');
            }
            throw new AuraHandledException(e.getMessage());
        }
    }
}