/**
 * Created by Igor Litvinyuk on 04.09.2018.
 */

trigger AccountContactTrigger on AccountContact__c (before insert, after update, after delete) {

    AccountContactHandler handler = new AccountContactHandler();

    if(Trigger.isBefore){
        if(Trigger.isInsert) {
            handler.onBeforeInsert(Trigger.new);
        }
    }
    else  if(Trigger.isAfter){
        if(Trigger.isUpdate){
            handler.onAfterUpdate(Trigger.old, Trigger.new);
        }
        else if(Trigger.isDelete){
            handler.onAfterDelete(Trigger.old);
        }
    }
}