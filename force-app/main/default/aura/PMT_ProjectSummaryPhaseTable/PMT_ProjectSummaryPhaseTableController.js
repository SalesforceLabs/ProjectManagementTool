({
	doInit : function(component, event, helper) {
        helper.getRecords(component, event, helper);
    },
    
    editRecord : function(component, event ,helper) {
        var recordId =event.currentTarget.id;
        $A.get('e.force:editRecord').setParams({ recordId: recordId }).fire();
    },
    
    navigateToRecord : function(component, event ,helper) {
        var recordId =event.currentTarget.id;
        $A.get('e.force:navigateToSObject').setParams({ recordId: recordId }).fire();
    },
    
    handleFilter: function(component, event, helper){
        var filterValue = component.get("v.selectedSpan");
        if(filterValue =='THIS_WEEK'){
            helper.filterWeek(component, event, helper);
        }else if(filterValue =='THIS_MONTH'){
            helper.filterMonth(component, event, helper);
        }else{
            helper.filterQuarter(component, event, helper);
        }
    },
    
    openModal : function(component, event){
        component.set("v.showMilestones", true);
    },
    
    closeModal : function(component, event){
        component.set("v.showMilestones", false);
    }
})