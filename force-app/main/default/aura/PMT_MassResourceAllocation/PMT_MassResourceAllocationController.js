({
    handleLineItemEvent : function(component, event, helper) {
        //Handle line item events such as add and delete
        var index = event.getParam("index");
        var allocationToAdd = event.getParam("resourceAllocation");
        //Add action
        if(event.getParam("action")=='Add'){
            helper.pushLineItem(component, index, allocationToAdd);
        }
        else{
            //Delete
            var list = component.get("v.resourceAllocation");
            //splice only deleted item from the list
            list.splice(index,1);
            component.set("v.resourceAllocation",list);
            //Maintain separate list for record deletion
            helper.updateDeletionList(component, allocationToAdd.Id);
        }
    },
    showHideActions : function(component, event, helper) {
        var activeSectionNames = component.get("v.activeSectionNames");
        component.set("v.showActions",activeSectionNames.includes(component.get("v.year")));
    },
    addNew : function(component, event, helper) {
        helper.addNewAllocation(component, event, helper);
    },
    copyAllocations : function(component, event, helper) {
        helper.copyFromPreviousYear(component, event, helper);
    },
    handleSelect : function(component, event, helper) {
        var selectedMenuItemValue = event.getParam("value");
        if(selectedMenuItemValue=='Add'){
            //Handle add for the current year
            helper.addNewAllocation(component, event, helper);
        }
        else if(selectedMenuItemValue=='Copy'){
            //handle copy from previous year
            helper.copyFromPreviousYear(component, event, helper);
        }
    }
})