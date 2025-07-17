import { LightningElement, track, wire } from 'lwc';
import getQuizQuestions from '@salesforce/apex/AccountApi.getQuestions';
const PAGE_SIZE = 5;
export default class AgentforceQuizList extends LightningElement {
    @track quizData = [];
    @track pagedData = [];
    @track searchKey = '';
    @track currentPage = 1;
    @track totalPages = 1;
    @track sortedBy = 'name';
    @track sortedDirection = 'asc';

    

    @wire(getQuizQuestions)
    wiredQuestions({ error, data }) {
        if (data) {
            this.quizData = data.map(q => ({
                id: q.Id,
                question: q.Question__c,
                name: q.Name,
                answersArr: [
                    q.Answer_Option_1__c,
                    q.Answer_Option_2__c,
                    q.Answer_Option_3__c
                ],
                correctAnswer: q.Correct_Answer__c
            }));
            this.filterAndPaginate();
        }
    }

    handlePrev() {
        if (this.currentPage > 1) {
            this.currentPage--;
            this.filterAndPaginate();
        }
    }

    handleNext() {
        if (this.currentPage < this.totalPages) {
            this.currentPage++;
            this.filterAndPaginate();
        }
    }

    get isPrevDisabled() {
        return this.currentPage === 1;
    }

    get isNextDisabled() {
        return this.currentPage === this.totalPages;
    }

    filterAndPaginate() {
        let filtered = this.quizData;
        if (this.searchKey) {
            filtered = filtered.filter(
                q =>  
                    q.question.toLowerCase().includes(this.searchKey) ||
                    q.answer.toLowerCase().includes(this.searchKey)
            );
        }
        // Sorting
        filtered = [...filtered].sort((a, b) => {
            let valA = a[this.sortedBy] ? a[this.sortedBy].toLowerCase() : '';
            let valB = b[this.sortedBy] ? b[this.sortedBy].toLowerCase() : '';
            if (valA < valB) return this.sortedDirection === 'asc' ? -1 : 1;
            if (valA > valB) return this.sortedDirection === 'asc' ? 1 : -1;
            return 0;
        });
        // Pagination
        this.totalPages = Math.ceil(filtered.length / PAGE_SIZE) || 1;
        const start = (this.currentPage - 1) * PAGE_SIZE;
        this.pagedData = filtered.slice(start, start + PAGE_SIZE);
    }
}