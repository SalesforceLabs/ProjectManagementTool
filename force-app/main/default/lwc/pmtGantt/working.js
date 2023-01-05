/*
 * Name : PMT_Gantt
 * Description : LWC Component to render headers & process the data required for Gantt view
 * Version : 56
 */
import { LightningElement, api, track, wire } from "lwc";
import { refreshApex } from "@salesforce/apex";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { loadScript } from "lightning/platformResourceLoader";
import { encodeDefaultFieldValues } from 'lightning/pageReferenceUtils';
import { NavigationMixin } from 'lightning/navigation';
import fetchGanttData from '@salesforce/apex/PMT_GanttCtrl.fetchGanttData';
import ganttJS from "@salesforce/resourceUrl/PMT_Gantt";

export default class pmtGantt extends NavigationMixin(LightningElement) {
	@api projectId;
	@api projectProgress;
	@api projectHealth;
	@api systemImpacted;
	@api projectCategory;
	@api programSelected;
	@api recordId;
	@api defaultView; // design attribute
	@api objectApiName;
	@track startDate;
	@track endDate;
	@track myprojflag;
	@track mytaskflag;
	@track followprojflag;
	@track isResourceView;
	@track isProjectView;
	@track isRecordTypeView;
	@track startDateUTC; // sending to backend using time
	@track endDateUTC; // sending to backend using time
	@track formattedStartDate; // Title (Date Range)
	@track formattedEndDate; // Title (Date Range)
	@track dates = []; // Dates (Header)

	wiredGanttResult; // Wired Apex result so it can be refreshed programmatically
	error;
	dataToShow = [];
	dataBkp = [];
	scaleType = false;
	isExpandedCheck = false;
	isExpandAll = false;
	isLoading = false;
	filtersCheck = false;
	filtersToShow = false;
	toastCheck = false;
	dateShift = 7; // determines how many days we shift by
	newStartDate;
	selectedView = 'View by Week';
	dataStyle;
	headerStyle;

	//@track datePickerString; // Date Navigation
	@track view = {
		// View Select
		options: [{
				label: "View by Day",
				value: "1/20"
			},
			{
				label: "View by Week",
				value: "7/6"
			},
			{
				label: "View by Month",
				value: "7/20"
			},
			{
				label: "View by Year",
				value: "4/16"
			}
		],
		slotSize: 1,
		slots: 1
	};

	connectedCallback() {
		if (this.projectId != '') {
			this.dataStyle = "width:100%;";
			this.headerStyle = "width:100%; position: sticky; top:0px; z-index:100; background-color: white;"
		} else {
			this.filtersToShow = true;
			this.dataStyle = "width:100%";
			this.headerStyle = "width:100%; position: sticky; top:0px; z-index:100; background-color: white;"
		}

		Promise.all([
			loadScript(this, ganttJS)
		]).then(() => {
			switch (this.defaultView) {
				case "View by Day":
					this.setView("1/20");
					break;
				default:
					this.setView("7/20");
			}
			this.setStartDate(new Date());
			refreshApex(this.wiredGanttResult);
		});
	}

	//function to set startDate for the headers based on scale selected
	setStartDate(_startDate) {
		try {
			if (_startDate instanceof Date && !isNaN(_startDate)) {
				if (this.scaleType) {
					this.startDate = _startDate;
				} else {
					_startDate.setHours(0, 0, 0, 0);
					this.datePickerString = _startDate.toISOString();
					this.startDate = moment(_startDate).day(1).toDate();
				}

				this.startDateUTC =
					moment(this.startDate)
					.utc()
					.valueOf() -
					moment(this.startDate).utcOffset() * 60 * 1000 +
					"";
				this.formattedStartDate = this.startDate.toLocaleDateString();
				this.setDateHeaders();

			} else {
				this.dispatchEvent(
					new ShowToastEvent({
						message: "Invalid Date",
						variant: "error"
					})
				);
			}
		} catch (Exception) {
			this.showToastMessage('Error', 'Error while setting start date', 'error');
		}
	}

	//function to get first date of the requested year
	getFirstDayOfYear(year) {
		return new Date(year, 0, 1);
	}

	//function to get last date of the requested year
	getLastDayOfYear(year) {
		return new Date(year, 11, 31);
	}

