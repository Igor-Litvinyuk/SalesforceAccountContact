/**
 * Created by Igor Litvinyuk on 04.09.2018.
 */

@isTest
private class AccountTriggerTest {
    @isTest static void TestCreateNewAccountInBulk() {
        List<Account> accounts = new List<Account>();
        for(Integer i = 0; i < 200; i++) {
            Account account = new Account(Name = 'Test Account ' + i, BillingState = 'CA');
            accounts.add(account);
        }
        Test.startTest();
        insert accounts;
        Test.stopTest();
        List<Account> verifyAccounts = [SELECT Id, ShippingState FROM Account];
        System.assertEquals(200, verifyAccounts.size());
        for (Account account : verifyAccounts){
            System.assertEquals('CA', account.ShippingState);
        }
    }
}