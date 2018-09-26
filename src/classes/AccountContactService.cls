/**
 * Created by Igor Litvinyuk on 05.09.2018.
 */

public with sharing class AccountContactService{

    public static boolean isFirstRun;

    static {
        isFirstRun = true;
    }

    private static List<AccountContact__c> accountContactsWithIsPrimaryFieldTrue = new List<AccountContact__c>();
    private static List<AccountContact__c> accountContactsWithIsPrimaryFieldFalse = new List<AccountContact__c>();
    private static List<AccountContact__c> accountContactsWithAnotherIsPrimaryField = new List<AccountContact__c>();
    private static List<AccountContact__c> accountContactsWithAnotherContact = new List<AccountContact__c>();
    private static Set<Id> contactsIdsForUpdate = new Set<Id>();
    private static List<AccountContact__c> allAccountContactsWithIsPrimaryFieldTrue;
    private static List<AccountContact__c> allAccountContactsWithIsPrimaryFieldFalse;

    public void insertNewAccountContacts(List<AccountContact__c> newAccountContacts) {
        Set<Id> contactsIdsSet = getContactIdsSet(newAccountContacts);
        Map<Id, List<AccountContact__c>> accountContactsListByContactIdMap = getAccountContactsListByContactIdMap(newAccountContacts);
        checkAndDistributeAccountContacts(contactsIdsSet, accountContactsListByContactIdMap);
        List<AccountContact__c> accountContacts = getAccountContacts(contactsIdsSet);
        Map<Id, List<AccountContact__c>> accountContactsListByContactId = getAccountContactsListByContactIdMap(accountContacts);
        if (!accountContactsWithIsPrimaryFieldTrue.isEmpty()){
            changeIsPrimaryFieldToFalse(accountContactsListByContactId);
        }
        if (!accountContactsWithIsPrimaryFieldFalse.isEmpty()){
            changeIsPrimaryFieldToTrue(accountContactsListByContactId);
        }
    }

    public void beforeUpdateAccountContacts(List<AccountContact__c> oldAccountContacts, List<AccountContact__c> newAccountContacts) {
        distributeAccountContactsForUpdate(oldAccountContacts, newAccountContacts);
        if (!accountContactsWithAnotherIsPrimaryField.isEmpty()){
            fillAccountContactsLists();
        }
        else if (!accountContactsWithAnotherContact.isEmpty()){
            distributeIsPrimaryFieldOnAccountContacts(oldAccountContacts);
        }
    }

    public void afterUpdateAccountContacts() {
        if (!accountContactsWithAnotherIsPrimaryField.isEmpty() && !accountContactsWithIsPrimaryFieldTrue.isEmpty()){
            updateIsPrimaryFieldOnAccountContactsToFalse();
        }
        if (!accountContactsWithAnotherIsPrimaryField.isEmpty() && !accountContactsWithIsPrimaryFieldFalse.isEmpty()){
            updateIsPrimaryFieldOnAccountContactsToTrue();
        }
        if (!contactsIdsForUpdate.isEmpty()){
            updateIsPrimaryFieldOnAccountContacts();
        }
    }

    public void deleteAccountContacts(List<AccountContact__c> oldAccountContacts) {
        List<AccountContact__c> accountContactsWithIsPrimaryFieldTrue = getAccountContactsListWithSpecificIsPrimaryField(oldAccountContacts, true);
        Set<Id> contactsIdsSetWithIsPrimaryFieldTrue = getContactIdsSet(accountContactsWithIsPrimaryFieldTrue);
        List<AccountContact__c> allAccountContactsWithSameContacts = getAccountContacts(contactsIdsSetWithIsPrimaryFieldTrue);
        if (!allAccountContactsWithSameContacts.isEmpty()){
            Map<Id, List<AccountContact__c>> accountContactsListByContactId = getAccountContactsListByContactIdMap(allAccountContactsWithSameContacts);
            List<AccountContact__c> accountContactsForUpdate = new List<AccountContact__c>();
            for (Id contactId : contactsIdsSetWithIsPrimaryFieldTrue){
                List<AccountContact__c> accountContactsList = accountContactsListByContactId.get(contactId);
                if (!accountContactsList.isEmpty()){
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

    private void checkAndDistributeAccountContacts(Set<Id> contactsIdsSet, Map<Id, List<AccountContact__c>> accountContactsListByContactIdMap){
        for (Id contactId : contactsIdsSet){
            List<AccountContact__c> accountContacts = accountContactsListByContactIdMap.get(contactId);
            Integer count = 0;
            for (AccountContact__c accountContact : accountContacts){
                if (accountContact.isPrimary__c){
                    accountContactsWithIsPrimaryFieldTrue.add(accountContact);
                    count++;
                }
            }
            if (count == 0){
                accountContactsWithIsPrimaryFieldFalse.add(accountContacts[0]);
            }
            else if (count > 1){
                throw new AccountContactException('Only one AccountContact with specific Contact can have isPrimary field true!');
            }
        }
    }

    private void changeIsPrimaryFieldToFalse(Map<Id, List<AccountContact__c>> accountContactsListByContactId){
        for (AccountContact__c accountContact: accountContactsWithIsPrimaryFieldTrue){
            List<AccountContact__c> accountContactsList = accountContactsListByContactId.get(accountContact.Contact__c);
            if (accountContactsList != null){
                accountContact.IsPrimary__c = false;
            }
        }
    }

    private void changeIsPrimaryFieldToTrue(Map<Id, List<AccountContact__c>> accountContactsListByContactId){
        for (AccountContact__c accountContact: accountContactsWithIsPrimaryFieldFalse){
            List<AccountContact__c> accountContactsList = accountContactsListByContactId.get(accountContact.Contact__c);
            if (accountContactsList == null){
                accountContact.IsPrimary__c = true;
            }
        }
    }

    private List<AccountContact__c> getAccountContactsListWithSpecificIsPrimaryField(List<AccountContact__c> accountContacts, Boolean isPrimary){
        List<AccountContact__c> accountContactsList = new List<AccountContact__c>();
        for (AccountContact__c accountContact : accountContacts){
            if (accountContact.IsPrimary__c == isPrimary){
                accountContactsList.add(accountContact);
            }
        }
        return accountContactsList;
    }

    private List<AccountContact__c> getAccountContactsWithSpecificIsPrimaryField(Set<Id> contactsIds, Boolean isPrimary){
        return [
                SELECT
                        Contact__c
                        , IsPrimary__c
                        , CreatedDate
                FROM AccountContact__c
                WHERE Contact__c IN : contactsIds
                AND isPrimary__c =: isPrimary
                ORDER BY CreatedDate
        ];
    }

    private void distributeAccountContactsForUpdate(List<AccountContact__c> oldAccountContacts, List<AccountContact__c> newAccountContacts){
        for (Integer i = 0; i < oldAccountContacts.size(); i++){
            if (oldAccountContacts[i].Account__c != newAccountContacts[i].Account__c
                    && oldAccountContacts[i].isPrimary__c == newAccountContacts[i].isPrimary__c
                    && oldAccountContacts[i].Contact__c == newAccountContacts[i].Contact__c){
                continue;
            }
            if (oldAccountContacts[i].isPrimary__c != newAccountContacts[i].isPrimary__c
                    && oldAccountContacts[i].Account__c == newAccountContacts[i].Account__c
                    && oldAccountContacts[i].Contact__c == newAccountContacts[i].Contact__c){
                accountContactsWithAnotherIsPrimaryField.add(newAccountContacts[i]);
            }
            else if (oldAccountContacts[i].Contact__c != newAccountContacts[i].Contact__c
                    && oldAccountContacts[i].isPrimary__c == newAccountContacts[i].isPrimary__c
                    && oldAccountContacts[i].Account__c == newAccountContacts[i].Account__c){
                accountContactsWithAnotherContact.add(newAccountContacts[i]);
            }
            else if (oldAccountContacts[i].Account__c != newAccountContacts[i].Account__c
                    && (oldAccountContacts[i].isPrimary__c != newAccountContacts[i].isPrimary__c
                    || oldAccountContacts[i].Account__c != newAccountContacts[i].Account__c)){
                throw new AccountContactException('You can not change more than one field at a time');
            }
            else if (oldAccountContacts[i].Contact__c!= newAccountContacts[i].Contact__c
                    && (oldAccountContacts[i].isPrimary__c != newAccountContacts[i].isPrimary__c
                    || oldAccountContacts[i].Account__c != newAccountContacts[i].Account__c)){
                throw new AccountContactException('You can not change more than one field at a time');
            }
            else if (oldAccountContacts[i].isPrimary__c != newAccountContacts[i].isPrimary__c
                    && (oldAccountContacts[i].isPrimary__c != newAccountContacts[i].isPrimary__c
                    || oldAccountContacts[i].Contact__c != newAccountContacts[i].Contact__c)){
                throw new AccountContactException('You can not change more than one field at a time');
            }
        }
    }

    private void fillAccountContactsLists(){
        Set<Id> contactsIdsSet = getContactIdsSet(accountContactsWithAnotherIsPrimaryField);
        Map<Id, List<AccountContact__c>> accountContactsListByContactIdMap = getAccountContactsListByContactIdMap(accountContactsWithAnotherIsPrimaryField);
        checkAndDistributeAccountContacts(contactsIdsSet, accountContactsListByContactIdMap);
        allAccountContactsWithIsPrimaryFieldTrue = getAccountContactsWithSpecificIsPrimaryField(contactsIdsSet, true);
        allAccountContactsWithIsPrimaryFieldFalse = getAccountContactsWithSpecificIsPrimaryField(contactsIdsSet, false);
    }

    private void distributeIsPrimaryFieldOnAccountContacts(List<AccountContact__c> oldAccountContacts){
        Set<Id> contactsIdsSet = getContactIdsSet(accountContactsWithAnotherContact);
        Map<Id, List<AccountContact__c>> accountContactsListByContactIdWithAnotherContacts = getAccountContactsListByContactIdMap(accountContactsWithAnotherContact);
        List<AccountContact__c> accountContactsList = getAccountContacts(contactsIdsSet);
        if (accountContactsList.isEmpty()){
            for (Id contactId : contactsIdsSet){
                List<AccountContact__c> accountContacts = accountContactsListByContactIdWithAnotherContacts.get(contactId);
                accountContacts[0].isPrimary__c = true;
            }
        }
        else {
            Map<Id, List<AccountContact__c>> allAccountContactsListByContactIdMap = getAccountContactsListByContactIdMap(accountContactsList);
            for (Id contactId : contactsIdsSet){
                List<AccountContact__c> accountContList = accountContactsListByContactIdWithAnotherContacts.get(contactId);
                if (allAccountContactsListByContactIdMap.containsKey(contactId)){
                    for (AccountContact__c accountContact : accountContList){
                        accountContact.isPrimary__c = false;
                    }
                }
                else {
                    accountContList[0].isPrimary__c = true;
                }
            }
        }
        for (AccountContact__c accountContact : oldAccountContacts){
            if (accountContact.isPrimary__c){
                contactsIdsForUpdate.add(accountContact.Contact__c);
            }
        }
    }

    private void updateIsPrimaryFieldOnAccountContactsToFalse(){
        List<AccountContact__c> accountContactsForUpdate = new List<AccountContact__c>();
        Set<Id> contactsIdsWithIsPrimaryFieldTrue = getContactIdsSet(allAccountContactsWithIsPrimaryFieldTrue);
        Map<Id, List<AccountContact__c>> accountContactsListByContactIdWithIsPrimaryFieldTrue = getAccountContactsListByContactIdMap(allAccountContactsWithIsPrimaryFieldTrue);
        for (Id contactId : contactsIdsWithIsPrimaryFieldTrue){
            List<AccountContact__c> accountContactsList = accountContactsListByContactIdWithIsPrimaryFieldTrue.get(contactId);
            accountContactsList[0].isPrimary__c = false;
            accountContactsForUpdate.add(accountContactsList[0]);
        }
        update accountContactsForUpdate;
    }

    private void updateIsPrimaryFieldOnAccountContactsToTrue(){
        List<AccountContact__c> accountContactsForUpdate = new List<AccountContact__c>();
        Set<Id> contactsIdsPrimaryFieldFalse = getContactIdsSet(allAccountContactsWithIsPrimaryFieldFalse);
        Map<Id, List<AccountContact__c>> accountContactsListByContactIdWithIsPrimaryFieldFalse = getAccountContactsListByContactIdMap(allAccountContactsWithIsPrimaryFieldFalse);
        for(Id contactId : contactsIdsPrimaryFieldFalse){
            List<AccountContact__c> accountContactsList = accountContactsListByContactIdWithIsPrimaryFieldFalse.get(contactId);
            accountContactsList[0].isPrimary__c = true;
            accountContactsForUpdate.add(accountContactsList[0]);
        }
        update accountContactsForUpdate;
    }

    private void updateIsPrimaryFieldOnAccountContacts(){
        List<AccountContact__c> accountContactsForUpdate = new List<AccountContact__c>();
        List<AccountContact__c> accountContactsWithIsPrimaryFieldTrue = getAccountContactsWithSpecificIsPrimaryField(contactsIdsForUpdate, false);
        if (!accountContactsWithIsPrimaryFieldTrue.isEmpty()){
            Map<Id, List<AccountContact__c>> accountContactsListByContactIdWithIsPrimaryFieldFalse = getAccountContactsListByContactIdMap(accountContactsWithIsPrimaryFieldTrue);
            for(Id contactId : contactsIdsForUpdate){
                List<AccountContact__c> accountContactsList = accountContactsListByContactIdWithIsPrimaryFieldFalse.get(contactId);
                accountContactsList[0].isPrimary__c = true;
                accountContactsForUpdate.add(accountContactsList[0]);
            }
            update accountContactsForUpdate;
        }
    }

    private class AccountContactException extends Exception{

    }
}