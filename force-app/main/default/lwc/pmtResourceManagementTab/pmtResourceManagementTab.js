/****************************************************************************
 * Name : PmtResourceManagementTab
 * Description : Shows the PMT Resource management component for tab
 *****************************************************************************/
import { LightningElement, wire } from 'lwc';

//fetch data using apex
import getData from '@salesforce/apex/PMT_ResourceManagementCtrl.getResourceAllocations';
import getFilters from '@salesforce/apex/PMT_ResourceManagementCtrl.getFilters';

import userId from '@salesforce/user/Id';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import DEPT_FIELD from '@salesforce/schema/User.Department';

import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';

//To chcek if user has edit access to allocation object
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import ALLOCATION_OBJECT from '@salesforce/schema/PMT_Resource_Allocation__c';

/*************************************** Constants ***************************************/
const BLANK_STRING = '';
const FY_STRING = 'FY';
const MONTH_API_SUFFIX = '__c';
const MONTH_REMAINING_SUFFIX = '_Remaining__c';
const MONTH_ALLOCATION_SUFFIX = '_Allocation__c';
const CELLSTYLE_FIELD = 'cellStyle';

//Column widths for aligning month columns
const SUMMARY_HEADER_COL_WIDTH = 300;
const TEXT_COL_WIDTH = 150;
const ROW_NUMBER_COL_WIDTH_OFFSET = 50;

//TODO : Months in the order of fiscal year
const MONTHS = ['Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec', 'Jan'];

//Summary table headers
const TOTAL_AVAIL_CONST = 'Total Resources Availability';
const TOTAL_ALLOCATION_CONST = 'Total Project Allocations';
const OVERALL_REMAIN_AVAIL_CONST = 'Consilidated Remaining Capacity';
const REMAIN_AVAIL_CONST = 'Remaining Capacity';

//CSS Table Overrides
const PMT_ERROR_STYLE = 'PMT_Error';

//Filter labels/Names for consistency between HTML and javascript
const DEPT_PICKLIST = "PMTDept";
const FISCAL_YEAR_PICKLIST = "FiscalYear";
const MANAGER_LOOKUP = "Manager";
const USER_LOOKUP = "User";
const PROJECT_LOOKUP = "Project";


export default class PmtResourceManagementTab extends LightningElement {
    //Data to show
    rawResourceData;
    resourceAvailabilities = [];
    resourceAllocations = [];
    summary = [];

    //Datatable columns
    summaryColumns;
    resourceAvailabilitiesColumns;
    resourceAllocationsColumns;
    resourceRemainingAvailabilitesColumns;

    //No data found properites
    noDataForAvailabilities;
    noDataForAllocations;

    //Accordion open section names : Initiate to keep all the sections open
    accordionActiveSections = ['Filters', 'Summary'];

    //Filter values
    pmtDepts = [];
    fiscalYears = [];

    //Filter Names
    pmtDeptInputName = DEPT_PICKLIST;
    fiscalYearInputName = FISCAL_YEAR_PICKLIST;
    managerInputName = MANAGER_LOOKUP;
    userInputName = USER_LOOKUP;
    projectInputName = PROJECT_LOOKUP;

    //Selected Filters
    selectedDept;
    selectedFiscalYear;
    //Selected Filters with Default values
    selectedManager = BLANK_STRING;
    selectedUser = BLANK_STRING;
    selectedProject= BLANK_STRING;

    //fiscalYear offset
    isEditable = false;
    
    //Show/hide spinner
    isLoading;

    //Fetch user record to get PMT Department value for the logged in user
    @wire(getRecord, { recordId: userId, fields: [DEPT_FIELD] })
    userInfo;

