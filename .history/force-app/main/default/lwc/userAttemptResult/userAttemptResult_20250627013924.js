import { LightningElement, track, wire  } from 'lwc';
import getQuestions from '@salesforce/apex/AccountApi.getQuestions';
import USER_ID from '@salesforce/user/Id';
export default class UserAttemptResult extends LightningElement {
    @track timerDisplay = '00:00:00';
    @track selectedOption = '';
    userId = USER_ID;
    userName = 'Sitaram Shreevastava';
    testName = 'Associate AI';
    dateTime = new Date().toLocaleString();
    setNo = 4;
    //quesSequence = '1';
    //nextButtonLabel = 'Next';
    intervalId;

    @track correctAnswers = [];

    @track currentIndex = 0;
    @track questions = [];
    
    @track selectedAnswer = '';
    @track responses = []; // [{ questionId, selectedAnswer, action }]
    @track isSubmitted = false;

    //isDesabledCueerntIndex = false;

    isChecked = false;
    backBtnIsDisabled = true;
    nextBtnIsDisabled = true;

    question = 'What modern-day country was Marie Curie born in?';
    options = [
        { label: '', value: '' },
        { label: '', value: '' },
        { label: '', value: '' }
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

        if (this.currentIndex == 0) {
            this.isDesabledCueerntIndex = true;
        } 
    }
    @wire(getQuestions)
    wiredQuestions({ error, data }) {
        if (data) {
            this.questions = data;
            //console.log('Questions:', JSON.stringify(this.questions));
            this.displayQuiz();
        } else {
            console.error(error);
        }
    }
    displayQuiz() {
        console.log('Displaying quiz for current index:', this.currentIndex);
        const currentQ = this.questions[this.currentIndex];
        if (currentQ) {
            this.question = currentQ.Question__c;
            this.options = [
                { label: currentQ.Answer_Option_1__c, value: currentQ.Answer_Option_1__c },
                { label: currentQ.Answer_Option_2__c, value: currentQ.Answer_Option_2__c },
                { label: currentQ.Answer_Option_3__c, value: currentQ.Answer_Option_3__c }
            ];
            this.correctAnswers[currentQ] = currentQ.Answer_Option_3__c;
        } else {
            this.question = '';
            this.options = [];
        }
    }  

    handleNext() {
        this.nextBtnIsDisabled = true;
        this.saveResponse();
        console.log('Responses:', JSON.stringify(this.responses));
        if (this.currentIndex < this.questions.length - 1) {            
            this.currentIndex++;
            this.displayQuiz();
        } else {
            this.isSubmitted = true;
            console.log('Final Responses:', JSON.stringify(this.responses));
            // Optional: Call Apex to save responses
            this.saveResultsToApex();
        }
        this.backBtnIsDisabled = (this.currentIndex > 0) ? false : true;
    }

    handleBack() { 
        if (this.currentIndex > 0) {
            this.currentIndex --; 
            this.displayQuiz();
            this.nextBtnIsDisabled = true;
            this.backBtnIsDisabled = (this.currentIndex === 0);
        }
    }
    

    disconnectedCallback() {
        clearInterval(this.intervalId);
    }

    
    handleOptionChange(event) {
        this.selectedAnswer = event.target.value;
        console.log('Selected Answer:', this.selectedAnswer);
        this.isDesabledCueerntIndex = false;
        this.nextBtnIsDisabled = false;
    }

    

    get buttonBackIsDesabled() {
        return this.backBtnIsDisabled ? 'footer-btn back-btn disabled-cursor' : 'footer-btn back-btn enabled-cursor';
    }

    
    get buttonNextIsDesabled() {
        return this.nextBtnIsDisabled ? 'footer-btn next-btn disabled-cursor' : 'footer-btn next-btn enabled-cursor';
    }

    get nextButtonLabel() {
        return (this.currentIndex === (this.questions.length - 1)) ? 'Submit' : 'Next';
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
            { label: currentQ.Answer_Option_1__c, value: currentQ.Answer_Option_1__c },
            { label: currentQ.Answer_Option_2__c, value: currentQ.Answer_Option_2__c },
            { label: currentQ.Answer_Option_3__c, value: currentQ.Answer_Option_3__c }
        ];
    }

    get quesSequence() {
        let allQues = this.questions.length;
        return this.currentIndex + 1 + ' of ' + allQues +': ';
    }

    saveResponse() {
       
        const currentQ = this.questions[this.currentIndex];
        // creating the response object
        this.responses[this.currentIndex] = {
            currentIndex: this.currentIndex,
            Selected_Answer__c: this.selectedAnswer,
            Correct_Answer__c: currentQ.Correct_Answer__c,
            Quiz_Question_Number__c: currentQ.Id,
            Attended_By__c: this.userId,
            IsCorrect_Answer__c: (this.selectedAnswer === currentQ.Correct_Answer__c) ? true : false,
        };
    }

   

}