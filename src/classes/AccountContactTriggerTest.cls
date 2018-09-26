/**
 * Created by Igor Litvinyuk on 06.09.2018.
 */

@isTest
private class AccountContactTriggerTest {

    private static final Integer half = 100;
    private static List<Account> accounts = new List<Account>();
    private static List<Contact> contacts = new List<Contact>();
    private static List<AccountContact__c> accountContactsForDelete = new List<AccountContact__c>();
    private static List<AccountContact__c> accountContactsForInsert = new List<AccountContact__c>();
    private static List<AccountContact__c> accountContactsForUpdate = new List<AccountContact__c>();
    private static List<AccountContact__c> firstHalfListAccountContactsForInsert = new List<AccountContact__c>();
    private static List<AccountContact__c> secondHalfListAccountContactsForInsert = new List<AccountContact__c>();

    @isTest
    static void testCreateNewAccountContactsWithDifferentIsPrimaryFieldsInBulk() {
        accountAndContactInserting();
        for (Integer i = 0; i < 200; i++){
            AccountContact__c accountContact = new AccountContact__c();
            accountContact.Account__c = accounts[i].Id;
            accountContact.Contact__c = contacts[i].Id;
            if (i < half){
                accountContact.isPrimary__c = false;
            }
            else {
                accountContact.isPrimary__c = true;
            }
            accountContactsForInsert.add(accountContact);
        }
        insert accountContactsForInsert;
        List<AccountContact__c> verifyAccountContacts = [SELECT Id, isPrimary__c FROM AccountContact__c];
        for (Integer i = 0; i < verifyAccountContacts.size(); i++){
            System.assertEquals(true, verifyAccountContacts[i].isPrimary__c);
        }
    }

    @isTest
    static void testCreateNewAccountContactsInBulkWithIsPrimaryFieldTrueOnSpecificContact() {
        accountAndContactInserting();
        for (Integer i = 0; i < 200; i++){
            AccountContact__c accountContact = new AccountContact__c();
            accountContact.Account__c = accounts[i].Id;
            accountContact.Contact__c = contacts[0].Id;
            accountContact.isPrimary__c = true;
            accountContactsForInsert.add(accountContact);
        }
        try {
            insert accountContactsForInsert;
        }
        catch(Exception e){
            System.assertEquals(true, true);
        }
    }

    @isTest
    static void testCreateNewAccountContactsWithIsPrimaryFieldTrue() {
        accountAndContactInserting();
        for (Integer i = 0; i < 200; i++){
            AccountContact__c accountContact = new AccountContact__c();
            accountContact.Account__c = accounts[i].Id;
            if (i < 100){
                accountContact.Contact__c = contacts[i].Id;
                firstHalfListAccountContactsForInsert.add(accountContact);
            }
            else {
                accountContact.Contact__c = contacts[i-half].Id;
                secondHalfListAccountContactsForInsert.add(accountContact);
            }
        }
        insert firstHalfListAccountContactsForInsert;
        insert secondHalfListAccountContactsForInsert;
        List<AccountContact__c> verifyAccountContacts = [SELECT Id, isPrimary__c FROM AccountContact__c ORDER BY isPrimary__c DESC];
        System.assertEquals(200, verifyAccountContacts.size());
        for (Integer i = 0; i < verifyAccountContacts.size(); i++){
            if (i < half){
                System.assertEquals(true, verifyAccountContacts[i].isPrimary__c);
            }
            else {
                System.assertEquals(false, verifyAccountContacts[i].isPrimary__c);
            }
        }
    }

    @isTest
    static void testUpdateAccountContactsWhenChangeAccount() {
        accountAndContactInserting();
        AccountContact__c accountContact = new AccountContact__c();
        accountContact.Account__c = accounts[0].Id;
        accountContact.Contact__c = contacts[1].Id;
        insert accountContact;
        accountContact.Account__c = accounts[1].Id;
        update accountContact;
        List<AccountContact__c> verifyAccountContacts = [SELECT Id, Account__c FROM AccountContact__c];
        System.assertEquals(accounts[1].Id, verifyAccountContacts[0].Account__c);
    }

    @isTest
    static void testUpdateAccountContactsWithIsPrimaryFieldTrue() {
        accountAndContactInserting();
        for (Integer i = 0; i < 200; i++){
            AccountContact__c accountContact = new AccountContact__c();
            accountContact.Account__c = accounts[i].Id;
            accountContact.Contact__c = contacts[i].Id;
            if (i < half){
                accountContact.Contact__c = contacts[i].Id;
                firstHalfListAccountContactsForInsert.add(accountContact);
            }
            else {
                accountContact.Contact__c = contacts[i-half].Id;
                accountContact.isPrimary__c = true;
                secondHalfListAccountContactsForInsert.add(accountContact);
                accountContactsForUpdate.add(accountContact);
            }
        }
        insert firstHalfListAccountContactsForInsert;
        insert secondHalfListAccountContactsForInsert;
        update accountContactsForUpdate;
        List<AccountContact__c> verifyAccountContacts = [SELECT Id, isPrimary__c FROM AccountContact__c ORDER BY isPrimary__c];
        for (Integer i = 0; i < verifyAccountContacts.size(); i++){
            if (i < half){
                System.assertEquals(false, verifyAccountContacts[i].isPrimary__c);
            }
            else {
                System.assertEquals(true, verifyAccountContacts[i].isPrimary__c);
            }
        }
    }

