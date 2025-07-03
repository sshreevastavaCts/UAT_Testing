import { LightningElement, track } from 'lwc';

export default class HomeCmp extends LightningElement {
    @track lwcItemList = [
        { id: 1, name: 'Built using modern JavaScript (ES6+)' },
        { id: 2, name: 'Based on Web Components standard' },
        { id: 3, name: 'Lightweight and better performance' },
        { id: 4, name: 'Easier to learn for developers with JavaScript/HTML/CSS experience' },
    ];

    @track aurItemList = [
        { id: 1, name: 'Uses Aura-specific syntax (.cmp, .controller, .helper)' },
        { id: 2, name: 'Heavier and more framework-dependent' },
        { id: 3, name: 'More verbose and harder to debug' },
        { id: 4, name: 'Still used in many legacy applications' },
    ];

    @track keyDifferences = [
        { id: 1, feature:   'Framework Base', lwc: 'Web Standards (ES6, Web Components)', aura: 'Custom Salesforce framework' },
        { id: 2, feature:   'Performance', lwc: 'High (due to native browser APIs)', aura: 'Lower' },
        { id: 3, feature:   'Syntax', lwc: 'Modern JavaScript (modules, classes)', aura: 'Aura-specific markup & JS' },
        { id: 4, feature:   'Learning Curve', lwc: 'Easier for JS developers', aura: 'Steeper' },
        { id: 5, feature:   'Reusability', lwc: 'High', aura: 'Moderate ' },
        { id: 6, feature:   'Component Files', lwc: '.html, .js, .js-meta.xml', aura: '.cmp, .controller.js, .helper.js, etc' },
        { id: 7, feature:   'Shadow DOM', lwc: 'Yes (encapsulation supported)', aura: 'No (styles can leak)' },
        { id: 8, feature:   'Data Binding', lwc: 'One-way binding', aura: 'Two-way binding' },
        { id: 8, feature:   'Interop', lwc: 'Can use Aura components inside LWC (but not vice versa)', aura: 'Can’t embed LWC directly' },
    ];
    // @track showLwc = true;
    // @track showAura = false;
    // @track showKeyDifferences = false;
    // @track showLwcList = false;
    // @track showAuraList = false;
    // @track showKeyDifferencesList = false;
    // @track showLwcListButton = true;
    // @track showAuraListButton = true;
    // @track showKeyDifferencesListButton = true;
}