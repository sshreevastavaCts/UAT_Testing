import { LightningElement, track, api } from 'lwc';
import startFileUpload from '@salesforce/apex/FilesUploadCtl.startFileUpload';
import uploadFileChunk from '@salesforce/apex/FilesUploadCtl.uploadFileChunk';
import deleteFile from '@salesforce/apex/FilesUploadCtl.deleteFile';

const CHUNK_SIZE = 750000; // ~0.75 MB per chunk

export default class FileUpload extends LightningElement {
    @api recordId = '001Qy000012sarFIAQ';
    @track files = [];

    handleFileChange(event) {
        if (event.target.files.length > 0) {
            [...event.target.files].forEach(file => {
                this.readFile(file);
            });
        }
    }

    readFile(file) {
        const reader = new FileReader();
        reader.onload = () => {
            const base64 = reader.result.split(',')[1];
            this.uploadInChunks(file, base64);
        };
        reader.readAsDataURL(file);
    }

    uploadInChunks(file, base64Data) {
        let start = 0;
        let end = CHUNK_SIZE;
        let chunkIndex = 0;
        let totalChunks = Math.ceil(base64Data.length / CHUNK_SIZE);

        const uploadChunk = () => {
            const chunk = base64Data.substring(start, end);

            const uploadMethod = (chunkIndex === 0) ? startFileUpload : uploadFileChunk;

            uploadMethod({ fileName: file.name, parentId: this.recordId, base64Data: chunk})
                .then((result) => {
                    let fileObj = this.files.find(f => f.name === file.name);
                    if (!fileObj) {
                        this.files.push({
                            id: result,
                            name: file.name,
                            size: (file.size / 1024).toFixed(2) + ' KB',
                            progress: 0
                        });
                        fileObj = this.files.find(f => f.name === file.name);
                    }
                    fileObj.progress = Math.round(((chunkIndex + 1) / totalChunks) * 100);

                    // Move to next chunk
                    start = end;
                    end = start + CHUNK_SIZE;
                    chunkIndex++;

                    if (start < base64Data.length) {
                        uploadChunk(); // Recursive call
                    }
                })
                .catch(error => {
                    console.error('Upload error:', error);
                });
        };

        uploadChunk();
    }

    handleDelete(event) {
        const fileId = event.target.dataset.id;
        deleteFile({ contentDocumentId: fileId })
            .then(() => {
                this.files = this.files.filter(file => file.id !== fileId);
            })
            .catch(error => {
                console.error('Delete error:', error);
            });
    }
}