({
    showToast : function(type, message) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "title": type + "!",
            "type": type,
            "message": message
        });
        toastEvent.fire();
    },
    
    getPicklists: function(component, event){
      //calls CreateMultiDonationsController.getCampaignList
            var action = component.get('c.getTaskWrapper');
        	var recordId = component.get("v.recordId");
        	action.setParams({
            "projectId" : recordId,
        	});
            // Set up the callback
            action.setCallback(this, $A.getCallback(function (response) {
                var state = response.getState();
                var resultsToast = $A.get("e.force:showToast");
                if(state === "SUCCESS"){
                    //if successful stores query results in ActiveCampaigns
                    var data = response.getReturnValue();               
                    component.set('v.MemberList', data.memberList);
                    component.set('v.PhaseList', data.phasesList);
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
            }));
            $A.enqueueAction(action);  
    },
    
    addTaskRecord: function(component, event) {
        //get the Phase List from component  
        var taskList = component.get("v.taskList");
        var rid = component.get("v.recordId");
        
        //Add New Phase Record
        taskList.push({
            'sobjectType': 'PMT_Task__c',
            'Name': '',
            'Project__c':rid,
            'Status__c': 'Not Started',
            'Start_Date__c': '',
            'Due_Date__c': '',
            'Assigned_To1__c': '',
            'Is_Milestone__c': false,
            'Phase__c': ''
        });
        component.set("v.taskList", taskList);
    },
     
    validateTaskList: function(component, event) {
        //Validate all opportunity records
        var isValid = true;
        var taskList = component.get("v.taskList");
        for (var i = 0; i < taskList.length; i++) {
            if (taskList[i].Name == '' || taskList[i].Start_Date__c == '' || taskList[i].Due_Date__c == '' || taskList[i].Phase__c == '') {
                isValid = false;
                component.set("v.errorMessage", 'PMT Task incomplete. Name, Start date, End date and Phase cannot be blank. Check line ' + (i + 1));
                component.set("v.isError", true);
            }else if(taskList[i].Start_Date__c > taskList[i].Due_Date__c){
                isValid = false;
                component.set("v.errorMessage", 'Task error: Start date cannot be older than End Date, Check line ' + (i + 1));
                component.set("v.isError", true);
            }
        }
        return isValid;
    },
     
    saveTaskList: function(component, event, helper) {
        //Call Apex class and pass opportunity list parameters
        component.set("v.isError", false);
        component.set("v.isLoading",true);
        var action = component.get("c.saveTasks");
        action.setParams({
            "taskList": component.get("v.taskList")
        });
        action.setCallback(this, function(response) {
            component.set("v.isLoading",false);
            var state = response.getState();
            if (state === "SUCCESS") {
                component.set("v.taskList", []);
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
})