({
    getResources : function(component, helper) {
        //spinner
        component.set("v.isLoading",true);
        //Server call to get the data
        var action = component.get("c.getResourceDetailsWrapper");
        action.setParams({
            project : component.get("v.projectRecord")
        });
        action.setCallback(this,function(response){
            if(response.getState() ==='SUCCESS'){
                if($A.util.isEmpty(response.getReturnValue())){
                    component.set("v.isLoading",false);
                	helper.showToast('Info', 'Warning','No record found.')
                }else{
                    var responseVal = response.getReturnValue();
                    helper.handleServerResponse(component, helper, responseVal);
                }
            }
            else{
                component.set("v.isLoading",false);
                helper.showToast('Error', 'Error while loading','An error occured while loading the records. Try to refresh, if error still persists, contact system admin.')
            }
        });
        $A.enqueueAction(action);
    },
    handleServerResponse : function(component, helper, responseVal){
        var availabilities;
        //Set Resource Availabilties
        component.set("v.fiscalYearOffset", responseVal.fiscalYearOffset);
        component.set("v.years", helper.getMonthsForProject(component, helper));
        component.set("v.roles", responseVal.roles);
        
        //Transform : User, month+year, availabilities  
        var allocations = helper.transformAllocations(component, responseVal.ResourceAllocations,responseVal.ResourceAvailabilities, responseVal.dummyAvailabilities);
        component.set("v.resourceAllocation",allocations);
        //is resource allocation records creatable
        component.set("v.isEditable", responseVal.isCreatable);
        
        //Keep the current year section open
        var date = new Date();
        var currentYear ='FY';
        
        //if less than start , use previous cal year to calc
        if((date.getMonth()+1)>=responseVal.fiscalYearOffset){
            currentYear = currentYear + (parseInt(((date.getYear()+1900).toString()).substring(2,4))+1);
        }
        //else use current calendar year
        else{
            currentYear = currentYear + ((date.getYear()+1900).toString()).substring(2,4);
        }
        // Bug with standard functionality, delayed attribute setting was required
        setTimeout(function(){
            component.find("accordion").set('v.activeSectionName', currentYear);
            component.set("v.isLoading",false);
        }, 10);
    },
    transformAllocations : function(component, ResourceAllocations, ResourceAvailabilities, dummyAvailabilities)
    {
        var Years = component.get("v.years");
        var transformedYears = [];
        var year;
        //Year loop
        for(var k=0;k<Years.length;k++){
            var dummyAvailability=undefined;
            
            //Assign dummy availability
            for(var i=0;i<dummyAvailabilities.length;i++){
                if(dummyAvailabilities[i].Fiscal_Year__c==Years[k].Name){
                    dummyAvailability = dummyAvailabilities[i];
                    break;
                }
            }
            
            //Generate year structure
            year = {'Name' : Years[k].Name, 'Records':[], 'Months':Years[k].months, 'DummyAvailability' : dummyAvailability, 'Availabilities' : []};
            year.Availabilities = ResourceAvailabilities.filter(avail => avail.Fiscal_Year__c==Years[k].Name);	
            
            var allocation, transformation, months, month;
            //Allocation loop
            //year => allocation
            for(var i=0;i<ResourceAllocations.length;i++)
            {
                allocation = ResourceAllocations[i];
                if(allocation.Fiscal_Year__c==Years[k].Name)
                {
                    transformation = {'Id':allocation.Id,'Role':allocation.Role__c, 'Availability':allocation.Resource_Availability__r};
                    months = component.get("v.years")[k].months;
                    transformation.months=[];
                    //month loop
                    //year => allocation => monthly allocation
                    for(var j=0;j<months.length;j++)
                    {
                        month = {'name':months[j],'percentage': allocation['' + months[j]+'__c']};
                        transformation.months.push(month);
                    }
                    //Current allocation to show
                    transformation.allocated = false;
                    //if dummy is not allocated
                    if(allocation.Resource_Availability__r.is_Dummy_Availability__c)
                    {
                       transformation.selUser = dummyAvailability.Id + '_' + dummyAvailability.User_Id__c;
                    }
                    else
                    {
                        transformation.selUser = allocation.Resource_Availability__r.Id + '_' + allocation.Resource_Availability__r.User_Id__c;
                        transformation.allocated = true;
                        
                    }
                    year.Records.push(transformation);
                }
            }
            transformedYears.push(year);
        }
        return transformedYears;
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
    getMonthsForProject : function(component, helper){
        //Year wise months
        var Start = new Date(component.get("v.projectRecord").Kickoff_formula__c);
        var End = new Date(component.get("v.projectRecord").Deadline_formula__c);
        var StartFiscal = parseInt(component.get("v.projectRecord").Start_Fiscal_Year__c.substring(2));
        var EndFiscal = parseInt(component.get("v.projectRecord").End_Fiscal_Year__c.substring(2));
        var difference = EndFiscal-StartFiscal;
        var years = [];
        var year, startMonth, endMonth;
        var fiscalStartMonth = component.get("v.fiscalYearOffset")-1;
        
        const MONTHS_IN_YEAR = 12;
        //loop for year
        for(var i=0;i<=difference;i++)
        {
            year = {'Name':'FY'+ parseInt(StartFiscal+i),'Year':StartFiscal+i, months:[]};
            //Set start and end month of the year
            //first and only year
            if(i==0 && i==difference){
                startMonth = Start.getMonth()-fiscalStartMonth;
                endMonth = End.getMonth()-fiscalStartMonth;
                if(Start.getMonth()<fiscalStartMonth){
                	startMonth=MONTHS_IN_YEAR-fiscalStartMonth+Start.getMonth();
                }
                if(End.getMonth()<fiscalStartMonth){
                	endMonth=MONTHS_IN_YEAR-fiscalStartMonth+End.getMonth();
				}
                //Change end
            }
            //first year in the series
            else if(i==0){
                startMonth = Start.getMonth()-fiscalStartMonth;
                endMonth = MONTHS_IN_YEAR-1; //End month of the year : 11th index in array
                if(Start.getMonth()==0){
                    startMonth=12-fiscalStartMonth;
                    endMonth=MONTHS_IN_YEAR-1;
                }
            }
            //last year in the series
                else if(i==difference){
                    startMonth = 0; //Start of the year
                    endMonth = End.getMonth()-fiscalStartMonth;
                    if(End.getMonth()==0){
                        endMonth=MONTHS_IN_YEAR-fiscalStartMonth;
                    }
                }
            //Middle years in the series
                    else
                    {
                        startMonth = 0;
                        endMonth = MONTHS_IN_YEAR-1;
                    }

            //Special Scenario
            if(Start.getMonth()==End.getMonth()  && Start.getYear()==End.getYear()){
                //if start and end month are same
                if(Start.getMonth()==0){
                    startMonth = endMonth = MONTHS_IN_YEAR-fiscalStartMonth;
                }
                else{
                    startMonth = endMonth = Start.getMonth()-fiscalStartMonth;
                }
            }
           
            //Setup a list of months based on start and end
            year.months = helper.getMonths(component, startMonth, endMonth);
            years.push(year);
        }
        return years;
    },
    getMonths : function(component, startMonth, endMonth){
        var fiscalStartMonth = component.get("v.fiscalYearOffset");
        //startMonth +=1;
        //endMonth +=1;
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
        var monthsFromProject = [];
        for(var k=startMonth;k<=endMonth;k++)
        {
            monthsFromProject.push(fiscalMonths[k%12]);
        }
        return monthsFromProject;
    },
    saveAllocations: function(component, helper){
        //Save the changes including new allocations and old to delete (upsert + delete)
        component.set("v.isLoading",true);
        //Transform JSON to Sobject format for saving
        var allocationsToSave = helper.transformationAllocationToSObject(component);
        var confirmation = true;
        
        //Action server call
        if(component.get("v.duplicatesFound")){
            confirmation = confirm('Same resource has been allocated more than once to this project. Do you want to continue?');
        }
        if(confirmation){
            var action = component.get("c.upsertDeleteAllocation");
            action.setParams({
                'allocationsToSave' : allocationsToSave,
                'allocationsToDelete' : component.get("v.resourceAllocationToDelete"),
                'project' : component.get("v.projectRecord")
            });
            action.setCallback(this,function(response){
                if(response.getState() ==='SUCCESS'){
                    helper.showToast('Success', 'Allocation Saved','Allocation information has been saved sucessfully');
                    component.set("v.resourceAllocationToDelete",null);
                    //There is bug that this method is unable to render data on the read only mode                    
                    //As a workaround calling the getResources again
                    helper.getResources(component,helper);
                    component.set("v.isReadOnly",true);
                }
                else {
                    var errors = response.getError();
                    if (errors) {
                        if (errors[0] && errors[0].message) {
                            // log the error passed in to AuraHandledException
                            helper.showToast('Error', 'Error while saving', errors[0].message);
                        }
                        else if(errors[0] &&  errors[0].pageErrors){
                            helper.showToast('Error', 'Error while saving', errors[0].pageErrors[0].message);
                        }
                    } else {
                        helper.showToast('Error', 'Error while saving','Error while saving the records. Try saving again, if error still persists, contact system admin.')
                    }
                    
                    component.set("v.isLoading",false);
                }
            });
            $A.enqueueAction(action);
        }
        else{
            component.set("v.isLoading",false);
        }
    },
    transformationAllocationToSObject : function(component){
        //Covert the custom JSON to sobjects for saving
        var allocationsByYear = component.get("v.resourceAllocation");
        var allocationsToSave = [];
        var allocations, allocationRecord, months, allocationSet;
        
        //year loop
        for(var k=0;k<allocationsByYear.length;k++){
            allocations = allocationsByYear[k].Records;
            //allocation loop
            //Year => allocation
            allocationSet = new Set();
            for(var i=0;i<allocations.length;i++){
                if(allocations[i].Id!==undefined){                    
                    component.set("v.duplicatesFound",false)
                    //END: ToDO
                    
                    allocationRecord = {'sobjectType':'PMT_Resource_Allocation__c','Id':allocations[i].Id,'Resource_Availability__c':allocations[i].Availability.Id,'Role__c':allocations[i].Role,'Project__c':component.get("v.recordId")};
                    months = allocations[i].months;
                    //month loop
                    //Year => Allocation => Monthly allocation
                    for(var j=0;j<months.length;j++){
                        allocationRecord['' + months[j].name+'__c'] = months[j].percentage;
                    }
                    allocationsToSave.push(allocationRecord);
                }
            }
        }
        return allocationsToSave;
    },
    showToast : function(type, title, message) {
        //Generic show toast for messages
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "title": title,
            "type": type,
            "message": message
            
        });
        toastEvent.fire();
    },
})