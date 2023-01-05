({
    copyFromPreviousYear : function(component, event, helper){
        //Copy all allocations from previous year
        var resourceAllocations = [];
        //get records from last year
        var resourceAllocationFromLastYear = component.get("v.masterResourceAllocations")[component.get("v.index")-1].Records;
        var resourceAllocation;
        var Months = component.get("v.months");
        for(var i=0;i<resourceAllocationFromLastYear.length;i++){
            //Clone
            resourceAllocation = JSON.parse(JSON.stringify(resourceAllocationFromLastYear[i]));
            //Default values
            resourceAllocation.Id=null;
            var thisYearAvailability = [];
            if(resourceAllocation.allocated){
                //find the same user for this year
                //Hardcoded index 1 for user Id
                //Mitigated by ensuring there are values separated by '_'
                var userId = resourceAllocation.selUser.split('_')[1];
                var masterAvailabilities = component.get("v.resourceAvailabilities");
                thisYearAvailability = masterAvailabilities.filter(avail=> avail.User_Id__c == userId);
            }
            //If availabilitiy found, assign
            if(thisYearAvailability.length>0){
                //hard coded 0 index for the found availability, prechecked using length
                resourceAllocation.Availability = thisYearAvailability[0];
                resourceAllocation.selUser = resourceAllocation.Availability.Id + '_' + resourceAllocation.Availability.User_Id__c;
            }
            //if not found, assign dummy
            else{
                resourceAllocation.Availability = JSON.parse(JSON.stringify(component.get("v.dummyAvailability")));   
                resourceAllocation.selUser = resourceAllocation.Availability.Id + '_' + resourceAllocation.Availability.User_Id__c;
                resourceAllocation.allocated = false;
            }
            
            
            resourceAllocation.months = [];
            resourceAllocation.RecommendedResource = null;
            for(var j=0;j<Months.length;j++){
                var month = {'name' : Months[j], 'percentage':0};
                resourceAllocation.months.push(month);
            }
            resourceAllocations.push(resourceAllocation);
        }
        component.set("v.resourceAllocation",resourceAllocations);
    },
    pushLineItem : function(component, index, allocationToAdd){
        //Push newly created line items
        var ResourceAllocations = component.get("v.resourceAllocation");
        //Add the item in between
        ResourceAllocations.splice(index,0,allocationToAdd);
        component.set("v.resourceAllocation",ResourceAllocations);
    },
    updateDeletionList : function(component, allocationIdVar){       
        //Delete only if the id is present
        if(allocationIdVar!='' && allocationIdVar!=null && allocationIdVar!=undefined){
            var ResourceAllocationToDelete = component.get("v.resourceAllocationToDelete")==null?[]:component.get("v.resourceAllocationToDelete");
            var allocationRecord = {'sobjectType':'PMT_Resource_Allocation__c','Id':allocationIdVar};
            ResourceAllocationToDelete.push(allocationRecord);
            component.set("v.resourceAllocationToDelete",ResourceAllocationToDelete); 
        }
        //else : newly added record and not save to database
    },
    showToast : function(type, title, message) {
        //Generic show toast to display message
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "title": title,
            "type": type,
            "message": message
            
        });
        toastEvent.fire();
    },
    addNewAllocation : function(component, event, helper) {
        //Create a new record
        //Use dummy availability for new record
        //Dummy availability not found, throw error
        if(component.get("v.dummyAvailability")==undefined){
            helper.showToast("error","Availability not found","The resource availability are not setup for this year yet. Get in touch with your admin");
            return;
        }
        var availability = JSON.parse(JSON.stringify(component.get("v.dummyAvailability")));
        var allocation =  {'Id':null, 'allocated':false,'months':[], 'Availability': availability, 'RecommendedResource':null, 'selUser' : availability.Id+'_'+availability.User_Id__c};
        //Assign very first item from list
        //hard coded index mitigated using length check
        allocation.Role = component.get("v.roles").length>0?component.get("v.roles")[0]:'';
        var months= component.get("v.months");
        var month;
        //month var
        for(var i=0;i<months.length;i++)
        {
            month = {'name':months[i], 'percentage':0};
            allocation.months.push(month);
        }
        helper.pushLineItem(component, component.get("v.resourceAllocation").length, allocation);
    }
})