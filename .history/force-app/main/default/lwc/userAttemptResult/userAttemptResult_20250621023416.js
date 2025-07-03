import { LightningElement, track } from 'lwc';

export default class UserAttemptResult extends LightningElement {
    @track showModal = true;
    @track selectedOption = '';

    question = 'What is the capital of France?';
    options = [
        { label: 'Paris', value: 'paris' },
        { label: 'London', value: 'london' },
        { label: 'Berlin', value: 'berlin' }
    ];

    handleOptionChange(event) {
        this.selectedOption = event.target.value;
    }

    handleBack() {
        // Add your back logic here
        alert('Back clicked');
    }

    handleNext() {
        // Add your next logic here
        alert(`Next clicked. Selected: ${this.selectedOption}`);
    }
}