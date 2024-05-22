({
    doInit : function(component, event, helper) {
        //Initial loading of component, called upon record load
        helper.getResources(component,helper);
    },
    handleCancel : function(component, event, helper){
        //Cancel to reinit the component
        //clear the deletion list
        component.set("v.resourceAllocationToDelete",null);
        component.set("v.isReadOnly",true);
        helper.getResources(component,helper);
    },
    handleLineItemEvent : function(component, event, helper) {
        //Which line item was clicked
        var index = event.getParam("index");
        var allocationToAdd = event.getParam("resourceAllocation");
        if(event.getParam("action")=='Remove'){
            //Maintain separate list for record deletion
            helper.updateDeletionList(component, allocationToAdd.Id);
        }
    },
    save : function(component, event, helper) {
        //reset duplicate flag
        component.set("v.duplicatesFound",false);
        //create a list of upsert
        //create a list of deletion
        helper.saveAllocations(component, helper);
    },
    toggleMode : function(component, event, helper) {
        //Toggle between readonly and edit mode
        component.set("v.isReadOnly",!component.get("v.isReadOnly"));
    }
})