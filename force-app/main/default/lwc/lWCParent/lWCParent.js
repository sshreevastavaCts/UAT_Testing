import { LightningElement, api, track} from 'lwc';

export default class LWCParent extends LightningElement {
    @api account = [];
    handleClickSave() {
        console.log('click btns')
        const childComponent1 = this.template.querySelector('c-lwc_child_cmp1'); // get first cmp for validation
        childComponent1.checkValidation(); // check validation in cmp 1

        const values = childComponent1.getValues();
        console.log('Retrieved values:', JSON.stringify(values));
    }
}