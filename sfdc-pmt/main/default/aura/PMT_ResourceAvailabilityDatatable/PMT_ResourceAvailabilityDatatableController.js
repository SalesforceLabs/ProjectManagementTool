({
    //Component initialization
    doInit : function(component, event, helper) {        
        helper.getAllocations(component, helper); //Get list of allocations	
    },
    
    //handle task table row actions
    handleRowAction: function (component, event, helper) {
        component.set("v.isRefresh",false);
        var action = event.getParam('action');
        var row = event.getParam('row');
        var actionName = action.name?action.name:JSON.stringify(action.name);
        switch (actionName) {
            case 'view_details' : helper.ViewRecord(component,row.Project__c);
                break;
            case 'View':helper.ViewRecord(component,row.Id);
                break;
            case 'Edit': helper.editRecord(component,row.Id);
                break;
            case 'Clone': helper.cloneAllocation(component,row);
                break;
            case 'Delete':helper.removeAllocation(component, row);
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
    handleAllocationsSelect : function(component, event, helper) {
        var selectedRows = event.getParam('selectedRows'); 
        component.set("v.selectedAllocation", selectedRows);
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
        helper.saveAllocations(component, draftValues);
        helper.getAllocations(component,helper);
        
    },
    
    //Component refresh on changes
    refreshData : function(component, event ,helper) {
        component.set("v.isRefresh",true);
        helper.getTasks(component, event, helper);        
    },

    transformDataForFiscalYear : function(component, event ,helper) {
        helper.processDataForFiscalYear(component, helper);
    }
    
})