    //Get the non-lookup picklist filters
    @wire(getFilters)
    setFilters(result){
        var {data, error} = result;
        if(data){
            //PMT Departments
            var tempList = [];
            data[0].forEach(dept => {
                tempList.push({label : dept, value: dept});
            });
            if(tempList.length==0){
                tempList.push({label : '--BLANK--', value: BLANK_STRING});
            }
            this.pmtDepts = tempList;

            //Fiscal Years
            tempList = [];
            data[1].forEach(year => {
                tempList.push({label : year, value: year});
            });
            this.fiscalYears = tempList;
            
            var fiscalStartMonth = data[2][0];
            
            //Set default values for the filters
            var date = new Date();
            var currentYear = FY_STRING;
            if (date.getMonth()+1>=fiscalStartMonth) {
                currentYear = currentYear + (parseInt(((date.getYear() + 1900).toString()).substring(2, 4)) + 1);
            }
            else {
                currentYear = currentYear + ((date.getYear() + 1900).toString()).substring(2, 4);
            }
            this.selectedFiscalYear = currentYear;
            var defaultDept = this.pmtDepts[0]?this.pmtDepts[0].value:'';
            //Set the PMT dept to user's dept if present else the first value
            this.selectedDept = getFieldValue(this.userInfo.data, DEPT_FIELD)?getFieldValue(this.userInfo.data, DEPT_FIELD):defaultDept;


            /**********************************Columns for datatable ******************************************** */
            //Columns for the summary datatable
            this.summaryColumns = [
                //Add offset width for row number col to align month columns
                { label: BLANK_STRING, initialWidth: SUMMARY_HEADER_COL_WIDTH + ROW_NUMBER_COL_WIDTH_OFFSET, fieldName: 'Name', type: 'text', editable: false }
            ];
            //Columns for the availability datatable
            this.resourceAvailabilitiesColumns = [
                {
                    label: 'User', initialWidth: TEXT_COL_WIDTH, fieldName: 'availabilityURL', type: 'url', editable: false, sortable: true,
                    typeAttributes: {
                        label: {
                            fieldName:  'User_Name__c'
                        }, target: '_self'
                    }
                },
                { label: 'Department', initialWidth: TEXT_COL_WIDTH, fieldName:  'User_Department__c', type: 'text', editable: false, sortable: true }
            ];
            //Columns for the allocations datatable
            this.resourceAllocationsColumns = [
                {
                    label: 'User', initialWidth: TEXT_COL_WIDTH, fieldName: 'availabilityURL', type: 'url', editable: false, sortable: true,
                    typeAttributes: {
                        label: {
                            fieldName: 'User_Name__c'
                        }, target: '_self'
                    }
                },
                {
                    label: 'Project', initialWidth: TEXT_COL_WIDTH, fieldName: 'projectURL', type: 'url', editable: false, sortable: true,
                    typeAttributes: {
                        label: {
                            fieldName: 'Project_Name__c'
                        }, target: '_self'
                    }
                }
            ];

            //Columns for the remaining availability datatable
            this.resourceRemainingAvailabilitesColumns = [
                //Add offset width for row number col to align month columns (divide by 2 for equal distribution in 2 columns)
                {
                    label: 'User', initialWidth: TEXT_COL_WIDTH + (ROW_NUMBER_COL_WIDTH_OFFSET / 2), fieldName: 'availabilityURL', type: 'url', editable: false, sortable: true,
                    typeAttributes: {
                        label: {
                            fieldName: 'User_Name__c'
                        }, target: '_self'
                    }
                },
                //Add offset width for row number col to align month columns (divide by 2 for equal distribution in 2 columns)
                { label: 'Department', initialWidth: TEXT_COL_WIDTH + (ROW_NUMBER_COL_WIDTH_OFFSET / 2), fieldName: 'User_Department__c', type: 'text', editable: false, sortable: true }
            ];

            //Fiscal Year Setup
            
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

            //Loop through months for creating additional columns
            fiscalMonths.forEach(month => {
                this.summaryColumns.push({ label: month, fieldName: month, type: 'number', editable: false });
                this.resourceAvailabilitiesColumns.push({ label: month, fieldName:  month + MONTH_API_SUFFIX, type: 'number', editable: this.isEditable, sortable: true, cellAttributes: { alignment: 'center' }  });
                this.resourceAllocationsColumns.push({ label: month, fieldName: month + MONTH_API_SUFFIX, type: 'number', editable: this.isEditable, sortable: true });
                this.resourceRemainingAvailabilitesColumns.push({ label: month, fieldName: month + MONTH_REMAINING_SUFFIX, type: 'number', editable: false, sortable: true, cellAttributes: { class: { fieldName: month + CELLSTYLE_FIELD }, alignment: 'center' } });
            });
            
        }
        else if(error){
            console.log(error);
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error while fetching data',
                    message: error.body.message,
                    variant: 'error'
                })
            );
        }
    }

    //Fetch Allocation object details to check the edit permission on allocation
    @wire(getObjectInfo, { objectApiName: ALLOCATION_OBJECT })
    setColumns({ data, error }) {
        if (data) {
            this.isEditable = data.updateable;
        }
        else if (error) {
            console.log(error);
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error while fetching data',
                    message: error.body.message,
                    variant: 'error'
                })
            );
        }
    }

    /********************************** Data changes ******************************************** */
    @wire(getData, { fiscalYear: '$selectedFiscalYear', selectedDept: '$selectedDept', selectedManagerId: '$selectedManager',selectedUserId : '$selectedUser', selectedProjectId: '$selectedProject'})
    processData(result) {
        //Show spinner
        this.isLoading = true;
        //Store the apex result in order to call refresh Apex
        this.rawResourceData = result;
        
        //To show the message that the data is not present
        this.noDataForAvailabilities = true;
        this.noDataForAllocations = true;

        if (result.data) {
            var allocations = [];
            //Process allocations to generate the links to the project and availability record
            result.data.resourceAllocations.forEach(allocation => {
                var cloneObj = { ...allocation };
                cloneObj.projectURL = '/' + cloneObj[ 'Project__c'];
                cloneObj.availabilityURL = '/' + cloneObj[ 'Resource_Availability__c'];
                allocations.push(cloneObj);
                //Data found : Remove no data flag
                if(this.noDataForAllocations)
                {
                    this.noDataForAllocations = false;
                }
            });
            this.resourceAllocations = allocations;

            var availabilities = [];
            //Process availability to generate the links to the availability record
            result.data.resourceAvailabilities.forEach(allocation => {
                var cloneObj = { ...allocation };
                MONTHS.forEach(month => {
                    cloneObj[month + CELLSTYLE_FIELD] = cloneObj[month + MONTH_REMAINING_SUFFIX] < 0 ? PMT_ERROR_STYLE : BLANK_STRING;
                    cloneObj.availabilityURL = '/' + cloneObj.Id;
                });
                availabilities.push(cloneObj);
                //Data found : Remove no data flag
                if (this.noDataForAvailabilities) {
                    this.noDataForAvailabilities = false;
                }
            });
            this.resourceAvailabilities = availabilities;

            //A variable to create and store summary records
            var summaryVar = [];
            //Initialize the months with 0 value for incrementing the values using records
            summaryVar.push({ Name: TOTAL_AVAIL_CONST, Feb: 0, Mar: 0, Apr: 0, May: 0, Jun: 0, Jul: 0, Aug: 0, Sep: 0, Oct: 0, Nov: 0, Dec: 0, Jan: 0 });
            summaryVar.push({ Name: TOTAL_ALLOCATION_CONST, Feb: 0, Mar: 0, Apr: 0, May: 0, Jun: 0, Jul: 0, Aug: 0, Sep: 0, Oct: 0, Nov: 0, Dec: 0, Jan: 0 });
            summaryVar.push({ Name: OVERALL_REMAIN_AVAIL_CONST, Feb: 0, Mar: 0, Apr: 0, May: 0, Jun: 0, Jul: 0, Aug: 0, Sep: 0, Oct: 0, Nov: 0, Dec: 0, Jan: 0 });
            summaryVar.push({ Name: REMAIN_AVAIL_CONST, Feb: 0, Mar: 0, Apr: 0, May: 0, Jun: 0, Jul: 0, Aug: 0, Sep: 0, Oct: 0, Nov: 0, Dec: 0, Jan: 0 });
            
            //Process data to calculate the summary
            result.data.resourceAvailabilities.forEach(element => {
                //IMP : Hardcoded indexes to generate the data needed in the format for lwc datatable
                MONTHS.forEach(month => {
                    summaryVar[0][month] += element[ month + MONTH_API_SUFFIX];
                    summaryVar[1][month] += element[ month + MONTH_ALLOCATION_SUFFIX];
                    summaryVar[2][month] += element[ month + MONTH_REMAINING_SUFFIX];
                    summaryVar[3][month] += element[ month + MONTH_REMAINING_SUFFIX]>0?element[month + MONTH_REMAINING_SUFFIX]:0;
                });
            });

            this.summary = summaryVar;
            this.isLoading = false;
        }
        else if (result.error) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error while fetching data',
                    message: result.error.body.message,
                    variant: 'error'
                })
            );
        }
    }

    //To refresh the wire method for the data, called after updating the values using inline editing
    refreshData(event) {
        refreshApex(this.rawResourceData);
    }

    /********************************** Filters ******************************************** */
    //Handle the change in picklist filters
    handleChangeInFilters(event) {
        //Show spinner : wire will hide the spinner at the end
        this.isLoading = true;
        //set the value based on the filter changed
        switch (event.target.name) {
            case DEPT_PICKLIST:
                this.selectedDept = event.detail.value;
                break;
            case FISCAL_YEAR_PICKLIST:
                this.selectedFiscalYear = event.detail.value;;
                break;
            default:
                console.log('Invalid Field');
                break;
        }
    }

    //Handle the changes in the lookup filters
    handleChangeInLookup(event){
        //Show spinner : wire will hide the spinner at the end
        this.isLoading = true;
        var value = event.detail.value.length>0?event.detail.value[0]:BLANK_STRING;
        //set the value based on the lookup changed
        switch (event.detail.source) {
            case MANAGER_LOOKUP:
                this.selectedManager = value;
                break;
            case USER_LOOKUP:
                this.selectedUser = value;
                break;
            case PROJECT_LOOKUP:
                this.selectedProject = value;
                break;
            default:
                console.log('Invalid Field');
                break;
        }
    }

}