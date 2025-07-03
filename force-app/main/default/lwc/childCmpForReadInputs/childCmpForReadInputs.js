import { LightningElement, api } from 'lwc';

export default class ChildCmpForReadInputs extends LightningElement {
    record;
    selectedDate;
    selectedEmail
    @api
    setRecordData(data) {
        console.log('Data received in child component:', data);
        this.record = null;
        setTimeout(() => {
            this.record = data;
        }, 0);
    }

    handleDOBChange(event) {
        this.selectedDate = event.target.value;
        console.log('Selected date:', this.selectedDate);
        this.record.DOB = this.selectedDate; // Update the record's DOB property 
    }
    handleEmailChange(event) {
        this.selectedEmail = event.target.value;
        console.log('Selected email:',this. selectedEmail);
        this.record.Email = this.selectedEmail; // Update the record's Email property 
    }
    passToParent() {
        console.log('hidfsdf'); 
        console.log('Record data before sending to parent:', JSON.stringify(this.record));   
        this.record.DOB = this.selectedDate;
        this.record.Email = this.selectedEmail;     
        console.log('Record data in child component:', this.record);
        const recordEvent = new CustomEvent('senddata', {
            detail: this.record
        });
        this.dispatchEvent(recordEvent); // Dispatch the event to the parent component
        console.log('Record data sent to parent:', JSON.stringify(this.record));
        // // Reset the record data
        // this.record = {
        //     firstName: '',
        //     lastName: '',
        //     parentAccount: '',
        //     DOB: '',
        //     Email: ''
        // };
        // console.log('Record data after reset:', this.record);
        // // Reset the input fields in the child component
        // const inputFields = this.template.querySelectorAll('lightning-input');
        // inputFields.forEach(input => {
        //     input.value = ''; // Reset the input field value
        // });
        // console.log('Input fields reset in child component');
        // // Reset the selected parent account
        // this.selectedParentId = ''; // Reset the selected parent account Id
        // this.selectedParentName = ''; // Reset the selected parent account Name
        // console.log('Selected parent account reset in child component');
        // // Reset the selected date
        // this.selectedDate = ''; // Reset the selected date
        // console.log('Selected date reset in child component');
        // // Reset the selected email
        // this.selectedEmail = ''; // Reset the selected email
        // console.log('Selected email reset in child component');         
    }
}