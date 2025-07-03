import { LightningElement } from 'lwc';

export default class EventHanding extends LightningElement {
    htmlCode = `<lightning-button 
                label="Click Me" 
                onclick={handleClick}>
                </lightning-button>`;
    jsCode = `handleClick(event) {
                console.log('Button clicked');
                }`;
    type = 'Standard DOM Events'+
    '<p>You can directly handle DOM events like click, change, input, mouseover, etc.</p>';
    keyDifferences = [
        {   id: 1, 
            type: this.type, 
            html: this.htmlCode,
            js: this.jsCode
        }
    ];
}