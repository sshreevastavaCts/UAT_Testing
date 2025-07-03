import { LightningElement, track, wire  } from 'lwc';
import getQuestions from '@salesforce/apex/AccountApi.getQuestions';
export default class UserAttemptResult extends LightningElement {
    @track timerDisplay = '00:00:00';
    @track selectedOption = '';

    userName = 'Sitaram Shreevastava';
    testName = 'Associate AI';
    dateTime = new Date().toLocaleString();
    setNo = 4;
    nextButtonLabel = 'Next';
    intervalId;
    question = 'What modern-day country was Marie Curie born in?';
    options = [
        { label: '🇩🇪', value: 'germany' },
        { label: '🇫🇷', value: 'france' },
        { label: '🇷🇺', value: 'russia' }
    ];
    connectedCallback() {
        let seconds = 0;
        this.intervalId = setInterval(() => {
            seconds++;
            const hrs = String(Math.floor(seconds / 3600)).padStart(2, '0');
            const mins = String(Math.floor((seconds % 3600) / 60)).padStart(2, '0');
            const secs = String(seconds % 60).padStart(2, '0');
            this.timerDisplay = `${hrs}:${mins}:${secs}`;
        }, 1000);
    }

    disconnectedCallback() {
        clearInterval(this.intervalId);
    }

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