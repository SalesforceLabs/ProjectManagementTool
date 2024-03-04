({
    doRefresh : function(component, event) {
        $A.get('e.force:refreshView').fire();
        component.find("SummaryTable").refreshTable();
        component.set("v.selectedSpan", "THIS_WEEK");
	},
    
    editRecord : function(component, event) {
        var recordId =event.currentTarget.id;
        $A.get('e.force:editRecord').setParams({ recordId: recordId }).fire();
    },
    
    milestone : function(component, event){
        component.find("SummaryTable").openModal();
    }

})