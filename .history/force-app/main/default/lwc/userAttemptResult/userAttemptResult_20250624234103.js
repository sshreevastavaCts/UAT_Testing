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


    @track currentIndex = 0;
    @track questions = [];
    
    @track selectedAnswer = '';
    @track responses = []; // [{ questionId, selectedAnswer, action }]
    @track isSubmitted = false;

           isDesabledCueerntIndex = false;

    question = 'What modern-day country was Marie Curie born in?';
    options = [
        { label: '🇩🇪', value: 'germany' },
        { label: '🇫🇷', value: 'france' },
        { label: '🇷🇺', value: 'russia' }
    ];


    @wire(getQuestions)
    wiredQuestions({ error, data }) {
        if (data) {
            this.questions = data;
            console.log('Questions:', JSON.stringify(this.questions));
            this.displayQuiz();
        } else {
            console.error(error);
        }
    }

    connectedCallback() {
        let seconds = 0;
        this.intervalId = setInterval(() => {
            seconds++;
            const hrs = String(Math.floor(seconds / 3600)).padStart(2, '0');
            const mins = String(Math.floor((seconds % 3600) / 60)).padStart(2, '0');
            const secs = String(seconds % 60).padStart(2, '0');
            this.timerDisplay = `${hrs}:${mins}:${secs}`;
        }, 1000);

        if (this.currentIndex == 0) {
            this.isDesabledCueerntIndex = true;
        } 
    }

    displayQuiz() {
        this.question = this.questions[this.currentIndex]['Question__c'];
    }


    restorePreviousAnswer() {

    }

    disconnectedCallback() {
        clearInterval(this.intervalId);
    }

    // handleOptionChange(event) {
    //     this.selectedOption = event.target.value;
    // }

    handleOptionChange(event) {
        this.selectedAnswer = event.detail.value;
    }

    handleBack() {
        this.saveResponse('Back');

        if (this.currentIndex > 0) {
            this.currentIndex--;
            this.restorePreviousAnswer();
        }
    }

    get nextButtonLabel() {
        return this.currentIndex === this.questions.length - 1 ? 'Submit' : 'Next';
    }

    get question() {
        return this.questions[this.currentIndex];
    }

    get currentIndexDisplay() {
        return this.currentIndex + 1;
    }

    get options() {
        if (!this.question) return [];
        return [
            { label: this.question.Option_A__c, value: 'A' },
            { label: this.question.Option_B__c, value: 'B' },
            { label: this.question.Option_C__c, value: 'C' },
            { label: this.question.Option_D__c, value: 'D' },
        ];
    }

    handleNext() {
        this.saveResponse('Next');

        if (this.currentIndex < this.questions.length - 1) {
            this.currentIndex++;
            this.restorePreviousAnswer();
        } else {
            this.isSubmitted = true;
            console.log('Final Responses:', JSON.stringify(this.responses));
            // Optional: Call Apex to save responses
        }
    }

    saveResponse(action) {
        const questionId = this.question.Id;

        const existingIndex = this.responses.findIndex(r => r.questionId === questionId);
        if (existingIndex !== -1) {
            // Update
            this.responses[existingIndex] = {
                questionId,
                selectedAnswer: this.selectedAnswer,
                action
            };
        } else {
            // Add
            this.responses.push({
                questionId,
                selectedAnswer: this.selectedAnswer,
                action
            });
        }
        console.log('Responses:', JSON.stringify(this.responses));
    }

   

}