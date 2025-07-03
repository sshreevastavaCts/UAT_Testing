import { LightningElement } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
export default class CreateAccountRecord extends LightningElement {

    handleSuccess(event) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Success',
                message: 'Account created! Record Id: ' + event.detail.id,
                variant: 'success',
            }),
        );
    }
}