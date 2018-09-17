/**
 * Created by Igor Litvinyuk on 04.09.2018.
 */

public with sharing class AccountContactHandler {
    AccountContactService service = new AccountContactService();

    public void onBeforeInsert(List<AccountContact__c> newAccountContacts) {
        service.insertNewAccountContacts(newAccountContacts);
    }

    public void onBeforeUpdate(List<AccountContact__c> oldAccountContacts, List<AccountContact__c> newAccountContacts) {
        service.beforeUpdateAccountContacts(oldAccountContacts, newAccountContacts);
    }

    public void onAfterUpdate() {
        service.updateAccountContacts();
    }

    public void onAfterDelete(List<AccountContact__c> oldAccountContacts) {
        service.deleteAccountContacts(oldAccountContacts);
    }
}