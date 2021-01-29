({
    //Component initialization
    doInit : function(component, event, helper) {
        //Get dynamic actions buttons
        var actions = helper.getRowActions.bind(this, component)
        
        //Define columns table
        component.set('v.columns', [
            {label: 'Phase',fieldName: 'Phase', editable:false, type: 'text', sortable:true,},
            {label: 'Name',fieldName: 'Name', editable:true, type: 'text', sortable:true},
            {label: 'Status', fieldName: 'Status__c', editable:false, type: 'text', initialWidth: 160, sortable:true, 
             cellAttributes:{ iconName: { fieldName: 'Status_Icon_Name__c' }, iconPosition: 'left', iconAlternativeText: 'Status' }},
            {label: '% Compl.', fieldName: 'Percentage_Completion__c', editable:true, type: 'number',step:5, initialWidth: 90},
            {label: 'Start Date', fieldName: 'Start_Date__c', editable:true, type: 'date-local', initialWidth: 130, sortable:true,
             typeAttributes: {year: 'numeric', month: 'short', day: 'numeric'} },
            {label: 'Due Date', fieldName: 'Due_Date__c', editable:true, type: 'date-local', initialWidth: 130, sortable:true,
             typeAttributes: {year: 'numeric', month: 'short', day: 'numeric'} },
            {label: 'Assigned To', fieldName: 'AssignedTo', editable:false, type: 'text', sortable:true, initialWidth: 160},
            {label: 'Description', fieldName: 'Description__c', editable:true, type: 'text'},
            {label: '', type: 'action', typeAttributes: { rowActions: actions } }
        ]);        
        
        helper.getTasks(component, helper); //Get list of tasks
        
    },
    
    //handle task table row actions
    handleRowAction: function (component, event, helper) {
        var action = event.getParam('action');
        var row = event.getParam('row');
        switch (action.name) {
            case 'View':helper.ViewRecord(component,row.Id);
                break;
            case 'Edit': helper.editRecord(component,row.Id);
                break;
            case 'Copy': helper.cloneTask(component,row);
                break;
            case 'Delete':helper.removeTask(component, row);
                break;
            case 'Submit Approval':helper.submitPMTTaskForApproval(component,row.Id);
                break;
            default:
                console.log('Invalid Action');
                break;
        }
    },
    
    //Handle sorting on datatable columns
    handleSort: function (component, event, helper){
        var fieldName = event.getParam('fieldName');
        var sortDirection = event.getParam('sortDirection');
        // assign the latest attribute with the sorted column fieldName and sorted direction
        component.set("v.sortedBy", fieldName);
        component.set("v.sortedDirection", sortDirection);
        helper.sortData(component, fieldName, sortDirection);  
    },
    
    //Handle multiple task selection
    handleTaskSelect : function(component, event, helper) {
        var selectedRows = event.getParam('selectedRows'); 
        component.set("v.selectedTasks", selectedRows);
        var setRows = [];
        for ( var i = 0; i < selectedRows.length; i++ ) {
            setRows.push(selectedRows[i].Id);
        }
        component.set("v.selectedIds", setRows);         
    },
    
    //Save changes to Tasks
    onSave: function (component, event, helper) {
        component.set("v.isRefresh",false);
        var draftValues = event.getParam('draftValues');
        helper.saveTasks(component, draftValues);
        helper.getTasks(component,helper);        
    },
    
    //Handle click on Change Status button
    handleStatusClick: function(component, event, helper){
        var tasksSelected = component.get("v.selectedTasks");
        if(tasksSelected) 
        {
            helper.changeStatus(component, tasksSelected);
        }
        else
        {
            helper.showMessage("", "Please select atleast 1 record to update the Task.", "error");
        }
    },
    
    //Handle click on Change Status button
    handleAssigneeClick: function(component, event, helper){
        var tasksSelected = component.get("v.selectedTasks");
        if(tasksSelected)
        {
            helper.changeAssignee(component, tasksSelected);
        }
        else
        {
            helper.showMessage("", "Please select atleast 1 record to update the Assigned to.", "error");
        } 
    },
    
    //Close flow modal
    closemodal:function (component, event, helper) {
        component.set("v.showflowChangeStatus",false);
    },
    
    //Navigation
    handleStatusChange : function (component, event,helper) {
        if(event.getParam("status") === "FINISHED") {
            component.set("v.showflowChangeStatus", false);
            var projectId = component.get("v.recordId") ;
            var urlEvent = $A.get("e.force:navigateToSObject");
            urlEvent.setParams({
                "recordId": projectId
            });
            urlEvent.fire();
        } 
    },
    
    //Handle filters for datatable
    handlefilters: function (component, event, helper) {
        helper.updateTable(component);
    }
})