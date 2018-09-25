/**
 * Created by Igor Litvinyuk on 05.09.2018.
 */

public with sharing class AccountContactService{

    public static boolean isFirstRun;

    static {
        isFirstRun = true;
    }

    private static List<AccountContact__c> accountContactsWithIsPrimaryFieldTrueForUpdate;
    private static List<AccountContact__c> accountContactsWithIsPrimaryFieldFalseForUpdate;
    private static List<AccountContact__c> accountContactsWithIsPrimaryFieldFalseToTrue = new List<AccountContact__c>();
    private static List<AccountContact__c> accountContactsWithIsPrimaryFieldTrueToFalse = new List<AccountContact__c>();
    private static List<AccountContact__c> accountContactsWithAnotherContact = new List<AccountContact__c>();
    private static List<AccountContact__c> accountContactsForUpdate = new List<AccountContact__c>();

    public void insertNewAccountContacts(List<AccountContact__c> newAccountContacts) {
        List<AccountContact__c> accountContactsWithIsPrimaryFieldTrue = new List<AccountContact__c>();
        List<AccountContact__c> accountContactsWithIsPrimaryFieldFalse = new List<AccountContact__c>();
        Set<Id> contactsIdsSet = getContactIdsSet(newAccountContacts);
        Map<Id, List<AccountContact__c>> accountContactsListByContactIdMap = getAccountContactsListByContactIdMap(newAccountContacts);
        for (Id contactId : contactsIdsSet){
            List<AccountContact__c> accountContacts = accountContactsListByContactIdMap.get(contactId);
            Integer count = 0;
            for (AccountContact__c accountContact : accountContacts){
                if (accountContact.isPrimary__c == true){
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
        List<AccountContact__c> accountContacts = getAccountContacts(contactsIdsSet);
        Map<Id, List<AccountContact__c>> accountContactsListByContactId = getAccountContactsListByContactIdMap(accountContacts);
        for (AccountContact__c accountContact: accountContactsWithIsPrimaryFieldTrue){
            List<AccountContact__c> accountContactsList = accountContactsListByContactId.get(accountContact.Contact__c);
            if (accountContactsList != null){
                accountContact.IsPrimary__c = false;
            }
        }
        for (AccountContact__c accountContact: accountContactsWithIsPrimaryFieldFalse){
            List<AccountContact__c> accountContactsList = accountContactsListByContactId.get(accountContact.Contact__c);
            if (accountContactsList == null){
                accountContact.IsPrimary__c = true;
            }
        }
    }

    public void beforeUpdateAccountContacts(List<AccountContact__c> oldAccountContacts, List<AccountContact__c> newAccountContacts) {
        distributionAccountContacts(oldAccountContacts, newAccountContacts);
        Set<Id> contactsIdsSetWithIsPrimaryFieldTrue = getContactIdsSet(accountContactsWithIsPrimaryFieldFalseToTrue);
        accountContactsWithIsPrimaryFieldFalseForUpdate = getAccountContactsWithSpecificIsPrimaryField(contactsIdsSetWithIsPrimaryFieldTrue, true);
        Set<Id> contactsIdsSetWithIsPrimaryFieldFalse = getContactIdsSet(accountContactsWithIsPrimaryFieldTrueToFalse);
        accountContactsWithIsPrimaryFieldTrueForUpdate = getAccountContactsWithSpecificIsPrimaryField(contactsIdsSetWithIsPrimaryFieldFalse, false);
        Set<Id> contactsIdsSetWithSpecificContacts = getContactIdsSet(newAccountContacts);
        List<AccountContact__c> accountContactsWistSpecificContacts = getAccountContacts(contactsIdsSetWithSpecificContacts);
        changeIsPrimaryField(accountContactsWistSpecificContacts);
    }

    public void afterUpdateAccountContacts() {
        if(accountContactsWithIsPrimaryFieldFalseToTrue != null){
            addAccountContactsForUpdateWithIsPrimaryFieldFalse();
        }

        if(accountContactsWithIsPrimaryFieldTrueToFalse != null){
            addAccountContactsForUpdateWithIsPrimaryFieldTrue();
        }
        update accountContactsForUpdate;
    }

    public void deleteAccountContacts(List<AccountContact__c> oldAccountContacts) {
        List<AccountContact__c> accountContactsWithIsPrimaryFieldTrue = getAccountContactsListWithSpecificIsPrimaryField(oldAccountContacts, true);
        Set<Id> contactsIdsSetWithIsPrimaryFieldTrue = getContactIdsSet(accountContactsWithIsPrimaryFieldTrue);
        List<AccountContact__c> allAccountContactsWithSameContacts = getAccountContacts(contactsIdsSetWithIsPrimaryFieldTrue);
        if (allAccountContactsWithSameContacts.size() != 0){
            Map<Id, List<AccountContact__c>> accountContactsListByContactId = getAccountContactsListByContactIdMap(allAccountContactsWithSameContacts);
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

    private List<AccountContact__c> getAccountContactsListWithSpecificIsPrimaryField(List<AccountContact__c> accountContacts, Boolean isPrimary){
        List<AccountContact__c> accountContactsList = new List<AccountContact__c>();
        for (AccountContact__c accountContact : accountContacts){
            if (accountContact.IsPrimary__c == isPrimary){
                accountContactsList.add(accountContact);
            }
        }
        return accountContactsList;
    }

    private List<AccountContact__c> getAccountContactsWithSpecificIsPrimaryField(Set<Id> contactsIds, boolean isPrimary){
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

    private void distributionAccountContacts(List<AccountContact__c> oldAccountContacts, List<AccountContact__c> newAccountContacts){
        for (Integer i = 0; i < oldAccountContacts.size(); i++){
            if (oldAccountContacts[i].Account__c != newAccountContacts[i].Account__c){
                continue;
            }
            if (!oldAccountContacts[i].isPrimary__c && newAccountContacts[i].isPrimary__c
                    && oldAccountContacts[i].Contact__c == newAccountContacts[i].Contact__c){
                accountContactsWithIsPrimaryFieldFalseToTrue.add(oldAccountContacts[i]);
            }
            else if (oldAccountContacts[i].isPrimary__c && !newAccountContacts[i].isPrimary__c
                    && oldAccountContacts[i].Contact__c == newAccountContacts[i].Contact__c){
                accountContactsWithIsPrimaryFieldTrueToFalse.add(newAccountContacts[i]);
            }

            else if (oldAccountContacts[i].Contact__c != newAccountContacts[i].Contact__c){
                accountContactsWithAnotherContact.add(newAccountContacts[i]);
            }
        }
    }

    private void addAccountContactsForUpdateWithIsPrimaryFieldFalse(){
        Set<Id> contactsIdsWithIsPrimaryFieldTrue = getContactIdsSet(accountContactsWithIsPrimaryFieldFalseForUpdate);
        Map<Id, List<AccountContact__c>> accountContactsListByContactIdWithIsPrimaryFieldTrue = getAccountContactsListByContactIdMap(accountContactsWithIsPrimaryFieldFalseForUpdate);
        for(Id contactId : contactsIdsWithIsPrimaryFieldTrue){
            List<AccountContact__c> accountContactsList = accountContactsListByContactIdWithIsPrimaryFieldTrue.get(contactId);
            accountContactsList[0].isPrimary__c = false;
            accountContactsForUpdate.add(accountContactsList[0]);
        }
    }

    private void addAccountContactsForUpdateWithIsPrimaryFieldTrue(){
        Set<Id> contactsIdsPrimaryFieldFalse = getContactIdsSet(accountContactsWithIsPrimaryFieldTrueForUpdate);
        Map<Id, List<AccountContact__c>> accountContactsListByContactIdWithIsPrimaryFieldFalse = getAccountContactsListByContactIdMap(accountContactsWithIsPrimaryFieldTrueForUpdate);
        for(Id contactId : contactsIdsPrimaryFieldFalse){
            List<AccountContact__c> accountContactsList = accountContactsListByContactIdWithIsPrimaryFieldFalse.get(contactId);
            accountContactsList[0].isPrimary__c = true;
            accountContactsForUpdate.add(accountContactsList[0]);
        }
    }

    private void changeIsPrimaryField(List<AccountContact__c> accountContactsWistSpecificContacts){
        if (accountContactsWistSpecificContacts.size() == 0){
            for (AccountContact__c accountContact : accountContactsWithAnotherContact){
                accountContact.isPrimary__c = true;
            }
        }
        else {
            Map<Id, List<AccountContact__c>> accountContactsListWithSpecificContactByContactId = getAccountContactsListByContactIdMap(accountContactsWistSpecificContacts);
            for (AccountContact__c accountContact : accountContactsWithAnotherContact){
                List<AccountContact__c> accountContactsList = accountContactsListWithSpecificContactByContactId.get(accountContact.Contact__c);
                if (accountContactsList.size() == 0){
                    accountContact.isPrimary__c = true;
                }
                else {
                    accountContact.isPrimary__c = false;
                }
            }
        }
    }

    private class AccountContactException extends Exception{

    }
}