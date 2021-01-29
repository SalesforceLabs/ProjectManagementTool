({
    
    getAllocations : function(component, helper) {
        var action = component.get("c.getAllocationsForResource");
        action.setParams({
            resourceId : component.get("v.recordId"),
            fiscalYear : component.get("v.fiscalYear")
        });        
        action.setCallback(this,function(response){
            var state = response.getState();
            if (state === "SUCCESS") {
                var data = response.getReturnValue();
                var rows = data.resourceAvailabilities;
                                
                component.set("v.allocation", rows);
                component.set("v.isResourcePlanner", data.isResourcePlanner);
                this.processDataForFiscalYear(component, helper);
            }
            else if (response.getState() === "ERROR")
            {
                this.showMessage("","Some error has occured. Please refresh the page, if error persists. Contact system administrator","ERROR");
            }
        });
        $A.enqueueAction(action);
        
    },

    processDataForFiscalYear : function(component, helper){
        
        //Get dynamic actions buttons
        var actions = helper.getRowActions.bind(this, component); 
        
        //Fiscal Year Setup
        var fiscalStartMonth = component.get("v.fiscalYearOffset");
        const monthNames = ["Jan","Feb", "Mar", "Apr", "May", "Jun",
                    "Jul", "Aug", "Sep", "Oct", "Nov", "Dec" 
                   ];
        var fiscalMonths = [];
        
        //Add months from the current calendar year
        for(var i=fiscalStartMonth-1;i<monthNames.length;i++){
            fiscalMonths.push(monthNames[i]); 
        }
        //Add remaining fiscal year months from next calendar year
        for(var i=0;i<fiscalStartMonth-1;i++){
            fiscalMonths.push(monthNames[i]); 
        }
        
        //Define columns table
        var columns = [{label: 'Project', type: 'button', editable:false, sortable:true, typeAttributes: { label: {fieldName: 'Project_Name__c'}, variant:'base', class:'slds-truncate',name: 'view_details', title: 'Click to View Details'}},
                       {label: 'Project Owner',fieldName: 'Project_Owner__c', editable:false, type: 'text', sortable:true},
                       {label: 'Role',fieldName: 'Role__c', editable:false, type: 'text', sortable:true, initialWidth:100}];
        
        for(var i=0;i<fiscalMonths.length;i++){
            columns.push({label: fiscalMonths[i]+' %', fieldName: '' + fiscalMonths[i]+'__c', editable:component.get("v.isResourcePlanner"), type: 'number',step:1, initialWidth: 70});
        }
        
        columns.push({label: '', type: 'action', typeAttributes: { rowActions: actions }});
        component.set('v.columns', columns);
        
    },
    
    getRowActions: function (component, row, doneCallback) {
        var actions = [
            {
                'label': 'View',
                'iconName': 'utility:preview',
                'name': 'View'
            },
            {	'label': 'Edit' ,
             'iconName':'utility:edit',
             'name': 'Edit'
            }];
        if(component.get("v.isResourcePlanner")){
            actions.push({	'label': 'Clone' ,
                          'iconName':'utility:copy',
                          'name': 'Clone'
                         });
            
            actions.push({               
                'label': 'Delete',
                'iconName': 'utility:delete',
                'name': 'Delete'
            });
        }    
        doneCallback(actions);
    },
    
    removeAllocation: function (component, row) {
        var confirmation = confirm('Are you sure you want to delete?');
        if(confirmation){
            var rows = component.get('v.allocation');
            var rowIndex = rows.indexOf(row);
            rows.splice(rowIndex, 1);
            component.set('v.allocation', rows);
            if(row) {
                var action = component.get("c.deleteRecord");
                action.setParams({
                    recordToDelete : row 
                });
                action.setCallback(this,function(response){
                    
                    var result= response.getReturnValue();
                    if(result) {
                        this.showMessage("", "Record deleted successfully.", "Success");
                        $A.get('e.force:refreshView').fire();
                    } else {
                        this.showMessage("", "Error occurred. Please contact system administrator", "error");
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
            $A.get('e.force:refreshView').fire();
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
        $A.get('e.force:refreshView').fire();
        
    },
    
    cloneAllocation: function(component, AllocRec) {
        if(AllocRec) {
            var createAllocation = $A.get("e.force:createRecord");
            createAllocation.setParams({
                "entityApiName": "PMT_Resource_Allocation__c",
                "defaultFieldValues": {
                    'Project__c' : AllocRec.Project__c,
                    'Resource_Availability__c' : AllocRec.Resource_Availability__c,
                    'Role__c' : AllocRec.Role__c,
                    'Feb__c' : AllocRec.Feb__c,
                    'Mar__c' : AllocRec.Mar__c,
                    'Apr__c' : AllocRec.Apr__c,
                    'May__c' : AllocRec.May__c,
                    'Jun__c' : AllocRec.Jun__c,
                    'Jul__c' : AllocRec.Jul__c,
                    'Aug__c' : AllocRec.Aug__c,
                    'Sep__c' : AllocRec.Sep__c,
                    'Oct__c' : AllocRec.Oct__c,
                    'Nov__c' : AllocRec.Nov__c,
                    'Dec__c' : AllocRec.Dec__c,
                    'Jan__c' : AllocRec.Jan__c
                }
            });
            createAllocation.fire();
            $A.get('e.force:refreshView').fire();
        }
    },
    
    saveAllocations: function(component, allocationsToSave) {
        if(allocationsToSave) {
            var action = component.get("c.updateAllocations");
            action.setParams({"allocations" : allocationsToSave});
            action.setCallback(this, function(response) {
                var result = response.getReturnValue();
                var state = response.getState();
                
                if(result) {
                    component.set("v.selectedAllocations",response.getReturnValue());
                    component.set("v.draftValues",null);
                    
                    
                    this.showMessage("", "Your changes are saved.", "Success");
                    
                    $A.get('e.force:refreshView').fire();
                }else {
                    this.showMessage("", "Some error has occured. Please refresh the page, if error persists. Contact system administrator", "Info");
                }
                
            });
            $A.enqueueAction(action);
        }
        $A.get('e.force:refreshView').fire();
    },
    
    showMessage: function(title, message, type) {
        var resultsToast = $A.get("e.force:showToast");
        resultsToast.setParams({
            "title": title,
            "message": message,
            "type" : type
        });
        resultsToast.fire();
        $A.get('e.force:refreshView').fire();
    },
    
    //Handle sort in datatable columns
    sortData: function (component, fieldName, sortDirection) {
        var data = component.get("v.allocation");
        var reverse = sortDirection !== 'asc';
        //sorts the rows based on the column header that's clicked
        data.sort(this.sortBy(fieldName, reverse))
        component.set("v.allocation", data);
    },
    sortBy: function (field, reverse, primer) {
        var key = primer ?
            function(x) {
                return primer(x[field])
            } : function(x) {return x[field]};
        //checks if the two rows should switch places
        reverse = !reverse ? 1 : -1;
        return function (a, b) {
            return a = key(a), b = key(b), reverse * ((a > b) - (b > a));
        }
    },
    
})