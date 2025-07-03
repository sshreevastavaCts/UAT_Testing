import { LightningElement, track, wire, api } from 'lwc';
import { getPicklistValuesByRecordType, getObjectInfo } from 'lightning/uiObjectInfoApi';
import TASK_OBJECT from '@salesforce/schema/Task';

import SUBJECT_FIELD from '@salesforce/schema/Task.Subject';

import getSubjectPicklistValues from '@salesforce/apex/AccountApi.getTaskSubjectsByRecordId';

export default class CreateTask extends LightningElement {
    @track subject = '';
    @track status = '';
    @track priority = '';
    //@track subject = '';

    @track statusOptions = [];
    @track subjectOptions = [];
    @track priorityOptions = [];
   
    recordTypeId;
    objectInfo;


    @wire(getPicklistValuesByRecordType, { recordTypeId: '012Qy000006ipY1IAI', fieldApiName: SUBJECT_FIELD })
    subjectPicklist({ data, error }) {
        console.log('data ==>'+data);
        if (data) {
            console.log('data ==>'+data.values);
            this.subjectOptions = data.values;
        } else if (error) {
            console.error('Error loading Subject picklist values:', error);
        }
    }
    @wire(getPicklistValuesByRecordType, {
        objectApiName: TASK_OBJECT,
        recordTypeId: '012Qy000006ipY1IAI' // Make sure this value is available
    })
    wiredPicklistValues({ data, error }) {
        if (data) {
            this.statusOptions = data.picklistFieldValues.Status.values;
            console.log('data ==>'+this.statusOptions);
           
        } else if (error) {
            console.error('Error getting picklist values', error);
        }
    }

    connectedCallback() {
        getSubjectPicklistValues()
            .then(result => {
                this.subjectOptions = result.map(val => {
                    return { label: val, value: val };
                });
            })
            .catch(error => {
                console.error('Error fetching Subject picklist:', error);
            });
    }


    @track selectedLangs = [];
    lanOptions = [
        { label: 'JavaScript', value: 'javascript' },
        { label: 'Apex', value: 'apex' },
        { label: 'LWC', value: 'lwc' },
        { label: 'Visualforce', value: 'visualforce' },
        { label: 'SOQL', value: 'soql' },
        { label: 'SOSL', value: 'sosl' }
    ];

    handleLanChange(event) {
        this.selectedLangs = event.detail.value;
        console.log('Selected languages:', JSON.stringify(this.selectedLangs));
    }
}