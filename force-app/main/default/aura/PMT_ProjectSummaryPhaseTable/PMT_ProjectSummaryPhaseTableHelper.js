({
    showToast: function (type, message) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "title": type + "!",
            "type": type,
            "message": message
        });
        toastEvent.fire();
    },

    getRecords: function (component, event, helper) {
        component.set("v.isLoading", true);
        var action = component.get("c.getSummaryWrapper");
        action.setParams({
            recordId: component.get("v.recordId")
        });
        // Set up the callback
        action.setCallback(this, $A.getCallback(function (response) {
            var state = response.getState();

            if (state === "SUCCESS") {
                //if successful stores query results in Lists
                var data = response.getReturnValue();
                component.set('v.phases', data.phasesList);
                component.set('v.lateTasks', data.lateTaskList);
                component.set('v.tasks', data.onGoingTaskList);
                component.set('v.milestoneTasks', data.milestoneTaskList);
                component.set("v.fiscalYearOffset", data.fiscalMonthOffset);
                helper.filterWeek(component, event, helper);
            } else if (state === 'ERROR') {
                var errors = response.getError();
                var message = '';
                if (errors && Array.isArray(errors) && errors.length > 0) {
                    message += errors[0].message;
                }
                helper.showToast("Error", message);
            } else {
                helper.showToast("Error", "Something went wrong, please contact system administrator.");
            }
            component.set("v.isLoading", false);
        }));
        $A.enqueueAction(action);
    },

    filterWeek: function (component, event, helper) {
        var currStart = new Date; // get current date
        var currEnd = new Date;
        var currNextStart = new Date;
        var currNextEnd = new Date;
        var monthDay = currStart.getDate(); //get day of the month
        var weekDay = currStart.getDay(); //get day of the week
        var start = monthDay - weekDay + 1; //get first day of the week
        var end = start + 6; //get last day of the week
        var nextStart = end + 1; //get first day of next week 
        var nextEnd = nextStart + 6; //get last day of next week

        //set dates to ISO format YYYY-MM-DDTimeStamp
        var startDay = new Date(currStart.setDate(start)).toISOString();
        var endDay = new Date(currEnd.setDate(end)).toISOString();
        var nextStartDay = new Date(currNextStart.setDate(nextStart)).toISOString();
        var nextEndDay = new Date(currNextEnd.setDate(nextEnd)).toISOString();

        //Assign dates to component attributes in format YYYY-MM-DD
        component.set("v.startCurrent", startDay.substring(0, 10));
        component.set("v.endCurrent", endDay.substring(0, 10));
        component.set("v.startNext", nextStartDay.substring(0, 10));
        component.set("v.endNext", nextEndDay.substring(0, 10));

        //Filter columns
        helper.filterTasks(component);

    },

    filterMonth: function (component, event, helper) {
        var curr = new Date; // get current date
        var month = curr.getMonth(); //get current month
        var year = curr.getFullYear(); //get current year
        var start = 1; //get first day of the month
        var end = new Date(year, month + 1, 0).getDate(); //get last day of the month
        var nextStart = end + 1; //get first day of next month
        var nextEnd = new Date(year, month + 2, 0).getDate(); //get last day of next month

        //set dates to ISO format YYYY-MM-DDTimeStamp
        var startDay = new Date(curr.setDate(start)).toISOString();
        var endDay = new Date(curr.setDate(end)).toISOString();
        var nextStartDay = new Date(curr.setDate(nextStart)).toISOString();
        var nextEndDay = new Date(curr.setDate(nextEnd)).toISOString();

        //Assign dates to component attributes in format YYYY-MM-DD
        component.set("v.startCurrent", startDay.substring(0, 10));
        component.set("v.endCurrent", endDay.substring(0, 10));
        component.set("v.startNext", nextStartDay.substring(0, 10));
        component.set("v.endNext", nextEndDay.substring(0, 10));

        //Filter columns
        helper.filterTasks(component);

    },

    filterQuarter: function (component, event, helper) {
        var fiscalMonthOffset = component.get("v.fiscalYearOffset") - 1; //JS starts count from 0
        var curr = new Date(); // get current date
        var year = curr.getFullYear(); //get current year

        //Calculate Q1
        var startQ1 = new Date(year, fiscalMonthOffset, 1)
        var endQ1 = helper.add_months(startQ1, 3);
        endQ1.setDate(0);

        //Calculate Q2
        var startQ2 = helper.add_months(new Date(year, fiscalMonthOffset, 1), 3);
        var endQ2 = helper.add_months(startQ2, 3);
        endQ2.setDate(0);


        //Calculate Q3
        var startQ3 = helper.add_months(new Date(year, fiscalMonthOffset, 1), 6);
        var endQ3 = helper.add_months(startQ3, 3);
        endQ3.setDate(0);


        //Calculate Q4
        var startQ4 = helper.add_months(new Date(year, fiscalMonthOffset, 1), 9);
        var endQ4 = helper.add_months(startQ4, 3);
        endQ4.setDate(0);

        if (curr >= startQ1 && curr <= endQ1) {
            component.set("v.startCurrent", startQ1);
            component.set("v.endCurrent", endQ1);

            component.set("v.startNext", startQ2);
            component.set("v.endNext", endQ2);
        }
        else if (curr >= startQ2 && curr <= endQ2) {
            component.set("v.startCurrent", startQ2);
            component.set("v.endCurrent", endQ2);

            component.set("v.startNext", startQ3);
            component.set("v.endNext", endQ3);
        }
        else if (curr >= startQ3 && curr <= endQ3) {
            component.set("v.startCurrent", startQ3);
            component.set("v.endCurrent", endQ3);

            component.set("v.startNext", startQ4);
            component.set("v.endNext", endQ4);
        }
        else {
            component.set("v.startCurrent", startQ4);
            component.set("v.endCurrent", endQ4);

            //Calculate Q1 - Next Year
            var startQ1Next = helper.add_months(new Date(year, fiscalMonthOffset, 1), 12);
            var endQ1Next = helper.add_months(startQ1Next, 3);
            endQ1Next.setDate(0);

            component.set("v.startNext", startQ1Next);
            component.set("v.endNext", endQ1Next);
        }
        //Filter columns
        helper.filterTasks(component);
    },

    add_months: function (dt, n) {
        var d = new Date(dt.getFullYear(), dt.getMonth(),dt.getDate());
        return new Date(d.setMonth(d.getMonth() + n));
    },

    filterTasks: function (component) {
        //Get relative dates for filter
        var startCurrent = new Date(component.get("v.startCurrent"));
        var endCurrent = new Date(component.get("v.endCurrent"));
        var startNext = new Date(component.get("v.startNext"));
        var endNext = new Date(component.get("v.endNext"));

        //Get current period tasks -> Due Date in current period
        var filteredCurrent = component.get('v.tasks');
        filteredCurrent.forEach(row => {
            row.Due_Date__c = new Date(row.Due_Date__c);
            row.Start_Date__c = new Date(row.Start_Date__c);
        });
        filteredCurrent = filteredCurrent.filter(row => row.Due_Date__c >= startCurrent && row.Due_Date__c <= endCurrent);
        component.set("v.currentTasks", filteredCurrent);

        //Get next period tasks -> Due date in next period
        var filteredNext = component.get('v.tasks');
        filteredNext = filteredNext.filter(row => row.Due_Date__c >= startNext && row.Due_Date__c <= endNext);
        component.set("v.nextTasks", filteredNext);

        //Get In Progress Tasks -> Start date in or before current period with Due date after Next period
        var filteredInProgress = component.get('v.tasks');
        filteredInProgress = filteredInProgress.filter(row => row.Start_Date__c <= endCurrent && row.Due_Date__c > endNext);
        component.set("v.onGoingTasks", filteredInProgress);
    }
})