	//function to set Start/End Dates, Gantt Columns & required Slots based on the Scale selected
	setDateHeaders() {
		try {
			this.newStartDate = this.startDate;
			var headerType = "MMMM";
			var headerFormat = "YYYYMM";
			var incrementType = "days";
			var slotEndDateCalc = this.view.slotSize - 1;
			var skipValue = this.view.slotSize;

			if (this.view.slots == '16') {
				headerType = "YYYY";
				this.scaleType = true;
				incrementType = "months";
				skipValue = 3;
				slotEndDateCalc = 3;
				headerFormat = "YYYY";
				const currentYear = this.startDate.getFullYear();
				this.newStartDate = this.getFirstDayOfYear(currentYear);
				this.endDate = this.getLastDayOfYear(currentYear + 3);
				this.view.slotSize = 92;
				this.startDate = this.newStartDate;
			} else {
				this.scaleType = false;
				this.endDate = moment(this.newStartDate)
					.add(this.view.slots * this.view.slotSize - 1, "days")
					.toDate();
				this.endDateUTC =
					moment(this.endDate)
					.utc()
					.valueOf() -
					moment(this.endDate).utcOffset() * 60 * 1000 +
					"";
			}

			this.formattedStartDate = this.newStartDate.toLocaleDateString();
			this.formattedEndDate = this.endDate.toLocaleDateString();
			let today = new Date();
			today.setHours(0, 0, 0, 0);
			today = today.getTime();

			let dates = {};

			for (let date = moment(this.newStartDate); date <= moment(this.endDate); date.add(skipValue, incrementType)) {
				let index = date.format(headerFormat);

				if (!dates[index]) {
					dates[index] = {
						dayName: '',
						name: date.format(headerType),
						days: []
					};
				}

				let day = {
					class: "slds-col slds-p-vertical_x-small slds-m-top_x-small lwc-timeline_day",
					label: date.format("M/D"),
					start: date.toDate()
				};

				if (this.view.slotSize > 1) {
					let end = moment(date).add(slotEndDateCalc, incrementType);
					day.end = end.toDate();
				} else {
					day.end = date.toDate();
					day.dayName = date.format("ddd");
					if (date.day() === 0) {
						day.class = day.class + " lwc-is-week-end";
					}
				}

				if (today >= day.start && today <= day.end) {
					day.class += " lwc-is-today";
				}

				dates[index].days.push(day);
				dates[index].style = "width: calc(" + dates[index].days.length + "/" + this.view.slots + "*100%)";
			}

			// reorder index
			this.dates = Object.values(dates);

			Array.from(
				this.template.querySelectorAll("c-pmt-ganttdata")
			).forEach(resource => {
				resource.refreshDates(this.newStartDate, this.endDate, this.view.slotSize);
			});
		} catch (Exception) {
			this.showToastMessage('Error', 'Error while date headers', 'error');
		}
	}

	//function to navigate to default scale values based on user selection
	navigateToToday() {
		this.isLoading = true;
		if (this.scaleType) {
			let currentDate = new Date();
			const currentYear = currentDate.getFullYear();
			this.setStartDate(this.getFirstDayOfYear(currentYear));
		} else {
			this.setStartDate(new Date());
		}
		this.isLoading = false;
	}

	//function to navigate to previous set of Date ranges when user click on "<" icon
	navigateToPrevious() {
		this.isLoading = true;
		let _startDate = this.startDate;

		if (this.scaleType) {
			let currentYear = this.newStartDate.getFullYear();
			let newDate = this.getFirstDayOfYear(currentYear - 1);
			_startDate = newDate;
		} else {
			this.dateShift = 7;
			_startDate.setDate(_startDate.getDate() - this.dateShift);
		}
		this.setStartDate(_startDate);
		//this.isLoading = false;
	}

	//function to navigate to next set of Date ranges when user click on ">" icon
	navigateToNext() {
		this.isLoading = true;
		let _startDate = this.startDate;

		if (this.scaleType) {
			let currentYear = this.newStartDate.getFullYear();
			let newDate = this.getFirstDayOfYear(currentYear + 1);
			_startDate = newDate;
		} else {
			this.dateShift = 7;
			_startDate.setDate(_startDate.getDate() + this.dateShift);
		}
		this.setStartDate(_startDate);
	}

	//function to calulcate slots/slotsize based on selected scale value
	setView(value) {
		let values = value.split("/");
		this.view.value = value;
		this.view.slotSize = parseInt(value[0], 10);
		this.view.slots = parseInt(values[1], 10);
	}

