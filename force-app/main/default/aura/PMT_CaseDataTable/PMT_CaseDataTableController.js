({
	//Component initialization
    doInit : function(component, event, helper) {
        //Get dynamic actions buttons
        var actions = helper.getRowActions.bind(this, component)
        
        //Define columns table
       
        component.set('v.columns', [          
            {label: 'Case Number',fieldName: 'CaseNumber', type: 'button', editable:false, sortable:true, initialWidth:100, typeAttributes: { label: {fieldName: 'CaseNumber'}, variant:'base', class:'slds-truncate',name: 'view', title: 'Click to View Details'}},         
            {label: 'Type', fieldName: 'Type', editable:false, type: 'text', sortable:true,initialWidth: 150,  cellAttributes:{class:{fieldName:'Priority'}}},
            {label: 'Age',fieldName: 'Days_Open__c', editable:false, type: 'number', sortable:true, initialWidth: 70, cellAttributes:{alignment: 'center', class:{fieldName:'Priority'}}},
            {label: 'Case Title',fieldName: 'Subject', editable:false, type: 'text', sortable:true, cellAttributes:{class:{fieldName:'Priority'}}},
            {label: 'Description', fieldName: 'Description', editable:false, type: 'text', cellAttributes:{class:{fieldName:'Priority'}}},            
            {label: 'Status', fieldName: 'Status', editable:false, type: 'text', sortable:true,initialWidth: 120,  cellAttributes:{class:{fieldName:'Priority'}}},
            {label: 'Priority', fieldName: 'Priority', editable:false, type: 'text', sortable:true, initialWidth: 100, cellAttributes:{class:{fieldName:'Priority'}}},
            {label: '', type: 'action', cellAttributes:{class:{fieldName:'Priority'}}, typeAttributes: { rowActions: actions } },
        ]);        
        
        helper.getRecords(component, helper); //Get list of allocations	
    },
    
    //Handle filters for datatable
    handlefilters: function (component, event, helper) {
        helper.updateTable(component);
    }
})