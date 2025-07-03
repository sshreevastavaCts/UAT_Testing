import { LightningElement,track } from 'lwc';

export default class LWCPages extends LightningElement {
    @track leftMenuInnerText = 'Home';
    @track activeTab = '0'; //display cmp  

    // left menu options
    leftMenuOptions = [
        { id: '0', label: 'Home', class: 'slds-col slds-size_1-of-1 menu_options active' },
        { id: '1', label: 'Simple LWC Component', class: 'slds-col slds-size_1-of-1 menu_options' },
        { id: '2', label: 'Parent to Child Component (pass data)', class: 'slds-col slds-size_1-of-1 menu_options' },
        { id: '3', label: 'LWC Many screens with validation', class: 'slds-col slds-size_1-of-1 menu_options' },
        { id: '4', label: 'LWC Life Cycle Hooks', class: 'slds-col slds-size_1-of-1 menu_options' },
        { id: '5', label: 'LWC Decorators', class: 'slds-col slds-size_1-of-1 menu_options' },
        { id: '6', label: 'LWC Data Binding', class: 'slds-col slds-size_1-of-1 menu_options' },
        { id: '7', label: 'LWC Event Handling', class: 'slds-col slds-size_1-of-1 menu_options' },
        { id: '8', label: 'LWC Display Locations', class: 'slds-col slds-size_1-of-1 menu_options' },
    ];

    addActiveClassInLeftMenu(event) {
        let divDataId = event.currentTarget.dataset.id;
        const allBoxes = this.template.querySelectorAll('.menu_options');
        allBoxes.forEach(box => {
            box.classList.remove('active');
        });
       
        let str = 'div[data-id="'+divDataId+'"]';
        const divElement = this.template.querySelector(str);
        this.leftMenuInnerText = divElement.innerText;
        divElement.classList.add('active');
        
        // selected tab work space 
        this.activeTab = divDataId;
    }
    get isVisibleTab0() {
        return this.activeTab === '0';
    }
    get isVisibleTab1() {
        return this.activeTab === '1';
    }


    get isVisibleTab2() {
        return this.activeTab === '2';
    }

    get isVisibleTab3() {
        return this.activeTab === '3';
    }

    get isVisibleTab4() {
        return this.activeTab === '4';
    }

    get isVisibleTab5() {
        return this.activeTab === '5';
    }
    get isVisibleTab6() {
        return this.activeTab === '6';
    }    
    get isVisibleTab7() {
        return this.activeTab === '7';
    }
       
    get isVisibleTab8() {
        return this.activeTab === '8';
    }
}