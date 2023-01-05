({
	doInit: function (component, event, helper) {        
        //this block to fetch picklist values
        helper.fetchHealthPicklist(component); // fetches PickList Values of Tribute Type Field
        helper.addPhaseRecord(component, event); //Add one initial row in the component
     },
    
    addRow: function(component, event, helper) {
        component.set("v.isCreated", false);
        helper.addPhaseRecord(component, event);
    },
     
    removeRow: function(component, event, helper) {
        //Get the Phase list
        var phaseList = component.get("v.phaseList");
        //Get the target object
        var selectedItem = event.currentTarget;
        //Get the selected item index
        var index = selectedItem.dataset.record;
        //Release 1.0
        //Bug Fix : Create task, Phases button when nothing added still submit button shown and clickable with success message.
        if(phaseList.length>1){
            phaseList.splice(index, 1);
        	component.set("v.phaseList", phaseList);
        }
        else{
            helper.showToast("Warning", "Cannot remove the last row.");
        }
    },
     
    save: function(component, event, helper) {
        component.set("v.isCreated", false);
        if (helper.validatePhaseList(component, event)) {
            helper.savePhaseList(component, event);
        }
    },
    
    closeQuickAction : function(component, event, helper){
        var dismissActionPanel = $A.get("e.force:closeQuickAction");
        dismissActionPanel.fire();
    }
})