({
    getTasks : function(component, helper) {
        component.set("v.isLoading",true);
        var action = component.get("c.getTasksForProject");
        action.setParams({
            projectId : component.get("v.recordId") 
        });        
        action.setCallback(this,function(response){
            //Create a set for status values
            var statusSet = new Set();
            var phaseSet = new Set();
            var memberSet = new Set();
            
            var statusList = [{'label':'All','value':'all'}];
            var phaseList = [{'label':'All','value':'all'}];
            var memberList = [{'label':'All','value':'all'}];
            
            var state = response.getState();
            if (state === "SUCCESS") {
                var rows = response.getReturnValue();
                for (var i = 0; i < rows.length; i++){
                    var row = rows[i];
                    if (row.Assigned_To1__c) row.AssignedTo = row.Assigned_To1__r.Name;
                    if (row.Phase__c) row.Phase = row.Phase__r.Name;
                    
                    //Unique phase list
                    if(!phaseSet.has(row.Phase__r.Id)){
                        phaseSet.add(row.Phase__r.Id);    
                        phaseList.push({'label':row.Phase__r.Name, 'value':row.Phase__r.Id});
                    }
                    
                    //Unique status list
                    if(!statusSet.has(row.Status__c)){
                        statusSet.add(row.Status__c);    
                        statusList.push({'label':row.Status__c, 'value':row.Status__c});
                    }
                    
                    //Unique assignee list
                    if(!memberSet.has(row.Assigned_To1__c)){
                        memberSet.add(row.Assigned_To1__c); 
                        if(row.Assigned_To1__c!='' && row.Assigned_To1__c!=undefined){
                            memberList.push({'label':row.AssignedTo, 'value':row.Assigned_To1__c});  
                        }
                    }
                    
                }
                
                //Set filters
                component.set("v.PhaseList", phaseList);
                statusList.push({'label':'Open Tasks','value':'Open Tasks'})
                component.set("v.statusList", statusList);
                memberList.push({'label':'Not Assigned', 'value':'Not Assigned'})
                component.set("v.MemberList", memberList);
                
                //Set data
                component.set("v.tasks", rows);
                component.set("v.rawData", rows);
                
                //Apply default filter
                helper.updateTable(component);
                
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
            component.set("v.isLoading",false);
        });
        $A.enqueueAction(action);
        
    },
    
    getRowActions: function (component, row, doneCallback) {
        var actions = [{
            'label': 'View',
            'iconName': 'utility:preview',
            'name': 'View'
        },
                       {	'label': 'Edit' ,
                        'iconName':'utility:edit',
                        'name': 'Edit'
                       },
                       {	'label': 'Copy' ,
                        'iconName':'utility:copy',
                        'name': 'Copy'
                       }
                      ];
        var deleteAction = {
            'label': 'Delete',
            'iconName': 'utility:delete',
            'name': 'Delete'
        };
        if (row['Approved']) {  
            deleteAction['disabled'] = 'true';
        } else {
            actions.push({
                'label': 'Submit Approval',
                'iconName': 'utility:approval',
                'name': 'Submit Approval'
            });
        }
        actions.push(deleteAction);
        doneCallback(actions);
    },
    
    removeTask: function (component, row) {
        var confirmation = confirm('Are you sure you want to delete?');
        if(confirmation){
            var rows = component.get('v.tasks');
            var rowIndex = rows.indexOf(row);
            rows.splice(rowIndex, 1);
            component.set('v.tasks', rows);
            if(row) {
                var action = component.get("c.deleteRecord");
                action.setParams({
                    recordToDelete : row 
                });
                action.setCallback(this,function(response){                    
                    var result= response.getReturnValue();
                    var state = response.getState();
                    if(state === "SUCCESS"){
                        this.showMessage("", "Record deleted successfully.", "Success");
                        $A.get('e.force:refreshView').fire();
                    } else if(state ==='ERROR'){            
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
            }
        }
    },
    editRecord: function(component, recId)
    {
        if(recId) {
            var editRecordEvent = $A.get("e.force:editRecord");
            editRecordEvent.setParams({
                "recordId": recId
            });
            editRecordEvent.fire();
        }    
    },
    
    ViewRecord:function(component, recId)
    {
        if(recId) {
            
            var urlEvent = $A.get("e.force:navigateToSObject");
            urlEvent.setParams({
                "recordId": recId
            });
            urlEvent.fire();
        } 
    },
    
    cloneTask: function(component, taskRec) {
        if(taskRec) {
            var createPMTTaskEvent = $A.get("e.force:createRecord");
            createPMTTaskEvent.setParams({
                "entityApiName": "PMT_Task__c",
                "defaultFieldValues": {
                    'Phase__c' : taskRec.Phase__c,
                    'Name' : taskRec.Name,
                    'Assigned_To1__c' : taskRec.Assigned_To1__c,
                    'Start_Date__c' : taskRec.Start_Date__c,
                    'Due_Date__c' : taskRec.Due_Date__c
                }
            });
            createPMTTaskEvent.fire();
        }
    },
    
    submitPMTTaskForApproval: function(component, recId) {
        if(recId) {
            var action = component.get("c.submitTaskForApproval");
            action.setParams({
                taskId : recId 
            });
            action.setCallback(this,function(response){
                var result= response.getReturnValue();
                var state = response.getState(); 
                if(state === "SUCCESS"){
                    this.showMessage("", "PMT Task was submitted for Approval.", "Success");
                    $A.get('e.force:refreshView').fire();
                } else if(state ==='ERROR'){            
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
        }
    },
    
    saveTasks: function(component, tasksToSave) {
        if(tasksToSave) {
            var action = component.get("c.updateTasks");
            action.setParams({"tasks" : tasksToSave});
            action.setCallback(this, function(response) {
                var result = response.getReturnValue();
                var state = response.getState();                
                 if(state === "SUCCESS"){
                    component.set("v.selectedTasks",response.getReturnValue());
                    component.set("v.draftValues",null);                    
                    this.showMessage("", "Your changes are saved.", "Success");
                    
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
        }
    },
    
    showMessage: function(title, message, type) {
        var resultsToast = $A.get("e.force:showToast");
        resultsToast.setParams({
            "title": title,
            "message": message,
            "type" : type
        });
        resultsToast.fire();
    },
    
    changeStatus: function(component, tasksSelected) {
        component.set("v.showflowChangeStatus", true);
        // Find the component whose aura:id is "flowChangeStatus"
        var flow = component.find("flowChangeStatus");
        var inputVariables = [
            {
                name : "PMTTaskListIds",
                type : "SObject",
                value : component.get("v.selectedIds")
            }
        ];
        // In that component, start your flow. Reference the flow's API Name.
        flow.startFlow("PMT_Mass_update_Task_Status", inputVariables);
    },
    
    changeAssignee: function(component, tasksSelected) {
        component.set("v.showflowChangeStatus", true);        
        var action = component.get("c.getTasksList");
        action.setParams({
            taskIds : component.get("v.selectedIds") 
        });        
        action.setCallback(this,function(response){
            var state = response.getState();
            if (state === "SUCCESS") {
                var listOfTasks = response.getReturnValue();
                component.set("v.tasksToUpdate", listOfTasks);
                // Find the component whose aura:id is "flowChangeStatus"
                var flow = component.find("flowChangeStatus");
                var inputVariables = [
                    {
                        name : "InputProjectId",
                        type : "SObject",
                        value : component.get("v.recordId")
                    },
                    {
                        name : "LsPMTTasksSelected",
                        type : "SObject",
                        value :component.get("v.tasksToUpdate")
                    }
                ];
                // In that component, start your flow. Reference the flow's API Name.
                flow.startFlow("PMT_Mass_update_Task_Assignee",inputVariables); 
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
    
    //Handle sort in datatable columns
    sortData: function (component, fieldName, sortDirection) {
        var data = component.get("v.tasks");
        var reverse = sortDirection !== 'asc';
        //sorts the rows based on the column header that's clicked
        data.sort(this.sortBy(fieldName, reverse))
        component.set("v.tasks", data);
    },
    sortBy: function (field, reverse, primer) {
        var key = primer ?
            function(x) {return primer(x[field])} :
        function(x) {return x[field]};
        //checks if the two rows should switch places
        reverse = !reverse ? 1 : -1;
        return function (a, b) {
            return a = key(a), b = key(b), reverse * ((a > b) - (b > a));
        }
    },
    updateTable: function (component) {
        var rows = JSON.parse(JSON.stringify(component.get('v.rawData')));
        var selectedPhase = component.get("v.selectedPhase");
        var selectedStatus = component.get("v.selectedStatus");
        var selectedMember = component.get("v.selectedMember");
        
        var filteredRows = JSON.parse(JSON.stringify(rows));
        if(selectedPhase !== 'all' && selectedPhase!=='') {
            filteredRows = filteredRows.filter(row=> row.Phase__r.Id == selectedPhase);
        }
        if(selectedStatus !== 'all' && selectedStatus!=='' && selectedStatus!=='Open Tasks') {
            filteredRows = filteredRows.filter(row=> row.Status__c == selectedStatus);
        }
        else if(selectedStatus == 'Open Tasks'){
            filteredRows = filteredRows.filter(row=> row.Status__c == 'Not Started' || row.Status__c == 'In Progress' || row.Status__c == 'On Hold');
        }
        
        if(selectedMember !== 'Not Assigned' && selectedMember!='all' && selectedMember!=='') {
            filteredRows = filteredRows.filter(row=> row.Assigned_To1__c == selectedMember);
        }
        else if(selectedMember == 'Not Assigned'){
            filteredRows = filteredRows.filter(row=> row.Assigned_To1__c == '' || row.Assigned_To1__c == undefined);
        }
        component.set("v.tasks", filteredRows);
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