/**
 * Created by Igor Litvinyuk on 04.09.2018.
 */

trigger AccountTrigger on Account (before insert) {
    if (Trigger.isBefore && Trigger.isInsert) {
        AccountTriggerHandler.CreateAccounts(Trigger.New);
    }
}