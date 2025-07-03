import { LightningElement, wire, track, api } from 'lwc';
import getAccounts from '@salesforce/apex/AccountApi.getAccounts';
export default class Lwc_child_cmp1 extends LightningElement {    
    @api accountData;
    showValidationMessage = false; // Reset validation message on input
    AccountName = 'null';
    AccountNumber = '';
    AccountSite = '';
    Employees = '';
    SICCode = '';
    // start parent account
    pAccountVal = 'none';
    selectedAccount;
    @track Parent_Account_Data;
    Parent_Account_Options;
    // end parent account
 
    @track rating_options = [
        { label: 'None', value: 'None'},
        { label: 'Hot', value: 'Hot'},
        { label: 'Warm', value: 'Warm'},
        { label: 'Cold', value: 'Cold'}
    ];
    rating_value = 'none';

    ownership_value = 'none';
    @track ownership_options = [
        {label: 'None', value: 'None'},
        {label: 'Public', value: 'Public'},
        {label: 'Private', value: 'Private'},
        {label: 'Subsidiary', value: 'Subsidiary'},
        {label: 'Other', value: 'Other'}
    ];
    // start parent account
    @wire(getAccounts) leads({ error, data }) { 
        if (data) {
            let holdOption = {};
            console.log(data);
            try {
                this.Parent_Account_Data = data;
                this.Parent_Account_Options = data.map(d => {return {label: d.Name, value: d.Id, selected: false }});
            } catch (error) {
                console.error(error);
            }
        } else if (error) {
            console.error(error);
        }
    }
    handleAccountName(event) {
        this.AccountName = event.detail.value;
        const accNameInput = this.template.querySelector('[data-field="accName"]');
        this.displayValidation(accNameInput, this.AccountName);
        console.log('get AccountName ==>'+this.AccountName);
    }
    handleParentAccount(event) {
        this.pAccountVal = event.detail.value;
        console.log(this.pAccountVal);
        this.selectedAccount = this.Parent_Account_Data.filter(lead => lead.Id === event.detail.value)[0];
        console.log('this.selectedAccount ==>'+JSON.stringify(this.selectedAccount));
        const parAccNameInput = this.template.querySelector('[data-field="parAccName"]');
        this.displayValidation(parAccNameInput, this.pAccountVal);
    } // end parent account
    
    // start rating 
    handleRating(event) {
        this.rating_value = event.detail.value;
        //this.accountData.Rating = this.rating_value;
        console.log('get rating_value ==>'+this.rating_value);
    }
 
    handleOwnership(event) {
        this.ownership_value = event.detail.value;
        //this.accountData.Ownership = this.ownership_value;
        console.log('get ownership_value ==>'+this.ownership_value);
    }
    
    handleAccountNo(event) {
        this.AccountNumber = event.detail.value;
        //this.accountData.AccountNumber = this.AccountNumber;
        console.log('get AccountNumber ==>'+this.AccountNumber);
    }
    
    handleAccountSite(event) {
        this.AccountSite = event.detail.value;
        //this.accountData.Site = this.AccountSite;
        console.log('get AccountSite ==>'+this.AccountSite);
    }
    handleSICCode(event) {
        this.SICCode = event.detail.value;
        //this.accountData.Sic = this.SICCode;
        console.log('get SICCode ==>'+this.SICCode);
    }
    handleEmployees(event) {
        this.Employees = event.detail.value;
        //this.accountData.NumberOfEmployees = this.Employees;
        console.log('get Employees ==>'+this.Employees);
        console.log('get Employees ==>'+this.accountData);
    }


    // return data to parent to on save btn
    @api
    getValues() {
        return {
            name: this.AccountName,
            ParentId: this.pAccountVal,
            AccountNumber: this.AccountNumber,
            Site: this.AccountSite,
            Rating: this.rating_value,
            Ownership: this.ownership_value,
            NumberOfEmployees: this.Employees,
            Sic: this.SICCode
        };
    }

    
    @api
    checkValidation() {
        console.log('in child cmp ==>');
        
        const accNameInput = this.template.querySelector('[data-field="accName"]');
        this.displayValidation(accNameInput, this.AccountName);
        
        const parAccNameInput = this.template.querySelector('[data-field="parAccName"]');
        this.displayValidation(parAccNameInput, this.pAccountVal);    
    }

    displayValidation(inputField, inputFieldValue) {
        console.log('inputField ==>'+JSON.stringify(inputField));
        console.log('displayValidation ==>'+inputFieldValue);
        if (inputFieldValue.trim() == '' || inputFieldValue === 'null' || inputFieldValue == 'none' || inputFieldValue === 'undefined'){
            inputField.setCustomValidity('This field is required!');
            inputField.reportValidity();
        } else {
            inputField.setCustomValidity('');
            inputField.reportValidity();
        }
    }
}