	//function to set startdate based on scale selected
	handleViewChange(event) {
		this.isLoading = true;
		this.setView(event.target.value);
		this.setDateHeaders();
		if (this.scaleType) {
			let currentDate = new Date();
			const currentYear = currentDate.getFullYear();
			this.setStartDate(this.getFirstDayOfYear(currentYear));
		} else {
			this.setStartDate(new Date());
		}
		this.isLoading = false;
		this.startDate = this.newStartDate;
	}

	//wire method to fetch PMT project, phases and task records as JSON string as per filters selected and pass it to gantt 
	@wire(fetchGanttData, {
		slotSize: '$view.slotSize',
		startTime: '$startDateUTC',
		projectId: '$projectId',
		projectProgress: '$projectProgress',
		projectHealth: '$projectHealth',
		systemImpacted: '$systemImpacted',
		projectCategory: '$projectCategory',
		program: '$programSelected',
	})
	wiredGanttData(result) {
		this.isLoading = true;
		this.wiredGanttResult = result;
		if (result.data) {
			this.dataToShow = [];
			this.processData(result.data);

			if (result.data.length == 30 && this.toastCheck == false) {
				this.toastCheck = true;
				const evt = new ShowToastEvent({
					title: 'Search Results',
					message: 'Only first 30 results are displayed ordered by name, please use additional filters to optimize the search',
					variant: 'warning',
				});
				this.dispatchEvent(evt);
			}
		} else if (result.error) {
			this.showToastMessage('Error', result.error, 'error');
		}
	}

	//function to process the data returned from apex server call 
	processData(data) {
		this.dataToShow = [];
		if (data.length != 0) {
			data.forEach(wrapper => {
				var projectRec = {
					...wrapper
				};
				projectRec.isExpanded = false;
				projectRec.isDraggable = false;
				projectRec.titleClass = "slds-media "; //slds-media_center
				projectRec.actionIcon = (projectRec.lstOfChilds) ? 'utility:chevronright' : '';
				this.dataToShow.push(projectRec);
				this.dataBkp = this.dataToShow;

			});
		}
		if (this.filtersCheck) {
			this.getFiltertedData();
		}
		if (this.isExpandedCheck) {
			this.showCurrentView(this.dataToShow);
		}
		this.isLoading = false;
	}

	//function to restore the current view even when filters are selected
	showCurrentView(showData) {
		this.isExpandAll = true;
		var cloneDataToExpand = [...this.dataBkp];
		cloneDataToExpand = this.expandAll(cloneDataToExpand);
		this.dataToShow = [];
		this.dataToShow = cloneDataToExpand;
		this.isExpandAll = false;
	}

	//function to filter the data based on filter selected
	handleValueChange(event) {
		this.isLoading = true;
		switch (event.target.name) {
			case 'projtgl':
				this.myprojflag = event.target.checked;
				break;
			case 'tasktgl':
				this.mytaskflag = event.target.checked;
				break;
			case 'followtgl':
				this.followprojflag = event.target.checked;
				break;
		}

		if (this.myprojflag == true || this.mytaskflag == true || this.followprojflag == true) {
			this.filtersCheck = true;
		} else {
			this.filtersCheck = false;
		}
		this.isLoading = true;
		this.processData(this.wiredGanttResult.data);
		this.getFiltertedData();
	}

	//function to filter data based on filter selected
	getFiltertedData() {
		try {
			var clonedData = [...this.dataToShow];

			//Filter when My Project is selected
			if (this.myprojflag == true) {
				this.filtersCheck = true;
				clonedData = clonedData.filter(function(element) {
					return element.isMyProject == true;
				}, this);
			}

			//Filter when Follow Projects is selected
			if (this.followprojflag == true) {
				this.filtersCheck = true;
				clonedData = clonedData.filter(function(element) {
					return element.isFollow == true;
				}, this);
			}

			//Filter when All Tasks is selected
			if (this.mytaskflag == true) {
				this.filtersCheck = true;
				clonedData = this.filterProjectsWithoutPhases(clonedData);
				var newclonedData = JSON.parse(JSON.stringify(clonedData))

				newclonedData.forEach(element => {
					element.lstOfChilds.forEach(phase => {
						if (typeof phase.lstOfChilds != 'undefined') {
							phase.lstOfChilds.forEach(task => {
								if (task.isAssignedToMe == false) {
									const index = phase.lstOfChilds.indexOf(task);
									phase.lstOfChilds.splice(index, 1, "");
								}
							});
							phase.lstOfChilds = phase.lstOfChilds.filter(Boolean);
						}
					});
				});

				var newClone = this.filterPhasesWithoutTasks(newclonedData);
				newClone = this.filterProjectsWithoutPhases(newClone);
				clonedData.length = 0;
				clonedData = newClone;
			}
			this.dataToShow = [];
			this.dataToShow = clonedData;
			this.dataBkp = this.dataToShow
			this.isLoading = false;
		} catch (Exception) {
			this.showToastMessage('Error', 'Error during filtering data', 'error');
		}
	}

