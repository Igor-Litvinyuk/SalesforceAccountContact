/**
 * Created by Igor Litvinyuk on 10.09.2018.
 */

public with sharing class AccountHandler{
    AccountContactService service = new AccountContactService();

    public void onBeforeDelete(List<Account> oldAccounts){
        service.deleteAccountContactViaAccount(oldAccounts);
    }
}