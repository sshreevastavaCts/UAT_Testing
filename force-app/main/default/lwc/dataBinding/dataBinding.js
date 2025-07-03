import { LightningElement } from 'lwc';

export default class DataBinding extends LightningElement {
    keyDifferences = [
        { id: '0', useCase: 'Display a computed value in template', getter: 'Yes', setter: 'No'},
        { id: '1', useCase: 'Need logic to run when a property changes', getter: 'No', setter: 'Yes'},
        { id: '2', useCase: 'Create a read-only derived value', getter: 'Yes', setter: 'No'},
        { id: '3', useCase: 'Track changes to an @api property', getter: 'No', setter: 'Yes'},
    ]
}