	//function to filter Projects without Phases 
	filterProjectsWithoutPhases(newclonedData) {
		var tempData = newclonedData;
		var filteredProjects = tempData.filter(function(element) {
			return (typeof element.lstOfChilds != 'undefined' && element.lstOfChilds.length != 0);
		}, this);
		return filteredProjects;
	}

	//function to filter Phases without Tasks 
	filterPhasesWithoutTasks(newclonedData) {
		var tempData = newclonedData;

		var filteredPhases = tempData.map((project) => {
			return {
				...project,
				lstOfChilds: project.lstOfChilds.filter((phase) =>
					(typeof phase.lstOfChilds != 'undefined' && phase.lstOfChilds.length != 0))
			}
		})
		return filteredPhases;
	}

	//function to filter data after user clicks on Expand All button
	filteredView(cloneData){
		var newclonedData = [];
			cloneData.forEach(element => {
				if(element.objAPIName=='PMT_Phase__c'){
					const index = cloneData.indexOf(element);
					cloneData.splice(index, 1, "");
				}
			});
			newclonedData = cloneData.filter(Boolean);
		return newclonedData;
	}

	//function to handle refresh/expand/collpase action from Gantt
	handleonclick(event) {
		this.isLoading = true;
		var action = event.target.label;
		switch (action) {
			case '':
				refreshApex(this.wiredGanttResult);
				break;

			case 'Expand All':
				this.isExpandAll = true;
				var cloneDataToExpand = [...this.dataToShow];
				console.log('here....',cloneDataToExpand.length);
				console.log('length...'+this.dataToShow.length)
				cloneDataToExpand = this.filteredView(cloneDataToExpand);

				cloneDataToExpand = this.expandAll(cloneDataToExpand);
				this.dataToShow = [];
				this.dataToShow = cloneDataToExpand;
				this.isExpandAll = false;
				break;

			case 'Collapse All':
				//this.isExpandedCheck = true;
				//if (this.isExpandedCheck) {
					var cloneDataToCollapse = [];
					cloneDataToCollapse = [...this.dataToShow];

					//cloneDataToExpand = this.filteredView(cloneDataToCollapse);



					for (var counter = 0; counter < cloneDataToCollapse.length; counter++) {
						var index = this.findIndexById(cloneDataToCollapse[counter].id, cloneDataToCollapse);
						cloneDataToCollapse = this.closeAllChilds(cloneDataToCollapse[index], cloneDataToCollapse);
					}
					this.dataToShow = [];
					this.dataToShow = cloneDataToCollapse;
					this.isExpandedCheck = false;
				//}
				break;
			default:
				break;
		}
		this.isLoading = false;
	}

	//function to handle expand the child records
	expandAll(cloneData) {
		try {
			this.isExpandedCheck = true;
			for (var counter = 0; counter < cloneData.length; counter++) {
				var record = cloneData[counter];
				var index = this.findIndexById(record.id, cloneData);
				if (record.objAPIName == 'PMT_Project__c') {
					cloneData = this.expandView(record, index, cloneData, true);
				}

				var relatedRecords = record.lstOfChilds;
				if (relatedRecords && relatedRecords.length > 0) {
					relatedRecords.forEach(element => {
						cloneData = this.expandView(element, index, cloneData, false);
					});
				}
			}
			return cloneData;
		} catch (Exception) {
			this.showToastMessage('Error', 'Error during expandAll', 'error');
		}
	}

	//function to handle events fired from child component
	eventhandler(event) {
		var action = event.detail.type;
		var currentdate = new Date();

		switch (action) {
			case 'add':
				this.createAction(event.detail.recordId);
				break;

			case 'refreshData':
				refreshApex(this.wiredGanttResult)
				break;

			case 'showdata':
				this.handleshowdataevent(event.detail.recordId);
				break;
		}
	}

