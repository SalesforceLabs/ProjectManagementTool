/****************************************************************************
 * Name : GenLwcDatatable
 * Description : Generates a generic datatable with sorting and inline editing
 *****************************************************************************/

import { LightningElement, api } from 'lwc';
//To show success/error message
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
//to update the records
import { updateRecord } from 'lightning/uiRecordApi';
import {NavigationMixin} from 'lightning/navigation';

export default class GenLwcDatatable extends NavigationMixin(LightningElement){
    //Columns to be displayed in the datatable
    @api columns;
    //Data to be displayed in the datatable
    @api tableData;
    //Key field for indentifying the rows
    @api keyField;
    //Store the field name for the sort
    @api sortedBy;

    //Default sort order for the datatable
    defaultSortDirection = 'asc';
    //Store sorting direction on click of the user
    sortDirection = 'asc';

    //Shows the spinner whene data is being saved
    isLoading = false;

    //Sort method for the datatable
    sortBy(field, reverse, primer) {
        const key = primer
            ? function (x) {
                return primer(x[field]);
            }
            : function (x) {
                return x[field];
            };

        return function (a, b) {
            a = key(a) ? key(a) : '';
            b = key(b) ? key(b) : '';
            return reverse * ((a > b) - (b > a));
        };
    }

    //Datatable Util : Handle sorting
    onHandleSort(event) {
        const { fieldName: sortedBy, sortDirection } = event.detail;
        const cloneData = [...this.tableData];

        cloneData.sort(this.sortBy(sortedBy, sortDirection === 'asc' ? 1 : -1));
        this.tableData = cloneData;
        this.sortDirection = sortDirection;
        this.sortedBy = sortedBy;
    }

    //Use updateRecord to update the records
    handleSave(event) {
        //show loading sign
        this.isLoading = true;

        //Process data
        const recordInputs = event.detail.draftValues.slice().map(draft => {
            const fields = Object.assign({}, draft);
            return { fields };
        });

        const promises = recordInputs.map(recordInput => updateRecord(recordInput));
        Promise.all(promises).then(records => {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: 'Records updated',
                    variant: 'success'
                })
            );
            // Clear all draft values
            this.draftValues = [];
            // Create event to refresh the data using @wire in parent component
            const refreshEvent = new CustomEvent("refreshevent");

            // Dispatches the event.
            this.dispatchEvent(refreshEvent);
            //Force reset the edit highlighting
            this.columns = [...this.columns];
            //hide loading sign
            this.isLoading = false;
        }).catch(error => {
            // Handle error
            console.log(JSON.stringify(error));
            var message = error.body.message;
            console.log(JSON.stringify(error.body.output.fieldErrors));
            for(var field in error.body.output.fieldErrors){
                error.body.output.fieldErrors[field].forEach(fieldError => {
                    message += ' ' + fieldError.message;
                });
            }
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error while updating data',
                    message: message,
                    variant: 'error'
                })
            );
            //hide loading sign
            this.isLoading = false;
        });
    }

    //handle row action on datatable
    handleRowAction(event){
        const actionName = event.detail.action.name;
        const row = event.detail.row; 
        switch(actionName){
            case 'view' :
                    this.navigateToRecord(row, 'view');
                    break;
            case 'edit' :
                    this.navigateToRecord(row, 'edit');
                    break;
            default:
                    console.log('No Actions found');
                    break;
        }
    }

    //handle navigation as per action mentioned
    navigateToRecord(row, action){
        this[NavigationMixin.Navigate]({
            type : 'standard__recordPage',
            attributes : {
                recordId : row.Id,
                actionName : action
            }
        });
    }
}