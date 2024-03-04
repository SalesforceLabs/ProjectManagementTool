/*
 * Name : pmtGanttdata
 * Description : This is the child component to render the Projects/Phases/Tasks data for PMT Gantt
 */
import { LightningElement, api } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { deleteRecord } from 'lightning/uiRecordApi';
import saveTask from '@salesforce/apex/PMT_GanttCtrl.saveTask';
import { NavigationMixin } from 'lightning/navigation';
import LightningConfirm from 'lightning/confirm';

export default class PmtGanttdata extends NavigationMixin(LightningElement) {
    record;
    recordurl;
    recordPageRef;
    @api tempVariable;
    @api startDate;
    @api endDate;
    @api dateIncrement;
    @api
    get project() {
        return this._project;
    }
    set project(_project) {
        this._project = _project;
        this.setVisibility();
    }

    connectedCallback() {
        this.refreshDates(this.startDate, this.endDate, this.dateIncrement);
        this.recordPageRef = {
            type: 'standard__recordPage',
            attributes: {
                recordId: this.record.id,
                actionName: 'view'
            }
        };
        this[NavigationMixin.GenerateUrl](this.recordPageRef)
            .then(url => this.recordurl = url);
    }

    //function to handle edit/delete events on Phases/Tasks
    handleOnClick(event) {
        try {
            var recordId = (event.currentTarget.id).split('-')[0];
            var action;
            if (event.currentTarget.name) {
                action = event.currentTarget.name;
            } else {
                action = 'showdata';
            }
            switch (action) {
                case 'edit':
                    this.navigateToRecord(recordId, 'edit');
                    break;

                case 'delete':
                    LightningConfirm.open({
                        message: 'Are you sure you want to delete the record?',
                        label: 'Delete Record',
                    }).then((result) => {
                        if (result == true) {
                            this.deleteAction(this.record.id);
                        }
                    });
                    break;

                case 'view':
                    event.preventDefault();
                    event.stopPropagation();
                    this[NavigationMixin.Navigate](this.recordPageRef);
                    break;

                default:
                    var param = {
                        recordId: recordId,
                        type: action
                    };
                    const custEvent = new CustomEvent(
                        'calleventhandler', {
                        detail: param
                    });
                    this.dispatchEvent(custEvent);
                    break;
            }
        } catch (Exception) {
            this.showToastMessage('Error', 'Error while clicking on actions', 'error');
        }
    }