	//It will define default values required and redirect to standard record creation page  
	createAction(id) {
		try {
			var defaultValue, newObjectAPI;
			var index = this.findIndexById(id, this.dataToShow);
			var record = this.dataToShow[index];
			if (record.objAPIName == 'PMT_Project__c') { //add new phase
				defaultValue = encodeDefaultFieldValues({
					Project__c: id
				});
				newObjectAPI = 'PMT_Phase__c';

			} else if (record.objAPIName == 'PMT_Phase__c') { //add new tasks
				defaultValue = encodeDefaultFieldValues({
					Project_Milestone__c: id
				});
				newObjectAPI = 'PMT_Task__c';
			}
			this[NavigationMixin.Navigate]({
				type: 'standard__objectPage',
				attributes: {
					objectApiName: newObjectAPI,
					actionName: 'new'
				},
				state: {
					defaultFieldValues: defaultValue
				}
			});
		} catch (Exception) {
			this.showToastMessage('Error', 'Error during record creation', 'error');
		}
	}

	//funtion to handle expand/collapse actions
	handleshowdataevent(recordId) {
		try {
			var cloneData = [...this.dataToShow];
			const index = this.findIndexById(recordId, cloneData);
			var record = cloneData[index];

			console.log('beforeee manual..'+JSON.stringify(cloneData));


			const actionIcon = record.actionIcon;
			if (actionIcon) {
				if (record.isExpanded) {
					cloneData = this.closeAllChilds(record, cloneData);
				} else {
					record.actionIcon = 'utility:chevrondown';
					record.isExpanded = true;
					cloneData.splice(index, 1);
					cloneData.splice(index, 0, record);

					var relatedRecords = record.lstOfChilds;
					if (relatedRecords) {
						relatedRecords.forEach(child => {
							cloneData = this.expandView(child, index, cloneData, false);
						});
					}
				}
			}
			this.dataToShow = cloneData;
			console.log('after manual..'+JSON.stringify(cloneData));

			this.isLoading = false;
		} catch (Exception) {
			this.showToastMessage('Error', 'Error during expand/collapse action', 'error');
		}
	}

	//funtion to handle expand action
	expandView(recordToAdd, index, cloneData, isProject) {
		try {
			var record = {
				...recordToAdd
			};


			var relatedRecords = record.lstOfChilds;

			record.isExpanded = (relatedRecords && relatedRecords.length > 0) ? this.isExpandAll : false;
			record.actionIcon = (relatedRecords && relatedRecords.length > 0) ? ((this.isExpandAll) ? 'utility:chevrondown' : 'utility:chevronright') : '';

			var customClass = "slds-media "; //slds-media_center 
			if (record.objAPIName == 'PMT_Phase__c') {
				customClass += "slds-p-left_medium";
				record.isDraggable = false;
				record.padding = "padding-left: 15px;";
			} else if (record.objAPIName == 'PMT_Task__c') {
				customClass += "slds-p-left_large";
				record.isDraggable = true;
				record.padding = "padding-left: 30px;";
			}
			record.titleClass = customClass;

			if (isProject) {
				cloneData.splice(index, 1);
				cloneData.splice(index, 0, record);
			} else {
				cloneData.splice(index + 1, 0, record);
			}
			return cloneData;
		} catch (Exception) {
			this.showToastMessage('Error', 'Error during expanding view', 'error');
		}
	}

	//funtion to handle collapse action
	closeAllChilds(record, cloneData) {
		try {
			if (record.isExpanded) {
				var relatedRecords = record.lstOfChilds;
				if (relatedRecords && relatedRecords.length > 0) {
					relatedRecords.forEach(child => {
						var rec = {
							...child
						};
						const recIndex = this.findIndexById(rec.id, cloneData);
						this.closeAllChilds(cloneData[recIndex], cloneData);

						cloneData.splice(this.findIndexById(rec.id, cloneData), 1);
					});
				}

				record.actionIcon = 'utility:chevronright';
				record.isExpanded = false;
				const index = this.findIndexById(record.id, cloneData);
				cloneData.splice(index, 1);
				cloneData.splice(index, 0, record);
			}
			return cloneData;
		} catch (Exception) {
			this.showToastMessage('Error', 'Error while closing childs', 'error');
		}
	}

	//function to find index based on record id
	findIndexById(Id, listToSearch) {
		try {
			for (var i = 0; i < listToSearch.length; i++) {
				if (listToSearch[i].id === Id) {
					return i;
				}
			}
		} catch (Exception) {
			this.showToastMessage('Error', 'Error duing index search', 'error');
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