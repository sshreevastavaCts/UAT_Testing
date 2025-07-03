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

    @track correctAnswers = [];

    @track currentIndex = 0;
    @track questions = [];
    
    @track selectedAnswer = '';
    @track responses = []; // [{ questionId, selectedAnswer, action }]
    @track isSubmitted = false;

    isDesabledCueerntIndex = false;

    question = 'What modern-day country was Marie Curie born in?';
    options = [
        { label: '', value: '' },
        { label: '', value: '' },
        { label: '', value: '' }
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
        const currentQ = this.questions[this.currentIndex];
        if (currentQ) {
            this.question = currentQ.Question__c;
            this.options = [
                { label: currentQ.Answer_Option_1__c, value: 'A' },
                { label: currentQ.Answer_Option_2__c, value: 'B' },
                { label: currentQ.Answer_Option_3__c, value: 'C' }
            ];
            this.correctAnswers[currentQ] = currentQ.Answer_Option_3__c;
        } else {
            this.question = '';
            this.options = [];
        }
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
        this.selectedAnswer = event.target.value;
        console.log('Selected Answer:', this.selectedAnswer);
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
        const currentQ = this.questions[this.currentIndex];
        if (!currentQ) return [];
        return [
            { label: currentQ.Answer_Option_1__c, value: 'A' },
            { label: currentQ.Answer_Option_2__c, value: 'B' },
            { label: currentQ.Answer_Option_3__c, value: 'C' }
        ];
    }

    handleNext() {
        //this.saveResponse('Next');

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