    //Nevigate to record edit or view page
    navigateToRecord(recId, action) {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: recId,
                actionName: action
            }
        });
    }

    //Performs delete operation on selected task  
    deleteAction(recordId) {
        deleteRecord(recordId)
            .then(() => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'Record deleted',
                        variant: 'success'
                    })
                );
            })
            .catch(error => {
                this.showToastMessage('Error', 'Error while deleting record, please contact system administrator.', 'error');
            });
    }

    //function to add months based to the date provided
    addMonthsToDate(numOfMonths, date) {
        date.setMonth(date.getMonth() + numOfMonths);
        return date;
    }

    //function to set slots when changing scale or during navigation using < > buttons on Gantt
    @api
    refreshDates(startDate, endDate, dateIncrement) {
        try {
            let dateIncrementNew = dateIncrement;

            if (endDate && dateIncrementNew) {
                let times = [];
                let today = new Date();
                today.setHours(0, 0, 0, 0);
                today = today.getTime();

                if (dateIncrementNew === 92) {
                    this.viewType = "View by Year";
                } else if (dateIncrementNew === 1) {
                    this.viewType = "View by Day";
                } else if (dateIncrementNew === 7) {
                    const timeDiff = Math.abs(endDate.getTime() - startDate.getTime());
                    const diffDays = Math.floor(timeDiff / (1000 * 3600 * 24));
                    if (diffDays === 139) {
                        this.viewType = "View by Month";
                    } else {
                        this.viewType = "View by Week";
                    }
                }

                for (let date = new Date(startDate); date <= endDate; date.setDate(date.getDate() + dateIncrementNew)) {
                    let time = {
                        class: "slds-col lwc-timeslot",
                        start: date.getTime()
                    };

                    if (dateIncrementNew > 1) {
                        let end = new Date(date);


                        if (this.viewType === "View by Year") {
                            end = this.getLastDayOfQuarter(date);
                            dateIncrementNew = this.getDaysBetweenDates(date, end);
                        } else {
                            end.setDate(end.getDate() + dateIncrementNew - 1);
                        }

                        time.end = end.getTime();
                    } else {
                        time.end = date.getTime();
                    }
                    if (today >= time.start && today <= time.end) {
                        time.class += " lwc-is-today";
                    }


                    switch (this.viewType) {
                        case "View by Day":
                            //Adding separator line after Sunday.
                            if (date.getDay() === 0) {
                                time.class = time.class + " lwc-is-week-end";
                            }
                            break;

                        case "View by Week":
                            //Adding separator line after 2 weeks.
                            let year = new Date(new Date(time.end).getFullYear(), 0, 1);
                            let days = Math.floor((new Date(time.end) - year) / (24 * 60 * 60 * 1000));
                            if (Math.ceil((new Date(time.end).getDay() + 1 + days) / 7) % 2 === 0) {
                                time.class = time.class + " lwc-is-week-end";
                            }
                            break;

                        case "View by Month":
                            //Adding separator line if date's month is not same as (date + 7 days) date's month.
                            if (date.getMonth() !== moment(date).add(dateIncrement, "days").toDate().getMonth()) {
                                time.class = time.class + " lwc-is-week-end";
                            }
                            break;
                        case "View by Year":
                            //Adding separator line if date's year is not same as next incremental date's year.
                            if (date.getFullYear() !== moment(date).add(3, "months").toDate().getFullYear()) {
                                time.class = time.class + " lwc-is-week-end";
                            }
                            break;
                        default:
                            break;
                    }

                    times.push(time);
                }
                this.times = times;
                this.startDate = startDate;
                this.endDate = endDate;
                this.dateIncrement = dateIncrementNew;
                this.setVisibility();
            }
        } catch (Exeception) {
            this.showToastMessage("Error", "Error while refreshing dates", "error");
        }
    }


    getLastDayOfQuarter(date) {
        let _date = new Date(date);
        _date = this.addMonthsToDate(2, _date);
        return new Date(_date.getFullYear(), _date.getMonth() + 1, 0);
    }

    getDaysBetweenDates(firstDate, secondDate) {
        let days = 0;
        let dateIncrement = 0;

        for (let date = new Date(firstDate); date < secondDate; date.setDate(date.getDate() + dateIncrement)) {
            dateIncrement = this.getLastdayOfMonth(date);
            days += dateIncrement;
        }
        return days;
    }

    getLastdayOfMonth(date) {
        let _date = new Date(date);
        let returnDate = new Date(_date.getFullYear(), _date.getMonth() + 1, 0);
        return returnDate.getDate();
    }


    getLastdayOfQtr(date) {
        let _date = new Date(date);
        let returnDate = new Date(_date.getFullYear(), _date.getMonth() + 1, 0);
        return returnDate.getDate();
    }

    //function to set necessary stlying once the scale/navigation actions are changed
    setVisibility() {
        var recordToShow = {
            ...this.project
        };
        recordToShow.class = this.calcClass(this.project);
        recordToShow.class = recordToShow.class + ' ' + this.project.id;
        recordToShow.style = this.calcStyle(this.project);
        this.record = recordToShow;
    }

    // calculate record classes
    calcClass(record) {
        let classes = ["slds-is-absolute", "lwc-allocation"];
        return classes.join(" ");
    }

    // calculate record positions/styles
    calcStyle(record) {
        try {
            if (!this.times) {
                return;
            }
            const totalSlots = this.times.length;
            let styles = [
                'left: ' + (record.left / totalSlots) * 100 + '%',
                'right: ' +
                ((totalSlots - (record.right + 1)) / totalSlots) * 100 +
                '%'
            ];

            const colorMap = {
                PMT_Project__c: "#c8c8c8", //gray
                PMT_Phase__c: "#A3A3A3", //dark gray       
                PMT_Task__c: "#3db9d3", //blue           
            };

            var backgroundColor = (record.isMilestone) ? "#D3B33D" : colorMap[record.objAPIName];
            styles.push("background-color: " + backgroundColor);

            if (!isNaN(this.dragInfo.startIndex)) {
                styles.push('pointer-events: auto');
                styles.push('transition: left ease 250ms, right ease 250ms');
            } else {
                styles.push('pointer-events: auto');
                styles.push('transition: none');
            }
            return styles.join('; ');
        } catch (Exeception) {
            this.showToastMessage('Error', 'Error during style calculation', 'error');
        }
    }

    //function to save task record with new start/end dates while dragging
    _saveTask(taskRec) {
        return saveTask(taskRec)
            .then(() => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        message: 'Task Saved Successfully!',
                        variant: "success"
                    })
                );
                var param = {
                    recordId: '',
                    type: 'refreshData'
                };
                const custEvent = new CustomEvent(
                    'calleventhandler', {
                    detail: param
                });
                this.dispatchEvent(custEvent);
            })
            .catch(error => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        message: error.body.message,
                        variant: "error"
                    })
                );
            });
    }

    /*** Drag/Drop ***/
    dragInfo = {};
    handleDragStart(event) {
        try {
            let container = this.template.querySelector('.' + event.currentTarget.dataset.id);
            container.style.opacity = 0;
            setTimeout(function () {
                container.style.pointerEvents = 'none';
            }, 0);
        } catch (Exception) {
            this.showToastMessage('Error', 'Error during drag start', 'error');
        }
    }

    //function to handle left drag event
    handleLeftDragStart(event) {
        this.dragInfo.direction = "left";
        this.handleDragStart(event);
    }

    //function to handle right drag event
    handleRightDragStart(event) {
        this.dragInfo.direction = "right";
        this.handleDragStart(event);
    }

    //function to handle record saving when drag event is ended
    handleDragEnd(event) {
        try {
            event.preventDefault();
            const allocation = this.dragInfo.newAllocation;
            if (typeof allocation != 'undefined') {
                //console.log('here...'+allocation);
                let startDate = new Date(allocation.start_date);
                let endDate = new Date(allocation.end_date);

                console.log('start update...' + startDate);
                console.log('end update...' + endDate);


                if (this.record.objAPIName == 'PMT_Task__c') {
                    this._saveTask({
                        taskId: this.record.id,
                        startDate: startDate,
                        endDate: endDate
                    });
                    this.dragInfo = {};
                }
                else {
                    this.showToastMessage('Warning', 'Please note only Task timeline can be updated from Gantt view', 'warning');
                }
            }

        } catch (Exception) {
            this.showToastMessage('Error', 'Error during drag end', 'error');
        }
    }

    //function to handle drag event for setting start/end dates 
    handleDragEnter(event) {
        try {
            const direction = this.dragInfo.direction;
            const start = new Date(parseInt(event.currentTarget.dataset.start, 10));
            const end = new Date(parseInt(event.currentTarget.dataset.end, 10));
            const index = parseInt(event.currentTarget.dataset.index, 10);

            if (isNaN(this.dragInfo.startIndex)) {
                this.dragInfo.startIndex = index;
            }

            let allocation = JSON.parse(JSON.stringify(this.project));

            switch (direction) {
                case "left":
                    if (index <= allocation.right) {
                        allocation.start_date = this.getYYYYMMDD(start);
                        allocation.left = index;
                    } else {
                        allocation = this.dragInfo.newAllocation;
                    }
                    break;
                case "right":
                    if (index >= allocation.left) {
                        allocation.end_date = this.getYYYYMMDD(end);
                        allocation.right = index;
                    } else {
                        allocation = this.dragInfo.newAllocation;
                    }
                    break;
                default:
                    let deltaIndex = index - this.dragInfo.startIndex;
                    let firstSlot = this.times[0];
                    let startDate = new Date(firstSlot.start);
                    let endDate = new Date(firstSlot.end);
                    allocation.left = allocation.left + deltaIndex;
                    allocation.right = allocation.right + deltaIndex;

                    startDate.setDate(
                        startDate.getDate() + allocation.left * this.dateIncrement
                    );
                    endDate.setDate(
                        endDate.getDate() + allocation.right * this.dateIncrement
                    );
                    allocation.start_date = this.getYYYYMMDD(startDate);
                    allocation.end_date = this.getYYYYMMDD(endDate);
            }
            console.log('allocation.start_date...' + allocation.start_date);
            console.log('allocation.start_date...' + allocation.end_date);
            this.dragInfo.newAllocation = allocation;
            this.template.querySelector("." + allocation.id).style = this.calcStyle(allocation);
        } catch (Exception) {
            this.showToastMessage('Error', 'Please set the Start/End date for Task', 'warning');
        }
    }

    get isPMTTask() {
        return this.record.objAPIName == 'PMT_Task__c' ? true : false;
    }

    get isPMTProject() {
        return this.record.objAPIName == 'PMT_Project__c' ? true : false;
    }

    get isPMTPhase() {
        return this.record.objAPIName == 'PMT_Phase__c' ? true : false;
    }

    //function for date calculation
    getYYYYMMDD(d) {
        try {
            const _d = new Date(d);
            return new Date(_d.getTime() - _d.getTimezoneOffset() * 60 * 1000).toISOString().split('T')[0];
        } catch (Exception) {
            this.showToastMessage('Error', 'Error during date calculation', 'error');
        }
    }

    //show toast message on component
    showToastMessage(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: title,
                message: message,
                variant: variant
            })
        );
    }
}