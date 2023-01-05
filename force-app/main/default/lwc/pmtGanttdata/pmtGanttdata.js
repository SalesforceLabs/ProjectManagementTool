/*
 * Name : pmtGanttdata
 * Description : This is the child component to render the Projects/Phases/Tasks data for PMT Gantt
 */
import {LightningElement,api} from "lwc";
import {ShowToastEvent} from "lightning/platformShowToastEvent";
import {deleteRecord} from 'lightning/uiRecordApi';
import saveTask from '@salesforce/apex/PMT_GanttCtrl.saveTask';
import {NavigationMixin} from 'lightning/navigation';
import LightningConfirm from 'lightning/confirm';

export default class PmtGanttdata extends NavigationMixin(LightningElement) {
    record;
    recordurl;
    recordPageRef;
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
            var dateIncrementNew = dateIncrement;
            var typeCheck = false;
 
            if (endDate && endDate && dateIncrementNew) {
                let times = [];
                let today = new Date();
                today.setHours(0, 0, 0, 0);
                today = today.getTime();
 
                if (dateIncrementNew == 92) {
                    typeCheck = true;
                }
 
                for (let date = new Date(startDate); date <= endDate; date.setDate(date.getDate() + dateIncrementNew)) {
 
                    if (typeCheck) {
                        var tempDate = new Date(date);
                        var newDate = this.addMonthsToDate(3, tempDate);
                        let difference = newDate.getTime() - date.getTime();
                        let totalDays = Math.ceil(difference / (1000 * 3600 * 24));
                        dateIncrementNew = totalDays;
                    }
 
                    let time = {
                        class: "slds-col lwc-timeslot",
                        start: date.getTime()
                    };
 
                    if (dateIncrementNew > 1) {
                        let end = new Date(date);
                        end.setDate(end.getDate() + dateIncrementNew - 1);
                        time.end = end.getTime();
 
                    } else {
                        time.end = date.getTime();
 
                        if (times.length % 7 === 6) {
                            time.class += " lwc-is-week-end";
                        }
                    }
                    if (today >= time.start && today <= time.end) {
                        time.class += " lwc-is-today";
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
            this.showToastMessage('Error', 'Error while refreshing dates', 'error');
        }
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
            setTimeout(function() {
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
            if(typeof allocation != 'undefined'){
                //console.log('here...'+allocation);
                let startDate = new Date(allocation.start_date);
            let endDate = new Date(allocation.end_date);

            console.log('start update...'+startDate);
            console.log('end update...'+endDate);


            if(this.record.objAPIName=='PMT_Task__c'){
                 this._saveTask({
                     taskId: this.record.id,
                     startDate: startDate,
                     endDate: endDate
                 });
             this.dragInfo = {};
            }
            else{
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
            console.log('allocation.start_date...'+allocation.start_date);
            console.log('allocation.start_date...'+allocation.end_date);
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