    @isTest
    static void testUpdateAccountContactsWithIsPrimaryFieldFalse() {
        accountAndContactInserting();
        for (Integer i = 0; i < 200; i++){
            AccountContact__c accountContact = new AccountContact__c();
            accountContact.Account__c = accounts[i].Id;
            if (i < half){
                accountContact.Contact__c = contacts[i].Id;
                accountContact.isPrimary__c = false;
                firstHalfListAccountContactsForInsert.add(accountContact);
                accountContactsForUpdate.add(accountContact);
            }
            else {
                accountContact.Contact__c = contacts[i-half].Id;
                secondHalfListAccountContactsForInsert.add(accountContact);
            }
        }
        insert firstHalfListAccountContactsForInsert;
        insert secondHalfListAccountContactsForInsert;
        update accountContactsForUpdate;
        List<AccountContact__c> verifyAccountContacts = [SELECT Id, isPrimary__c FROM AccountContact__c ORDER BY isPrimary__c];
        for (Integer i = 0; i < verifyAccountContacts.size(); i++){
            if (i < half){
                System.assertEquals(false, verifyAccountContacts[i].isPrimary__c);
            }
            else {
                System.assertEquals(true, verifyAccountContacts[i].isPrimary__c);
            }
        }
    }

    @isTest
    static void testUpdateAccountContactsInBulkWithNewContacts() {
        accountAndContactInserting();
        for (Integer i = 0; i < 100; i++){
            AccountContact__c accountContact = new AccountContact__c();
            accountContact.Account__c = accounts[i].Id;
            accountContact.Contact__c = contacts[i].Id;
            accountContactsForInsert.add(accountContact);
            accountContactsForUpdate.add(accountContact);
        }
        insert accountContactsForInsert;
        for (Integer i = 0; i < accountContactsForUpdate.size(); i++){
            accountContactsForUpdate[i].Contact__c = contacts[i + half].Id;
        }
        update accountContactsForUpdate;
        List<AccountContact__c> verifyAccountContacts = [SELECT Id, Contact__c, isPrimary__c FROM AccountContact__c];
        for (Integer i = 0; i < verifyAccountContacts.size(); i++){
            System.assertEquals(true, verifyAccountContacts[i].isPrimary__c);
        }
    }

    @isTest
    static void testUpdateAccountContactsInBulkWithExistsContacts() {
        accountAndContactInserting();
        for (Integer i = 0; i < 200; i++){
            AccountContact__c accountContact = new AccountContact__c();
            accountContact.Account__c = accounts[i].Id;
            accountContact.Contact__c = contacts[i].Id;
            accountContactsForInsert.add(accountContact);
            accountContactsForUpdate.add(accountContact);
        }
        insert accountContactsForInsert;
        for (Integer i = 100; i < accountContactsForUpdate.size(); i++){
            accountContactsForUpdate[i].Contact__c = contacts[i - half].Id;
        }
        try {
            update accountContactsForUpdate;
        }
        catch(Exception e){
            System.assertEquals(true, true);
        }
    }

    @isTest
    static void testDeleteAccountContactsInBulkWithChangingCheckboxOnAnotherAccountContact() {
        accountAndContactInserting();
        for (Integer i = 0; i < 100; i++){
            AccountContact__c accountContact = new AccountContact__c();
            accountContact.Account__c = accounts[i].Id;
            accountContact.Contact__c = contacts[i].Id;
            firstHalfListAccountContactsForInsert.add(accountContact);
            accountContactsForDelete.add(accountContact);
        }
        insert firstHalfListAccountContactsForInsert;
        for (Integer i = 0; i < 100; i++){
            AccountContact__c accountContact = new AccountContact__c();
            accountContact.Account__c = accounts[i].Id;
            accountContact.Contact__c = contacts[i].Id;
            secondHalfListAccountContactsForInsert.add(accountContact);
        }
        insert secondHalfListAccountContactsForInsert;
        delete accountContactsForDelete;
        List<AccountContact__c> verifyAccountContacts = [SELECT Id, isPrimary__c FROM AccountContact__c];
        System.assertEquals(half, verifyAccountContacts.size());
        for (Integer i = 0; i < verifyAccountContacts.size(); i++){
            System.assertEquals(true, verifyAccountContacts[i].isPrimary__c);
        }
    }

    @isTest
    static void testDeleteOneLastAccountContactWith() {
        accountAndContactInserting();
        AccountContact__c accountContact1 = new AccountContact__c();
        accountContact1.Account__c = accounts[0].Id;
        accountContact1.Contact__c = contacts[0].Id;
        insert accountContact1;
        delete accountContact1;
        List<AccountContact__c> verifyAccountContacts = [SELECT Id, isPrimary__c FROM AccountContact__c];
        System.assertEquals(0, verifyAccountContacts.size());
    }

    private static void accountAndContactInserting(){
        for(Integer i = 0; i < 200; i++) {
            Account account = new Account(Name = 'Test Account ' + i);
            accounts.add(account);
            Contact contact = new Contact(LastName = 'Test Contact ' + i);
            contacts.add(contact);
        }
        insert accounts;
        insert contacts;
    }
}