({
	addPhaseRecord: function(component, event) {
        //get the Phase List from component  
        var phaseList = component.get("v.phaseList");
        var rid = component.get("v.recordId");
        
        //Add New Phase Record
        phaseList.push({
            'sobjectType': 'PMT_Phase__c',
            'Name': '',
            'Project__c':rid,
            'Phase_Health__c': 'Not Started',
            'Description__c': ''
        });
        component.set("v.phaseList", phaseList);
    },
     
    validatePhaseList: function(component, event) {
        //Validate all opportunity records
        var isValid = true;
        var phaseList = component.get("v.phaseList");
        for (var i = 0; i < phaseList.length; i++) {
            if (phaseList[i].Name == '' || phaseList[i].Phase_Health__c == '') {
                isValid = false;
                component.set("v.errorMessage", 'Phase Name cannot be blank. Check line ' + (i + 1));
                component.set("v.isError", true);
            }
        }
        return isValid;
    },
     
    savePhaseList: function(component, event, helper) {
        //Call Apex class and pass opportunity list parameters
        component.set("v.isError", false);
        component.set("v.isLoading",true);
        var action = component.get("c.savePhases");
        action.setParams({
            "phaseList": component.get("v.phaseList")
        });
        action.setCallback(this, function(response) {
            component.set("v.isLoading",false);
            var state = response.getState();
            if (state === "SUCCESS") {
                component.set("v.phaseList", []);
                component.set("v.isCreated", true); 
                $A.get('e.force:refreshView').fire();
            }else if(state ==='ERROR'){            
                var errors = response.getError();
                var message = '';               
                if (errors && Array.isArray(errors) && errors.length > 0) {
                    message += errors[0].message;
                }
                helper.showToast("Error", message);
            }else{
                helper.showToast("Error", "Something went wrong, please contact system administrator.");
            }  
        }); 
        $A.enqueueAction(action);
    },

	//Get values for Health picklist
	fetchHealthPicklist : function(component){
        var action = component.get("c.getPicklistvalues");
        action.setParams({
            'objectName': component.get("v.ObjectName"),
            'field_apiname': component.get("v.Health"),
            'nullRequired': false
        });
        action.setCallback(this, function(a) {
            var state = a.getState();
            if (state === "SUCCESS"){
                component.set("v.HealthPicklist", a.getReturnValue());
            }else if(state ==='ERROR'){            
                var errors = response.getError();
                var message = '';               
                if (errors && Array.isArray(errors) && errors.length > 0) {
                    message += errors[0].message;
                }
                helper.showToast("Error", message);
            }else{
                helper.showToast("Error", "Something went wrong, please contact system administrator.");
            }  
        });
        $A.enqueueAction(action);
    },
    
    showToast : function(type, message) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "title": type + "!",
            "type": type,
            "message": message
        });
        toastEvent.fire();
    },

})