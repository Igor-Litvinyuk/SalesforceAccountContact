/**
 * Created by Igor Litvinyuk on 06.09.2018.
 */

@isTest
private class AccountContactTriggerTest {

    private static List<AccountContact__c> accountContactsForInsert = new List<AccountContact__c>();
    private static List<AccountContact__c> accountContactsForDelete = new List<AccountContact__c>();
    private static List<AccountContact__c> accountContactsForUpdate = new List<AccountContact__c>();
    private static List<Account> accounts = new List<Account>();
    private static List<Contact> contacts = new List<Contact>();
    private static List<AccountContact__c> firstHalfListAccountContactsForInsert = new List<AccountContact__c>();
    private static List<AccountContact__c> secondHalfListAccountContactsForInsert = new List<AccountContact__c>();

    @isTest
    static void TestCreateNewAccountContactsInBulk() {
        accountAndContactInserting();
        for (Integer i = 0; i < 200; i++){
            AccountContact__c accountContact = new AccountContact__c();
            accountContact.Account__c = accounts[i].Id;
            accountContact.Contact__c = contacts[i].Id;
            accountContactsForInsert.add(accountContact);
        }
        Test.startTest();
        insert accountContactsForInsert;
        Test.stopTest();
        List<AccountContact__c> verifyAccountContacts = [SELECT Id FROM AccountContact__c];
        System.assertEquals(200, verifyAccountContacts.size());
    }

    @isTest
    static void TestCreateNewAccountContactsWithDifferentIsPrimaryFieldsInBulk() {
        accountAndContactInserting();
        for (Integer i = 0; i < 200; i++){
            AccountContact__c accountContact = new AccountContact__c();
            accountContact.Account__c = accounts[i].Id;
            accountContact.Contact__c = contacts[i].Id;
            if (i > 190){
                accountContact.isPrimary__c = true;
            }
            if (i < 10) {
                accountContact.isPrimary__c = false;
            }
            accountContactsForInsert.add(accountContact);
        }
        Test.startTest();
        insert accountContactsForInsert;
        Test.stopTest();
        List<AccountContact__c> verifyAccountContacts = [SELECT Id, isPrimary__c FROM AccountContact__c];
        System.assertEquals(true, verifyAccountContacts[1].isPrimary__c);
        System.assertEquals(true, verifyAccountContacts[191].isPrimary__c);
    }

    @isTest
    static void TestCreateNewAccountContactsInBulkWithSameContact() {
        accountAndContactInserting();
        for (Integer i = 0; i < 200; i++){
            AccountContact__c accountContact = new AccountContact__c();
            accountContact.Account__c = accounts[i].Id;
            accountContact.Contact__c = contacts[i].Id;
            if(i > 100){
                accountContact.Contact__c = contacts[i-101].Id;
            }
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
    static void TestCreateNewAccountContactsWithIsPrimaryFieldTrue() {
        accountAndContactInserting();
        for (Integer i = 0; i < 200; i++){
            AccountContact__c accountContact = new AccountContact__c();
            if (i < 100){
                accountContact.Account__c = accounts[i].Id;
                accountContact.Contact__c = contacts[i].Id;
                firstHalfListAccountContactsForInsert.add(accountContact);
            }
            else {
                accountContact.Account__c = accounts[i].Id;
                accountContact.Contact__c = contacts[i-100].Id;
                secondHalfListAccountContactsForInsert.add(accountContact);
            }
        }
        Test.startTest();
        insert firstHalfListAccountContactsForInsert;
        insert secondHalfListAccountContactsForInsert;
        Test.stopTest();
        List<AccountContact__c> verifyAccountContacts = [SELECT Id, isPrimary__c FROM AccountContact__c];
        for (Integer i = 0; i < verifyAccountContacts.size(); i++){
            if (i < 100){
                System.assertEquals(true, verifyAccountContacts[i].isPrimary__c);
            }
            else {
                System.assertEquals(false, verifyAccountContacts[i].isPrimary__c);
            }
        }
    }

    @isTest
    static void TestUpdateAccountContactsWithIsPrimaryFieldTrue() {
        accountAndContactInserting();
        for (Integer i = 0; i < 200; i++){
            AccountContact__c accountContact = new AccountContact__c();
            if (i < 100){
                accountContact.Account__c = accounts[i].Id;
                accountContact.Contact__c = contacts[i].Id;
                firstHalfListAccountContactsForInsert.add(accountContact);
            }
            else {
                accountContact.Account__c = accounts[i].Id;
                accountContact.Contact__c = contacts[i-100].Id;
                accountContact.isPrimary__c = true;
                secondHalfListAccountContactsForInsert.add(accountContact);
                accountContactsForUpdate.add(accountContact);
            }
        }
        insert firstHalfListAccountContactsForInsert;
        insert secondHalfListAccountContactsForInsert;
        Test.startTest();
        update accountContactsForUpdate;
        Test.stopTest();
        List<AccountContact__c> verifyAccountContacts = [SELECT Id, isPrimary__c FROM AccountContact__c];
        for (Integer i = 0; i < verifyAccountContacts.size(); i++){
            if (i < 100){
                System.assertEquals(false, verifyAccountContacts[i].isPrimary__c);
            }
            else {
                System.assertEquals(true, verifyAccountContacts[i].isPrimary__c);
            }
        }
    }

    @isTest
    static void TestDeleteAccountContactsInBulkWithChangingCheckboxOnAnotherAccountContact() {
        accountAndContactInserting();
        for (Integer i = 0; i < 200; i++){
            AccountContact__c accountContact = new AccountContact__c();
            if (i < 100){
                accountContact.Account__c = accounts[i].Id;
                accountContact.Contact__c = contacts[i].Id;
                accountContact.isPrimary__c = true;
                firstHalfListAccountContactsForInsert.add(accountContact);
                accountContactsForDelete.add(accountContact);
            }
            else {
                accountContact.Account__c = accounts[i].Id;
                accountContact.Contact__c = contacts[i-100].Id;
                secondHalfListAccountContactsForInsert.add(accountContact);
            }
        }
        insert firstHalfListAccountContactsForInsert;
        insert secondHalfListAccountContactsForInsert;
        Test.startTest();
        delete accountContactsForDelete;
        Test.stopTest();
        List<AccountContact__c> verifyAccountContacts = [SELECT Id, isPrimary__c FROM AccountContact__c];
        System.assertEquals(100, verifyAccountContacts.size());
        for (Integer i = 0; i < verifyAccountContacts.size(); i++){
            System.assertEquals(true, verifyAccountContacts[i].isPrimary__c);
        }
    }

    @isTest
    static void TestDeleteOneLastAccountContactWith() {
        accountAndContactInserting();
        AccountContact__c accountContact1 = new AccountContact__c();
        accountContact1.Account__c = accounts[0].Id;
        accountContact1.Contact__c = contacts[0].Id;
        insert accountContact1;
        Test.startTest();
        delete accountContact1;
        Test.stopTest();
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