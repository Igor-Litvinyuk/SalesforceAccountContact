/**
 * Created by Igor Litvinyuk on 10.09.2018.
 */

trigger ContactTrigger on Contact (before delete) {
    ContactHandler handler = new ContactHandler();

    if(Trigger.isBefore){
        if(Trigger.isDelete) {
            handler.onBeforeDelete(Trigger.old);
        }
    }
}