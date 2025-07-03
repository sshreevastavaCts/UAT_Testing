import { LightningElement } from 'lwc';

export default class SimpleLwcCmp extends LightningElement {
    name = 'Sitaram';
    handleChange(event) {
        this.name = event.target.value;
    }
}