import { LightningElement } from 'lwc';
import getAnswer from '@salesforce/apex/VoiceAIController.getAnswer';
export default class VoiceAssistant extends LightningElement {
    transcript = '';
    recognition;
    error = '';
    answer = '';
    startListening() {
        this.error = '';
        const SpeechRecognition = window.SpeechRecognition || window.webkitSpeechRecognition;

        if (!SpeechRecognition) {
            this.error = 'Speech Recognition is not supported in this browser. Use Chrome or Edge.';
            return;
        }

        try {
            this.recognition = new SpeechRecognition();
            this.recognition.lang = 'en-IN';
            this.recognition.interimResults = false;
            this.recognition.continuous = true;

            this.recognition.onresult = (event) => {
                let finalTranscript = '';
                for (let i = event.resultIndex; i < event.results.length; i++) {
                    if (event.results[i

                    ].isFinal) {
                        finalTranscript += event.results[i][0].transcript + ' ';
                    }
                }
                this.transcript = finalTranscript.trim();
            };

            this.recognition.onerror = (event) => {
                this.error = 'Speech error: ' + event.error;
            };

            this.recognition.start();
        } catch (e) {
            this.error = 'Microphone access failed: ' + e.message;
        }
    }

    stopListening() {
        if (this.recognition) {
            this.recognition.stop();
        }
    }

    getAnswerFromTranscript() {
        if (this.transcript) {
            getAnswer({ question: this.transcript })
                .then(result => {
                    let parsed = JSON.parse(result);
                    let rawAnswer = parsed.choices && parsed.choices.length > 0
                        ? parsed.choices[0].message.content
                        : 'No answer found.';
                    // Convert each line to a bullet point
                    let bulletPoints = rawAnswer
                        .split('\n')
                        .filter(line => line.trim() !== '')
                        .map(line => `<li>${line.trim()}</li>`)
                        .join('');
                    this.answer = `<ul>${bulletPoints}</ul>`;
                })
                .catch(error => {
                    this.answer = 'Error: ' + (error.body && error.body.message ? error.body.message : error.message);
                });
        }
    }
    clearTranscript() {
        this.transcript = '';
        this.answer = '';
        this.error = '';
    }
}