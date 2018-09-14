/**
 * Created by Igor Litvinyuk on 04.09.2018.
 */

trigger AccountContactTrigger on AccountContact__c (before insert, after update, after delete) {

    private static boolean isFirstRun = true;
    AccountContactHandler handler = new AccountContactHandler();

    if(Trigger.isBefore){
        if(Trigger.isInsert) {
            handler.onBeforeInsert(Trigger.new);
        }
    }
    else if(Trigger.isAfter){
        if(Trigger.isUpdate){
            if(isFirstRun){
                handler.onAfterUpdate(Trigger.old, Trigger.new);
                isFirstRun = false;
            }
        }
        else if(Trigger.isDelete){
            handler.onAfterDelete(Trigger.old);
        }
    }
}