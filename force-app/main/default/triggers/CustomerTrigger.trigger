trigger CustomerTrigger on APEX_Customer__c (after update, after insert) {
    if(trigger.isAfter && trigger.isUpdate) {
        CustomerTriggerHelperSOQL.isAfterUpdateCall(Trigger.new, Trigger.oldMap);    
    }
}