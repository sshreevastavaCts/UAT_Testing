import { LightningElement, track, wire  } from 'lwc';
import getQuestions from '@salesforce/apex/AccountApi.getQuestions';
import USER_ID from '@salesforce/user/Id';
import { getRecord } from 'lightning/uiRecordApi';
import saveResults from '@salesforce/apex/AccountApi.saveQuizAnswers';
const FIELDS = ['User.Name'];
export default class UserAttemptResult extends LightningElement {
    
    @track timerDisplay = '00:00:00';
    @track selectedOption = '';
    userId = USER_ID;
    
    userName = '';
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
    @track QR_responses = []; 
    //isDesabledCueerntIndex = false;

    userTakenTime;
    isChecked = false;
    backBtnIsDisabled = true;
    nextBtnIsDisabled = true;

    startTime = null;
    endTime = null;

    uuid = '';
    question = 'What modern-day country was Marie Curie born in?';
    options = [
        { label: '', value: '' },
        { label: '', value: '' },
        { label: '', value: '' }
    ];

    connectedCallback() {
        this.startTime = new Date();
        // 70 minutes in seconds
        let totalSeconds = 70 * 60;
        this.updateTimerDisplay(totalSeconds);

        this.intervalId = setInterval(() => {
            totalSeconds--;
            this.updateTimerDisplay(totalSeconds);

            if (totalSeconds <= 0) {
                clearInterval(this.intervalId);
                this.timerDisplay = '00:00:00';
                // Optionally, you can auto-submit or show a message here
                // this.isSubmitted = true;
            }
        }, 1000);

        if (this.currentIndex == 0) {
            this.isDesabledCueerntIndex = true;
        } 

        this.uuid = this.generateUniqueId();
        console.log('Generated UUID:', this.uuid);
    }

    @wire(getRecord, { recordId: USER_ID, fields: FIELDS })
    userRecord({ error, data }) {
        if (data) {
            this.userName = data.fields.Name.value;
        } else if (error) {
            this.userName = '';
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

            clearInterval(this.intervalId);

            this.endTime = new Date();
            const timeTakenMs = this.endTime - this.startTime;
            const timeTakenSec = Math.floor(timeTakenMs / 1000);
            const mins = String(Math.floor(timeTakenSec / 60)).padStart(2, '0');
            const secs = String(timeTakenSec % 60).padStart(2, '0');
            const timeTakenDisplay = `${mins}:${secs}`;
            console.log('User time taken:', timeTakenDisplay);
            this.userTakenTime = timeTakenDisplay;
            
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
            UUID__c: this.uuid,
            Selected_Question__c: currentQ.Question__c,
            Selected_Answer__c: this.selectedAnswer,
            Correct_Answer__c: currentQ.Correct_Answer__c,
            Quiz_Question_Number__c: currentQ.Id,
            Attended_By__c: this.userId,
            IsCorrect_Answer__c: (this.selectedAnswer === currentQ.Correct_Answer__c) ? true : false,
        };

        

        console.log('Response saved:', JSON.stringify(this.responses));
        this.selectedAnswer = ''; // Reset selected answer for next question
    }

    saveResultsToApex() {
        // save response for quiz results
        const convertedDate = new Date().toISOString();
        const isCorrectCount = this.responses.filter(resp => resp && resp.IsCorrect_Answer__c === true).length;
        const score = "$isCorrectCount / $this.questions.length";
        const  percentage = score * 100;
        const status = (percentage >= 80) ? 'Pass' : 'Fail';
        this.QR_responses[0] = {
            Exam_Date_Time__c: convertedDate,
            Exam_Name__c: this.testName,
            Exam_Status__c: status,
            Exam_Taken_Time__c: this.userTakenTime,
            Percentage__c: percentage, // Placeholder, calculate percentage later
            Score__c: score, // Placeholder, calculate score later
            Set_No__c: this.setNo,
            Student_Attempts__c: this.currentIndex + 1,
            Student_Name__c: this.userId,
            Total_Questions__c: this.questions.length,
            Total_Time_Duration__c: this.timerDisplay,
            UAR_UUID__c: this.uuid,
        };
        console.log('QR Response:', JSON.stringify(this.QR_responses));
        saveResults({ quizAnswers: this.responses, QR_Answers: this.QR_responses })
            .then(() => {
                console.log('Responses saved successfully!');
                // Optionally show a success message to the user
            })
            .catch(error => {
                console.error('Error saving responses:', error);
                // Optionally show an error message to the user
            });
    }

    generateUniqueId() {
        return Math.random().toString(36).substr(2, 6).toUpperCase();
    }

    updateTimerDisplay(totalSeconds) {
        const hrs = String(Math.floor(totalSeconds / 3600)).padStart(2, '0');
        const mins = String(Math.floor((totalSeconds % 3600) / 60)).padStart(2, '0');
        const secs = String(totalSeconds % 60).padStart(2, '0');
        this.timerDisplay = `${hrs}:${mins}:${secs}`;
    }

   
}