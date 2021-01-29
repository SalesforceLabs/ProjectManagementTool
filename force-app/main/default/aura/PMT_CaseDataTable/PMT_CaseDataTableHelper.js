({
	    
    getRecords : function(component, helper) {
        var action = component.get("c.getCasesForProject");
        action.setParams({
            recordId : component.get("v.recordId"),
        });        
        action.setCallback(this,function(response){           
            component.set("v.showSpinner",false);
            
            //Create a set for status values
            var statusSet = new Set();
            var typeSet = new Set();
            var prioritySet = new Set();
            
            var statusList = [{'label':'All','value':'all'}];
            var typeListTemp = [{'label':'--None--','value':''},{'label':'All','value':'all'}];
            var typeList = [];
            var priorityList = [{'label':'All','value':'all'}];
            
            var state = response.getState();
            if (state === "SUCCESS") {
                var rows = response.getReturnValue();
                for (var i = 0; i < rows.length; i++){
                    var row = rows[i];
           
           			 //Unique Type list
                    if(!typeSet.has(row.Type) && row.Type){
                    	typeSet.add(row.Type);    
                        typeList.push({'label':row.Type, 'value':row.Type});
                    }
                    
                    //Unique status list
                    if(!statusSet.has(row.Status)){
                    	statusSet.add(row.Status);    
                        statusList.push({'label':row.Status, 'value':row.Status});
                    }
                    
                    //Unique Priority list
                    if(!prioritySet.has(row.Priority)){
                    	prioritySet.add(row.Priority); 
                        priorityList.push({'label':row.Priority, 'value':row.Priority});  
                    }
                    
                }
                
                //Set filters
                //Sort
                typeList.sort((a, b) => (a.label > b.label) ? 1 : -1);
                component.set("v.typeList", typeListTemp.concat(typeList));
                statusList.push({'label':'Open Cases','value':'Open Cases'})
                component.set("v.statusList", statusList);
                component.set("v.priorityList", priorityList);    
                
                
            	//Set data
            	component.set("v.cases", rows);
            	component.set("v.rawData", rows);
                //Apply default filter
                
                helper.updateTable(component);
                
            }else if (response.getState() === "ERROR"){
                var errors = response.getError();
                var message = ''; // Default error message
                // Retrieve the error message sent by the server                
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
    
    getRowActions: function (component, row, doneCallback) {
        var actions = [
            {
                'label': 'View',
                'iconName': 'utility:preview',
                'name': 'view'
            },
            {	'label': 'Edit' ,
             'iconName':'utility:edit',
             'name': 'edit'
            },            
        ];
            doneCallback(actions);
     },
            
  	
            
	//Generic show toast for showing error messages
    showToast : function(type, message) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "title": type + "!",
            "type": type,
            "mode" : "sticky",
            "message": message,
        });
        toastEvent.fire();
    },
    
    updateTable: function (component) {
        var rows = JSON.parse(JSON.stringify(component.get('v.rawData')));
        var selectedType = component.get("v.selectedType");
        var selectedStatus = component.get("v.selectedStatus");
        var selectedPriority = component.get("v.selectedPriority");
        
        var filteredRows = JSON.parse(JSON.stringify(rows));
        
        if(selectedType !== 'all' && selectedType!='') {
            filteredRows = filteredRows.filter(row=> row.Type == selectedType);
        }
        else if(selectedType !== 'all' && selectedType==''){
            filteredRows = filteredRows.filter(row=> (row.Type == '' || row.Type==null || row.Type==undefined));
        }
        if(selectedStatus !== 'all' && selectedStatus!=='' && selectedStatus!=='Open Cases') {
            filteredRows = filteredRows.filter(row=> row.Status == selectedStatus);
        }
        else if(selectedStatus == 'Open Cases'){
            filteredRows = filteredRows.filter(row=> row.Status !== 'Closed');
        }
        
        if(selectedPriority !='all' && selectedPriority!=='') {
            filteredRows = filteredRows.filter(row=> row.Priority == selectedPriority);
        }
        component.set("v.cases", filteredRows);
    }
})