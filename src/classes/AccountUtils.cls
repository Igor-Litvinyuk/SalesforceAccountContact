/**
 * Created by Igor Litvinyuk on 04.09.2018.
 */

public with sharing class AccountUtils {
    public static List<Account>  accountsByState(String state){
        List<Account> accounts = [SELECT Id, Name
                                  FROM Account
                                  WHERE BillingState = :state];
        return accounts;
    }
}