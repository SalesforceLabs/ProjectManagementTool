/*
 * Name : pmt_GanttView
 * Description :  This is the parent component for PMT Gantt to render filters & child components
 * Version : 56
 */

import { LightningElement, api, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import fetchGanttFilters from '@salesforce/apex/PMT_GanttCtrl.getGanttFilters';
const ALL_CONST = 'All';

export default class Pmt_GanttView extends LightningElement {
    @api height; // design attribute to specify height for chart
    @api withfilters; //design attribute to identify filters are applied or not
    @api recordId; //design attribute to store project record id

    //Set default values for filters
    healthSelected = ALL_CONST;
    categorySelected = ALL_CONST;
    programSelected = ALL_CONST;
    systemSelected = ALL_CONST;
    progressSelected = ALL_CONST;

    //Options array for filters 
    healthoptions = [];
    categoryoptions = [];
    systemoptions = [];
    progressoptions = [];
    searchProjects = false;
    error;

    connectedCallback() {
        if (typeof this.recordId == 'undefined') {
            this.recordId = '';
        }
    }

    //wire method to fetch filters to show on PMT Gantt View page
    @wire(fetchGanttFilters)
    getFilters(result) {
        if (result.data) {
            const data = result.data;
            var tempList = [];

            tempList.push({label: ALL_CONST,value: ALL_CONST});
            data.prjhealth.forEach(health => {
                tempList.push({
                    label: health.label,
                    value: health.value
                });
            });
            this.healthoptions = tempList;
            tempList = [];

            tempList.push({label: ALL_CONST,value: ALL_CONST});
            data.prjcategory.forEach(category => {
                tempList.push({
                    label: category.label,
                    value: category.value
                });
            });
            this.categoryoptions = tempList;
            tempList = [];

            tempList.push({label: ALL_CONST,value: ALL_CONST});
            data.sysimpacted.forEach(system => {
                tempList.push({
                    label: system.label,
                    value: system.value
                });
            });
            this.systemoptions = tempList;
            tempList = [];

            tempList.push({label: ALL_CONST,value: ALL_CONST});
            data.prjprogress.forEach(progress => {
                tempList.push({
                    label: progress.label,
                    value: progress.value
                });
            });
            this.progressoptions = tempList;
            tempList = [];

            this.error = undefined;
        } else if (result.error) {
            this.error = result.error;
            this.showToastMessage('Error', result.error, 'error');
        }
    }

    //Set selected filter values to variables
    handleChange(event) {
        this.searchProjects = false;
        switch (event.target.name) {
            case 'projhealth':
                this.healthSelected = event.detail.value;
                break;
            case 'projcategory':
                this.categorySelected = event.detail.value;
                break;
            case 'sysimpacted':
                this.systemSelected = event.detail.value;
                break;
            case 'projprogress':
                this.progressSelected = event.detail.value;
                break;
        }
    }

    //function to condidionally render child components when filters are being changed
    handleSearch() {
        this.searchProjects = true;
    }

    //handler on selection of program to get its Id
    handleProgramSelection(event) {
        var value = event.detail.value.length > 0 ? event.detail.value[0] : ALL_CONST;
        this.programSelected = value;
        this.searchProjects = false;
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