/**
 * Created by Igor Litvinyuk on 04.09.2018.
 */

public with sharing class AccountTriggerHandler {
    public static void CreateAccounts(List<Account> newAccounts) {
        for (Account account : newAccounts) {
            if (account.ShippingState != account.BillingState){
                account.ShippingState = account.BillingState;
            }
        }
    }
}