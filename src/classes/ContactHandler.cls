/**
 * Created by Igor Litvinyuk on 10.09.2018.
 */

public with sharing class ContactHandler{
    AccountContactService service = new AccountContactService();

    public void onBeforeDelete(List<Contact> oldContacts){
        service.deleteAccountContactViaContact(oldContacts);
    }
}