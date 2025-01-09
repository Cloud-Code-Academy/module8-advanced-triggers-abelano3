public with sharing class OpportunityTriggerHandler {
    public static void setType(List<Opportunity> opportunities) {
         // Set default Type for new Opportunities
        for (Opportunity opp : opportunities) {
            if (opp.Type == null){
                opp.Type = 'New Customer';
            }
        }      
    }

    public static void validateCloseOpportunity(List<Opportunity> opportunities) {
        // Prevent deletion of closed Opportunities
        for (Opportunity oldOpp : opportunities){
            if (oldOpp.IsClosed){
                oldOpp.addError('Cannot delete closed opportunity');
            }
        }
    }

    public static void insertTask(List<Opportunity> opportunities) {
        // Create a new Task for newly inserted Opportunities
        List<Task> tasks = new List<Task>();
        for (Opportunity opp : opportunities){
            Task tsk = new Task();
            tsk.Subject = 'Call Primary Contact';
            tsk.WhatId = opp.Id;
            tsk.WhoId = opp.Primary_Contact__c;
            tsk.OwnerId = opp.OwnerId;
            tsk.ActivityDate = Date.today().addDays(3);
            tasks.add(tsk);
        }
        insert tasks;
    }

    public static void updateDescriptionFromStage(List<Opportunity> opportunities, Map<Id, Opportunity> oldOppMap) {
        // Append Stage changes in Opportunity Description
        for (Opportunity opp : opportunities){
            Opportunity oldOpp = oldOppMap.get(opp.Id);
                if (opp.StageName != oldOpp.StageName){
                    opp.Description += '\n Stage Change:' + opp.StageName + ':' + DateTime.now().format();
                } 
            }
        }

    /*
    notifyOwnersOpportunityDeleted:
    - Sends an email notification to the owner of the Opportunity when it gets deleted.
    - Uses Salesforce's Messaging.SingleEmailMessage to send the email.
    */
    public static void notifyOwnersOpportunityDeleted(List<Opportunity> opps) {
        List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
        // Query the User records and create userMap to store Key/Value = User Id/User record.
        Map<Id, User> userMap = new Map<Id, User>([SELECT Id, Email FROM User]);

        for (Opportunity opp : opps){
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();

            // Get the User record of the Opportunity owner by looking up the OwnerId in userMap.
            User opportunityOwner = userMap.get(opp.OwnerId);

            String[] toAddresses = new List<String>{userMap.get(opp.OwnerId).Email};
            mail.setToAddresses(toAddresses);
            mail.setSubject('Opportunity Deleted : ' + opp.Name);
            mail.setPlainTextBody('Your Opportunity: ' + opp.Name +' has been deleted.');
            mails.add(mail);
        }        
        
        try {
            Messaging.sendEmail(mails);
        } catch (Exception e){
            System.debug('Exception: ' + e.getMessage());
        }
    }

    /*
    assignPrimaryContact:
    - Assigns a primary contact with the title of 'VP Sales' to undeleted Opportunities.
    - Only updates the Opportunities that don't already have a primary contact.
    */
    public static void assignPrimaryContact(Map<Id,Opportunity> oppNewMap) { 
        // Create a Set of related Account Ids.
        Set<Id> oppAccountIds = new Set<Id>();
        for (Opportunity opp : oppNewMap.values()) {
            oppAccountIds.add(opp.AccountId);
        }
        // Create accMap to query related accounts and contacts where Title = 'VP Sales'. 
        Map<Id, Account> accMap = new Map<Id, Account>([SELECT Id, (SELECT Id FROM Contacts WHERE Title = 'VP Sales') FROM Account WHERE Id IN: oppAccountIds]);

        Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>();
        for (Opportunity opp : oppNewMap.values()){            
            if (opp.Primary_Contact__c == null && !accMap.get(opp.AccountId).Contacts.isEmpty()){
                Opportunity oppToUpdate = new Opportunity(Id = opp.Id); 
                oppToUpdate.Primary_Contact__c = accMap.get(opp.AccountId).Contacts[0].Id;
                oppMap.put(opp.Id, oppToUpdate);
            }
        }
        update oppMap.values();
    }

    public static void amountValidation(List<Opportunity> opportunities) {
        for (Opportunity opp : opportunities) {
            if (opp.Amount < 5000) {
                opp.addError('Opportunity amount must be greater than 5000');
            }
        }
    }

    public static void deleteCloseWonOpportunity(List<Opportunity> opportunities) {
         // Obtain Set of account ids from the opportunties that are Closed Won.
         Set<Id> accountIds = new Set<Id>();
        for (Opportunity oldOpp : opportunities) {
            if (oldOpp.StageName == 'Closed Won') {
                accountIds.add(oldOpp.AccountId);
            }
        }

        // Query the Accounts using set of accountIds above to put into Map where Key-Account Id and Value-Account Industry.
        Map<Id, Account> accountMap = new Map<Id,Account>([SELECT Id, Industry FROM Account WHERE Id IN :accountIds]);

        // Loop through the 'old' opportunities and throw error if Opportunity StageName is 'Closed Won' and Account Industry is 'Banking'.
        for (Opportunity oldOpp : opportunities) {
            if (oldOpp.StageName == 'Closed Won') {
                Account relatedAccount = accountMap.get(oldOpp.AccountId);
                if (relatedAccount.Industry == 'Banking') {
                    oldOpp.addError('Cannot delete closed opportunity for a banking account that is won');
                }
            }
        }
    }

    public static void setPrimaryContact(List<Opportunity> opportunities) {
        // Obtain set of account ids from the Opportunity records.
        Set<Id> accountIds = new Set<Id>();
        for (Opportunity opp : opportunities) {
            if (opp.Primary_Contact__c == null && opp.AccountId != null) {
                accountIds.add(opp.AccountId);
            }
        }

        // Query the Contacts with Title = 'CEO' and put into a Map.  Loop through Opportunities and set Primary_Contact__c to the contact with Title = 'CEO'.
        Map<Id, Contact> contactMap = new Map<Id,Contact>();
        for (Contact con : [SELECT Id, AccountId FROM Contact WHERE Title = 'CEO' AND AccountId IN :accountIds]) {
            contactMap.put(con.AccountId, con);

            // Loop through the opportunities and set Primary_Contact__c based on the AccountId in the contactMap.
            for (Opportunity opp : opportunities) {
                if (contactMap.containskey(opp.AccountId)) {
                    opp.Primary_Contact__c = contactMap.get(opp.AccountId).Id;
                }
            }
        }
    }
}