/**
 * Created by Igor Litvinyuk on 05.09.2018.
 */

public with sharing class AccountContactService{
    private static boolean isUpdate = false;

    public void insertingNewAccountContacts(List<AccountContact__c> newAccountContacts) {
        Set<Id> contactsIdsSet = this.getContactIdsSet(newAccountContacts);
        Map<Id, List<AccountContact__c>> accountContactsListByContactIdMap = this.getAccountContactsListByContactIdMap(newAccountContacts);
        for (Id contactId : contactsIdsSet){
            if (accountContactsListByContactIdMap.get(contactId).size() > 1){
                throw new AccountContactException('AccountContact with same Contact already exists!');
            }
        }

        List<AccountContact__c> accountContactsWithIsPrimaryFieldTrue = new List<AccountContact__c>();
        List<AccountContact__c> accountContactsWithIsPrimaryFieldFalse = new List<AccountContact__c>();
        for (AccountContact__c accountContact : newAccountContacts) {
            if (accountContact.IsPrimary__c == true) {
                accountContactsWithIsPrimaryFieldTrue.add(accountContact);
            } else {
                accountContactsWithIsPrimaryFieldFalse.add(accountContact);
            }
        }
        List<AccountContact__c> accountContacts = this.getAccountContacts(contactsIdsSet);
        Map<Id, List<AccountContact__c>> accountContactsListByContactId = this.getAccountContactsListByContactIdMap(accountContacts);
        for(AccountContact__c accountContact: accountContactsWithIsPrimaryFieldTrue){
            List<AccountContact__c> accountContactsList = accountContactsListByContactId.get(accountContact.Contact__c);
            if(accountContactsList != null){
                accountContact.IsPrimary__c = false;
            }
        }

        for(AccountContact__c accountContact: accountContactsWithIsPrimaryFieldFalse){
            List<AccountContact__c> accountContactsList = accountContactsListByContactId.get(accountContact.Contact__c);
            if(accountContactsList == null){
                accountContact.IsPrimary__c = true;
            }
        }
    }

    public void updatingAccountContacts(List<AccountContact__c> oldAccountContacts, List<AccountContact__c> newAccountContacts) {
        List<AccountContact__c> accountContactsWithIsPrimaryFieldTrue = new List<AccountContact__c>();
        List<AccountContact__c> accountContactsWithIsPrimaryFieldFalse = new List<AccountContact__c>();
        for (Integer i = 0; i < oldAccountContacts.size(); i++){
            if (oldAccountContacts[i].isPrimary__c == false && newAccountContacts[i].isPrimary__c == true){
                accountContactsWithIsPrimaryFieldTrue.add(oldAccountContacts[i]);
            }
            else {
                accountContactsWithIsPrimaryFieldFalse.add(oldAccountContacts[i]);
            }
        }
        Set<Id> contactsIdsSetWithIsPrimaryFieldTrue = this.getContactIdsSet(accountContactsWithIsPrimaryFieldTrue);
        List<AccountContact__c> allAccountContactsWithIsPrimaryFieldTrue = this.getAccountContacts(contactsIdsSetWithIsPrimaryFieldTrue);
        Map<Id, List<AccountContact__c>> accountContactsListByContactIdWithIsPrimaryFieldTrue = this.getAccountContactsListByContactIdMap(allAccountContactsWithIsPrimaryFieldTrue);
        List<AccountContact__c> accountContactsForUpdateTrueToFalse = new List<AccountContact__c>();
        for(AccountContact__c accountContact: accountContactsWithIsPrimaryFieldTrue){
            List<AccountContact__c> accountContactsList = accountContactsListByContactIdWithIsPrimaryFieldTrue.get(accountContact.Contact__c);
            accountContactsList[0].isPrimary__c = false;
            accountContactsForUpdateTrueToFalse.add(accountContactsList[0]);
        }
        if (isUpdate == false){
            update accountContactsForUpdateTrueToFalse;
            isUpdate = true;
        }
    }

    public void deletingAccountContacts(List<AccountContact__c> oldAccountContacts) {
        List<AccountContact__c> allAccountContactsWithIsPrimaryFieldTrue = new List<AccountContact__c>();
        for (Integer i = 0; i < oldAccountContacts.size(); i++){
            if (oldAccountContacts[i].isPrimary__c == true){
                allAccountContactsWithIsPrimaryFieldTrue.add(oldAccountContacts[i]);
            }
        }
        Set<Id> contactsIdsSetWithIsPrimaryFieldTrue = this.getContactIdsSet(allAccountContactsWithIsPrimaryFieldTrue);
        List<AccountContact__c> allAccountContactsWithSameContacts = this.getAccountContacts(contactsIdsSetWithIsPrimaryFieldTrue);
        if (allAccountContactsWithSameContacts.size() != 0){
            Map<Id, List<AccountContact__c>> accountContactsListByContactId = this.getAccountContactsListByContactIdMap(allAccountContactsWithSameContacts);
            List<AccountContact__c> accountContactsForUpdate = new List<AccountContact__c>();
            for (Id contactId : contactsIdsSetWithIsPrimaryFieldTrue){
                List<AccountContact__c> accountContactsList = accountContactsListByContactId.get(contactId);
                if (accountContactsList.size() > 0){
                    Integer lastIndex = accountContactsList.size()-1;
                    accountContactsList[lastIndex].isPrimary__c = true;
                    accountContactsForUpdate.addAll(accountContactsList);
                }
            }
            update accountContactsForUpdate;
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

    public void deletingAccount(List<Account> oldAccounts) {
        Set<Id> accountsIds = new Set<Id>();
        for (Account account : oldAccounts) {
            accountsIds.add(account.Id);
        }
        delete [
                SELECT Id
                FROM AccountContact__c
                WHERE Account__c IN : accountsIds];
    }
}