({
    handleResourceSelection : function(component, event, helper) {
        var ResourceAllocation = component.get("v.resourceAllocation");
        var selUser = component.get("v.selUser");
        //Hardcoded index for availability id
        //Mitigated for ensuring there are values separated by '_'
        if(selUser && selUser.split('_')[0]!=component.get("v.dummyAvailability").Id){
            if(ResourceAllocation)
            {
                var selectedResource = component.get("v.masterResourceAvailabilities").filter(resource => resource.Id== component.get("v.selUser").split('_')[0])[0];
        		component.set("v.allocatedResourceName", selUser.split('_')[1]);
                
                component.set("v.isAllocated",true);
                //Hardcoded index for availability id
                //Mitigated for ensuring there are values separated by '_'
                ResourceAllocation.Availability.Id = selUser.split('_')[0];
                
                //highlight in red for overallocation
                helper.highlightCellsInRed(component, ResourceAllocation);
            }
        }
        //Deselect the allocated resource
        else{
            if(ResourceAllocation)
            {
                ResourceAllocation.Availability.Id = component.get("v.dummyAvailability").Id;
                component.get("v.resourceAllocation",ResourceAllocation); 
                component.set("v.isAllocated",false);
            }
        }
    },
    highlightCellsInRed : function(component, ResourceAllocation){
        var percentForMonth, allocationForMonth;
        //Highlight cell in red
        var selectedResource = component.get("v.masterResourceAvailabilities").filter(resource => resource.Id== component.get("v.selUser").split('_')[0])[0];
        if(selectedResource && component.get("v.isAllocated")){
            
            //Code to populate resource name for read only mode
            if(component.get("v.isReadOnly")){
        		component.set("v.allocatedResourceName", selectedResource.User__r.Name);
        	}
            //check for the monthly availability
            for(var i=0;i<ResourceAllocation.months.length;i++){
                percentForMonth = selectedResource['' + ResourceAllocation.months[i].name+'_Remaining__c'];
                //if resource is not changed, check for comitted allocation earlier
                var backupPercent = component.get("v.resourceAllocationBackup").Availability.Id==selectedResource.Id?component.get("v.resourceAllocationBackup").months[i].percentage:0;
                
                //Check the remaining allocation with current saved to db + extra allocation
                allocationForMonth = ResourceAllocation.months[i].percentage - backupPercent;
                if(ResourceAllocation.months[i].percentage!=0 && allocationForMonth>percentForMonth){
                    ResourceAllocation.months[i]['class']='redCell';
                }
                else{
                    ResourceAllocation.months[i]['class']='noBorder';
                }
            }
            component.set("v.resourceAllocation",ResourceAllocation);              
        } 
    },
    createNewLineItemForAllocation : function(component, event, helper, allocation) {
        //Create a new line item and throw event
        var cmpEvent = component.getEvent("LineItemAction");
        cmpEvent.setParams({
            "resourceAllocation" : allocation,
            "index" : component.get("v.index"),
            "action" : 'Add'
        });
        cmpEvent.fire();
    },
    copyAllocation : function(component, event, helper) {
        //Create a clone of line item and throw event
        var allocation = JSON.parse(JSON.stringify(component.get("v.resourceAllocation")));
        //Remove allocation
        allocation.Id=null;
        helper.createNewLineItemForAllocation(component, event, helper, allocation);
    },
    redirectToRecord : function(component, event, helper) {
        //redirect to the record id
        var urlEvent = $A.get("e.force:navigateToSObject");
        urlEvent.setParams({
            //Hardcoded index for availability id
            //Mitigated for ensuring there are values separated by '_'
            "recordId": component.get("v.selUser").split('_')[0]
        });
        urlEvent.fire();
        
    },
    splitAllocation : function(component, event, helper) {
        var availability = JSON.parse(JSON.stringify(component.get("v.dummyAvailability")));
        //Split the current allocation into 2
        var allocationOringinal = component.get("v.resourceAllocation");
        var allocationNew =  JSON.parse(JSON.stringify(component.get("v.resourceAllocation")));
        allocationNew.Id= null;
        allocationNew.allocated= false;
        allocationNew.Availability= availability;
        allocationNew.RecommendedResource= null;
        allocationNew.selUser = availability.Id+'_'+availability.User_Id__c;
        for(var i=0;i<allocationOringinal.months.length;i++)
        {
            allocationNew.Id=null;
            if(allocationOringinal.months[i].percentage%2!=0)
            {
                //if not a multiple of 10, +5 in the new allocation, because the step is of 2
                var percentage = allocationOringinal.months[i].percentage;
                allocationOringinal.months[i].percentage = (percentage-1)/2;
                allocationNew.months[i].percentage = ((percentage-1)/2)+1;
            }
            else
            {
                //split in two if divisble by 2
                allocationOringinal.months[i].percentage = allocationNew.months[i].percentage = allocationOringinal.months[i].percentage/2;
            }
            if(isNaN(allocationNew.months[i].percentage)){
                allocationNew.months[i].percentage=0;
            }
            if(isNaN(allocationOringinal.months[i].percentage)){
                allocationOringinal.months[i].percentage = 0;
            }
        }
        component.set("v.resourceAllocation",allocationOringinal);
        helper.createNewLineItemForAllocation(component, event, helper, allocationNew);
    },
    removeRole : function(component, event, helper){
        //Delete a line item and throw event
        var cmpEvent = component.getEvent("LineItemAction");
        cmpEvent.setParams({
            "resourceAllocation" : component.get("v.resourceAllocation"),
            "index" : component.get("v.index"),
            "action" : 'Remove'
        });
        cmpEvent.fire();
    },
    changeResourcePicklist : function(component, event, helper){
        //Change based on % and recommendation
        var master = component.get("v.masterResourceAvailabilities");
        var ResourceAllocation = component.get("v.resourceAllocation");
        var months = ResourceAllocation.months;
        
        //Generate recommendation based on availabilties and reporting manager
        var recommendations = [];
        var allResources = [];
        var directReports = [];
        
        for(var i=0;i<master.length;i++){
            if(master[i].User__r.ManagerId==$A.get('$SObjectType.CurrentUser.Id')){
                directReports.push(master[i]);
                continue;
            }
            //Check availability
            for(var j=0;j<months.length;j++){
                var currentAllocation = component.get("v.resourceAllocationBackup").months[j].percentage == months[j].percentage?0:component.get("v.resourceAllocationBackup").months[j].percentage;
                if(months[j].percentage - currentAllocation > master[i]['' + months[j].name+'_Remaining__c']){
                    break;
                }
            }
            //if available for all the months, add to recommendation
            if(j==months.length){
                recommendations.push(master[i]);
            }
            else{
                //else add to all list
                allResources.push(master[i]);
            }
        }

        component.set("v.teamAvailabilities",directReports);
        component.set("v.recommendedAvailabilities",recommendations);
        component.set("v.resourceAvailabilities",allResources);
        
        //highlight cells in red if overallocated
        helper.highlightCellsInRed(component, ResourceAllocation);
    }
})