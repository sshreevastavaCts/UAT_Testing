import { LightningElement, track } from 'lwc';

export default class Lwc_child_cmp3 extends LightningElement {
    customer_priority_value = 'None';
    sla_exp;
    location;
    slaSerialNo;
    @track Customer_Priority_Options = [
        {label: 'None', value: 'None'},
        {label: 'Low', value: 'Low'},
        {label: 'Medium', value: 'Medium'},
        {label: 'High', value: 'High'}
    ];

    active_value = 'None';
    @track Active_Options = [
        {label: 'None', value: 'None'},
        {label: 'Maybe', value: 'Maybe'},
        {label: 'Yes', value: 'Yes'},
        {label: 'No', value: 'No'}
    ];

    active_value = 'None';
    @track Active_Options = [
        {label: 'None', value: 'None'},
        {label: 'Yes', value: 'Yes'},
        {label: 'No', value: 'No'}
    ];

    SLA_value = 'None';
    @track SLA_Options = [
        {label: 'Gold', value: 'Gold'},
        {label: 'Silver', value: 'Silver'},
        {label: 'Platinum', value: 'Platinum'},
        {label: 'Bronze', value: 'Bronze'}
    ];

    Upsell_Opportunity_value = 'None';
    @track Upsell_Opportunity_Options = [
        {label: 'None', value: 'None'},
        {label: 'Maybe', value: 'Maybe'},
        {label: 'Yes', value: 'Yes'},
        {label: 'No', value: 'No'}
    ];

    handleCustomerPriority(event) {
        this.customer_priority_value = event.detail.value;
        console.log('get CustomerPriority ==>'+this.customer_priority_value);
    }

    handleActive(event) {
        this.active_value = event.detail.value;
        console.log('get active ==>'+this.active_value);
    }

    handleSlaExp(event) {
        this.sla_exp = event.detail.value;
        console.log('get Sla Exp DATE ==>'+this.sla_exp);
    }

    handleLocation(event) {
        this.location = event.detail.value;
        console.log('get location ==>'+this.location);
    }
    handleSLA(event) {
        this.SLA_value = event.detail.value;
        console.log('get SLA ==>'+this.SLA_value);
    }
     
    handleSlaSerialNo(event) {
        this.slaSerialNo = event.detail.value;
        console.log('get slaSerialNo ==>'+this.slaSerialNo);
    }
    handleUpsellOpportunity(event) {
        this.Upsell_Opportunity_value = event.detail.value;
        console.log('get Upsell_Opportunity_value ==>'+this.Upsell_Opportunity_value);
    }
}