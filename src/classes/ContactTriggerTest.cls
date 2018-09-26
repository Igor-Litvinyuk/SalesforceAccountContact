/**
 * Created by Igor Litvinyuk on 10.09.2018.
 */

@isTest
private class ContactTriggerTest{

    private static List<AccountContact__c> accountContactsForInsert = new List<AccountContact__c>();
    private static List<Account> accounts = new List<Account>();
    private static List<Contact> contacts = new List<Contact>();

    @isTest
    static void TestDeleteContact(){
        for (Integer i = 0; i < 200; i++) {
            Account account = new Account(Name = 'Test Account ' + i);
            accounts.add(account);
            Contact contact = new Contact(LastName = 'Test Contact ' + i);
            contacts.add(contact);
        }
        insert accounts;
        insert contacts;

        for (Integer i = 0; i < 200; i++){
            AccountContact__c accountContact = new AccountContact__c();
            accountContact.Account__c = accounts[i].Id;
            accountContact.Contact__c = contacts[i].Id;
            accountContactsForInsert.add(accountContact);
        }
        insert accountContactsForInsert;
        delete contacts;
        List<AccountContact__c> verifyAccountContacts = [SELECT Id FROM AccountContact__c];
        System.assertEquals(0, verifyAccountContacts.size());
        List<Contact> verifyContacts = [SELECT Id FROM Contact];
        System.assertEquals(0, verifyContacts.size());
    }
}