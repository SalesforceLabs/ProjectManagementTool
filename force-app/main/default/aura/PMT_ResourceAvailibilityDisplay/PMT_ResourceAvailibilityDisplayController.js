({
    doInit: function (component, event, helper) {
        var action = component.get("c.getPMTSettings");
        action.setCallback(this, function (response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var fiscalStartMonth = response.getReturnValue().Start_Month_of_Fiscal_Year__c;
                component.set("v.fiscalYearOffset", fiscalStartMonth);

                const monthNames = ["Jan", "Feb", "Mar", "Apr", "May", "Jun",
                    "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
                ];
                var fiscalMonths = [];
                //Add months from the current calendar yearf
                for (var i = fiscalStartMonth - 1; i < monthNames.length; i++) {
                    fiscalMonths.push(monthNames[i]);
                }
                //Add remaining fiscal year months from next calendar year
                for (var i = 0; i < fiscalStartMonth - 1; i++) {
                    fiscalMonths.push(monthNames[i]);
                }
                component.set("v.monthNames", fiscalMonths);

                //Process avail record to create loop
                var resAvail = component.get("v.availRecord");
                var allocations = [];
                var capacities = [];
                var availabilities = [];
                var transformedResourceAvail = { allocations: [], capacities: [], availabilities: [] };

                for (var j = 0; j < fiscalMonths.length; j++) {
                    var fieldName =  fiscalMonths[j] + '_Allocation__c';
                    allocations.push(resAvail[fieldName]);

                    fieldName = fiscalMonths[j] + '__c';
                    capacities.push(resAvail[fieldName]);

                    fieldName = fiscalMonths[j] + '_Remaining__c';
                    availabilities.push(resAvail[fieldName]);
                }
                transformedResourceAvail.allocations = allocations;
                transformedResourceAvail.capacities = capacities;
                transformedResourceAvail.availabilities = availabilities;
                component.set("v.resourceAvailability", transformedResourceAvail);
            }
            else {
                //Assigning default value in case of error
                component.set("v.fiscalYearOffset", 1);
                console.log("", "Some error has occured. Please refresh the page, if error persists. Contact system administrator", "ERROR");
            }
        });
        $A.enqueueAction(action);
    }
})