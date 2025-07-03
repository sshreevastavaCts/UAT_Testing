import { LightningElement, track, api, wire } from 'lwc';
import getData from '@salesforce/apex/AccountApi.getAccounts';
// Importing the wire service to call an Apex method
// Importing the track decorator to make properties reactive
// Importing the api decorator to expose properties to the parent component
// Importing the LightningElement base class to create a Lightning web component
// Importing the api decorator to expose properties to the parent component
// Importing the wire decorator to call an Apex method
// Importing the track decorator to make properties reactive
// Importing the LightningElement base class to create a Lightning web component
export default class Decorators extends LightningElement {

    @track keyDifferences = [
        {   id: 1,
            feature: '@api',
            lwc: 'Expose property/method to parent component',
            aura:'Pass data into a component'
        },
        {   id: 2,
            feature: '@track',
            lwc: 'Track private reactive state (legacy use)',
            aura:'Update UI when property changes'
        },
        {   id: 3,
            feature: '@wire',
            lwc: 'Call Apex or consume reactive services (like LDS)',
            aura:'Fetch data from backend'
        }
    ];
    // // Public property
    // @api publicProperty;

    // // Private property
    // @track privateProperty;

    // // Getter
    // get computedProperty() {
    //     return this.privateProperty + 1;
    // }

    // // Setter
    // set computedProperty(value) {
    //     this.privateProperty = value - 1;
    // }

    // // Wire service
    // @wire(getData)
    // wiredData({ error, data }) {
    //     if (data) {
    //         this.privateProperty = data;
    //     } else if (error) {
    //         console.error(error);
    //     }
    // }
}