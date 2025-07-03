import { LightningElement,api } from 'lwc';

export default class ChildComponent extends LightningElement {
    @api inputValue; // Receives input from parent
}