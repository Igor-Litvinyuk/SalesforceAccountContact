/**
 * Created by Igor Litvinyuk on 10.09.2018.
 */

trigger AccountTrigger on Account (before delete) {
    AccountHandler handler = new AccountHandler();

    if(Trigger.isBefore){
        if(Trigger.isDelete) {
            handler.onBeforeDelete(Trigger.old);
        }
    }
}