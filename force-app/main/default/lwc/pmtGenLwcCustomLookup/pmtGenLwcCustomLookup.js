/****************************************************************************
 * Name : GenLwcCustomLookup
 * Description : Shows the lookup field using record data tag
 *****************************************************************************/
import { LightningElement, api } from 'lwc';

export default class GenLwcCustomLookup extends LightningElement {
    //Object Name where the lookup is present
    @api childObjectApiName;
    //Lookup Field Name
    @api targetFieldApiName;
    //Label to be displayed for the field
    @api fieldLabel;
    //To disable the input
    @api disabled = false;
    //The value selected
    @api value;
    //To mark the field as required
    @api required = false;

    //Handle change in the lookup to send over the selected value
    handleChange(event) {
        console.log(event.detail.value);
        // Creates the event to send the data to parent component
        const selectedEvent = new CustomEvent('valueselected', {
            detail: {
                //The value selected
                value: event.detail.value,
                //The label of the field
                source: this.fieldLabel
            }
        });
        //dispatching the custom event
        this.dispatchEvent(selectedEvent);
    }

    @api isValid() {
        if (this.required) {
            this.template.querySelector('lightning-input-field').reportValidity();
        }
    }
}