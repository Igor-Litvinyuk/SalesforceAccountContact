/**
 * Created by Igor Litvinyuk on 05.09.2018.
 */

public with sharing class AccountContactService{

    public void insertNewAccountContacts(List<AccountContact__c> newAccountContacts) {
        Set<Id> contactsIdsSet = this.getContactIdsSet(newAccountContacts);
        Map<Id, List<AccountContact__c>> accountContactsListByContactIdMap = this.getAccountContactsListByContactIdMap(newAccountContacts);
        this.checkCountOfSameContactsFromTrigger(contactsIdsSet, accountContactsListByContactIdMap);

        List<AccountContact__c> accountContactsWithIsPrimaryFieldTrue = getAccountContactsListWithIsPrimaryFieldTrue(newAccountContacts);
        List<AccountContact__c> accountContactsWithIsPrimaryFieldFalse = getAccountContactsListWithIsPrimaryFieldFalse(newAccountContacts);

        List<AccountContact__c> accountContacts = this.getAccountContacts(contactsIdsSet);
        Map<Id, List<AccountContact__c>> accountContactsListByContactId = this.getAccountContactsListByContactIdMap(accountContacts);
        this.changeIsPrimaryFieldOnAccountContactsToFalse(accountContactsWithIsPrimaryFieldTrue, accountContactsListByContactId);
        this.changeIsPrimaryFieldOnAccountContactsToTrue(accountContactsWithIsPrimaryFieldFalse, accountContactsListByContactId);
    }

    public void updateAccountContacts(List<AccountContact__c> oldAccountContacts, List<AccountContact__c> newAccountContacts) {

    }

    public void deleteAccountContacts(List<AccountContact__c> oldAccountContacts) {
        List<AccountContact__c> accountContactsWithIsPrimaryFieldTrue = getAccountContactsListWithIsPrimaryFieldTrue(oldAccountContacts);
        Set<Id> contactsIdsSetWithIsPrimaryFieldTrue = this.getContactIdsSet(accountContactsWithIsPrimaryFieldTrue);
        List<AccountContact__c> allAccountContactsWithSameContacts = this.getAccountContacts(contactsIdsSetWithIsPrimaryFieldTrue);
        if (allAccountContactsWithSameContacts.size() != 0){
            Map<Id, List<AccountContact__c>> accountContactsListByContactId = this.getAccountContactsListByContactIdMap(allAccountContactsWithSameContacts);
            List<AccountContact__c> accountContactsForUpdate = new List<AccountContact__c>();
            for (Id contactId : contactsIdsSetWithIsPrimaryFieldTrue){
                List<AccountContact__c> accountContactsList = accountContactsListByContactId.get(contactId);
                if (accountContactsList.size() > 0){
                    accountContactsList[0].isPrimary__c = true;
                    accountContactsForUpdate.add(accountContactsList[0]);
                }
            }
            update accountContactsForUpdate;
        }
    }

    public void deleteAccountContactViaAccount(List<Account> oldAccounts) {
        Set<Id> accountsIds = new Set<Id>();
        for (Account account : oldAccounts) {
            accountsIds.add(account.Id);
        }
        List<AccountContact__c> accountContacts = [
                SELECT Id
                FROM AccountContact__c
                WHERE Account__c IN : accountsIds
        ];
        if (!accountContacts.isEmpty()){
            delete accountContacts;
        }
    }

    public void deleteAccountContactViaContact(List<Contact> oldContacts) {
        Set<Id> contactsIds = new Set<Id>();
        for (Contact contact : oldContacts) {
            contactsIds.add(contact.Id);
        }
        List<AccountContact__c> accountContacts = [
                SELECT Id
                FROM AccountContact__c
                WHERE Contact__c IN : contactsIds
        ];
        if (!accountContacts.isEmpty()){
            delete accountContacts;
        }
    }

    private Set<Id> getContactIdsSet(List<AccountContact__c> accountContacts) {
        Set<Id> result = new Set<Id>();
        for (AccountContact__c accountContact : accountContacts) {
            result.add(accountContact.Contact__c);
        }
        return result;
    }

    private List<AccountContact__c> getAccountContacts(Set<Id> contactsIds) {
        return [
                SELECT
                        Contact__c
                        , IsPrimary__c
                        , CreatedDate
                FROM AccountContact__c
                WHERE Contact__c IN : contactsIds
                ORDER BY CreatedDate];
    }

    private Map<Id, List<AccountContact__c>> getAccountContactsListByContactIdMap(List<AccountContact__c> accountContacts) {
        Map<Id, List<AccountContact__c>> resultMap = new Map<Id, List<AccountContact__c>>();
        for (AccountContact__c accountContact : accountContacts) {
            if (!resultMap.containsKey(accountContact.Contact__c)) {
                resultMap.put(accountContact.Contact__c, new List<AccountContact__c>());
            }
            List<AccountContact__c> accountContactsList = resultMap.get(accountContact.Contact__c);
            accountContactsList.add(accountContact);
        }
        return resultMap;
    }

    private void checkCountOfSameContactsFromTrigger(Set<Id> contactsIdsSet, Map<Id, List<AccountContact__c>> accountContactsListByContactIdMap){
        for (Id contactId : contactsIdsSet){
            if (accountContactsListByContactIdMap.get(contactId).size() > 1){
                throw new AccountContactException('AccountContact with same Contact already exists!');
            }
        }
    }

    private List<AccountContact__c> getAccountContactsListWithIsPrimaryFieldTrue(List<AccountContact__c> newAccountContacts){
        List<AccountContact__c> accountContacts = new List<AccountContact__c>();
        for (AccountContact__c accountContact : newAccountContacts) {
            if (accountContact.IsPrimary__c) {
                accountContacts.add(accountContact);
            }
        }
        return accountContacts;
    }

    private List<AccountContact__c> getAccountContactsListWithIsPrimaryFieldFalse(List<AccountContact__c> newAccountContacts){
        List<AccountContact__c> accountContacts = new List<AccountContact__c>();
        for (AccountContact__c accountContact : newAccountContacts) {
            if (!accountContact.IsPrimary__c) {
                accountContacts.add(accountContact);
            }
        }
        return accountContacts;
    }

    private void changeIsPrimaryFieldOnAccountContactsToFalse(List<AccountContact__c> accountContacts, Map<Id, List<AccountContact__c>> accountContactsListByContactId){
        for (AccountContact__c accountContact: accountContacts){
            List<AccountContact__c> accountContactsList = accountContactsListByContactId.get(accountContact.Contact__c);
            if (accountContactsList != null){
                accountContact.IsPrimary__c = false;
            }
        }
    }

    private void changeIsPrimaryFieldOnAccountContactsToTrue(List<AccountContact__c> accountContacts, Map<Id, List<AccountContact__c>> accountContactsListByContactId){
        for (AccountContact__c accountContact: accountContacts){
            List<AccountContact__c> accountContactsList = accountContactsListByContactId.get(accountContact.Contact__c);
            if (accountContactsList == null){
                accountContact.IsPrimary__c = true;
            }
        }
    }

    private class AccountContactException extends Exception{
    }
}