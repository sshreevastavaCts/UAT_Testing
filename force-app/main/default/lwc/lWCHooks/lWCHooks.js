import { LightningElement, track } from 'lwc';

export default class LWCHooks extends LightningElement {
    @track lwcItemList = [
        { id: 1, feature:   'constructor()', lwc: 'When the component is created (before rendered)', aura: 'Setup initial state, bind event handlers' },
        { id: 2, feature:   'connectedCallback()', lwc: 'When the component is inserted into the DOM', aura: 'Fetch data, set timers, interact with DOM' },
        { id: 3, feature:   'renderedCallback()', lwc: 'After every render (and re-render)', aura: 'Interact with rendered DOM, manipulate elements' },
        { id: 4, feature:   'disconnectedCallback()', lwc: 'When component is removed from the DOM', aura: 'Cleanup: clear timers, remove listeners' },
        { id: 5, feature:   'errorCallback(error, stack)', lwc: 'When child component throws an error', aura: 'Handle errors from nested components' },
    ];
    constructor() {
        super();
        console.log('Constructor called');
    }

    connectedCallback() {
        console.log('Connected Callback called');
    }

    renderedCallback() {
        console.log('Rendered Callback called');
    }

    disconnectedCallback() {
        console.log('Disconnected Callback called');
    }   
        
}