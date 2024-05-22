({
    itemSelected : function(component, event, helper) {
        //resource selected from picklist
        helper.handleResourceSelection(component, event, helper);
    },
    percentChange : function(component, event, helper) {
        //Changed the percentage
        var selUser = component.get("v.selUser");
        if(!component.get("v.isAllocated")){
            helper.changeResourcePicklist(component, event, helper);    
        }
        helper.highlightCellsInRed(component, component.get("v.resourceAllocation"));
        component.set("v.selUser",selUser);
    },
    updateRecommendation : function(component, event, helper) {
        //backup the original numbers
        component.set("v.resourceAllocationBackup", JSON.parse(JSON.stringify(component.get("v.resourceAllocation"))));
        //Update recommendation based on %
        helper.changeResourcePicklist(component, event, helper);
    },
    handleSelect : function(component, event, helper) {
        //Handle select for actions
        var selectedMenuItemValue = event.getParam("value");
        if(selectedMenuItemValue=='Copy'){
            helper.copyAllocation(component, event, helper);
        }
        else if(selectedMenuItemValue == 'Split'){
            helper.splitAllocation(component, event, helper);
        }
            else if(selectedMenuItemValue == 'Delete'){
                //check for confirmation
                var confirmation = confirm('Are you sure?');
                if(confirmation){
                    helper.removeRole(component, event, helper);
                }
            }
                else if(selectedMenuItemValue == 'View'){
                    helper.redirectToRecord(component, event, helper);
                }
    },
    showResourceAvailability : function(component, event, helper){
        helper.redirectToRecord(component, event, helper);
    },
    showPopup : function(component, event, helper) {
        //Show warning popup
        if(event.getSource().get("v.label")=='redCell'){
            component.set("v.isPopoverVisible",true);
        }
    },
    hidePopup : function(component, event, helper) {
        //Hide warning popup
        component.set("v.isPopoverVisible",false);
    },
    deleteRole : function(component, event, helper) {
        //Delete a line item
        helper.removeRole(component, event, helper);
    },
    cancelModal : function(component, event, helper) {
        component.set("v.isDeleted",false);
    }
})