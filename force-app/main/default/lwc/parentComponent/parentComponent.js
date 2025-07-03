import { LightningElement,track, wire, api } from 'lwc';
import getAccounts from '@salesforce/apex/AccountApi.getAccounts';
export default class ParentComponent extends LightningElement {
    @track userInput = ''; // Stores input value
    @track itemList = [
        { id: 1, name: 'The parent component (DynamicFieldsComponent) stores the user input (userInput).' },
        { id: 2, name: 'When the user types, handleInputChange updates userInput.' },
        { id: 3, name: 'The child component (childComponent) receives userInput as inputValue using @api.' },
        { id: 4, name: 'The child component dynamically displays the received value.' },
    ];

    @track accountOptions = []; // Options for the combobox
    @api selectedParentId = ''; // Store selected parent account Id
    selectedParentName = ''; // Store selected parent account Name

    @api fname = '';
    @api lname = '';

    @api contactData = {
        firstName: '',
        lastName: '',
        parentAccount: ''
    };

    receivedData;

    // Wire the Apex method to get the accounts
    @wire(getAccounts)
    wiredAccounts({ data, error }) {
        if (data) {
            // Transform the account list into combobox options
            this.accountOptions = data.map(account => ({
                label: account.Name,
                value: account.Id
            }));
        } else if (error) {
            // Handle errors
            console.error('Error fetching accounts', error);
        }
    }

    // Handle the combobox value change
    handleParentAccountChange(event) {
        const selectedValue = event.detail.value;
        this.selectedParentId = selectedValue;

        // Find the selected parent account by Id and update the name
        const selectedAccount = this.accountOptions.find(option => option.value === selectedValue);
        if (selectedAccount) {
            this.selectedParentName = selectedAccount.label;
        }
    }
    handleFirstNameChange(event) {
        this.fname = event.target.value; // Update user input dynamically
    }
    handleLastNameChange(event) {
        this.lname = event.target.value; // Update user input dynamically
    }
    handleInputChange(event) {
        this.userInput = event.target.value; // Update user input dynamically
    }

    passToChild() {
        const inputs = this.template.querySelectorAll('lightning-input');
        const inputs2 = this.template.querySelector('lightning-combobox');
        let isValid = true;

        /* Validate each input element  */
        inputs.forEach(input => {
            // Trigger the reportValidity method to check if the input is valid
            input.reportValidity();
        });
        inputs2.reportValidity();
        // If any input is invalid, display an error message 

        console.log('hi');
        this.contactData.firstName = this.fname;
        this.contactData.lastName = this.lname;
        this.contactData.parentAccount = this.selectedParentName;
        console.log(JSON.stringify(this.contactData));
        //const newRecord = { ...this.contactRecord }; // create a new object with the properties of the current object
        
        this.template.querySelector('c-child-cmp-for-read-inputs').setRecordData(this.contactData);
      
    }
    
    handleChildData(event) {
        this.receivedData = event.detail;
        console.log('Received from child:', JSON.stringify(this.receivedData));
    }
}