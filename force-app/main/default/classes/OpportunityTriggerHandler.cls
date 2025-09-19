public with sharing class OpportunityTriggerHandler {

 public void run() {
        switch on Trigger.operationType {
            when BEFORE_INSERT {
                OpportunityHelper.setType((List<Opportunity>) Trigger.new);
            }
            when AFTER_INSERT {
                OpportunityHelper.insertTask((List<Opportunity>) Trigger.new);
            }
            when BEFORE_UPDATE {
                OpportunityHelper.amountValidation((List<Opportunity>) Trigger.new);
                OpportunityHelper.setPrimaryContact((List<Opportunity>) Trigger.new);
                OpportunityHelper.updateDescriptionFromStage(
                    (List<Opportunity>) Trigger.new,
                    (Map<Id, Opportunity>) Trigger.oldMap
                );
            }
/*            when AFTER_UPDATE {
                
            }  
*/
            when BEFORE_DELETE {
                OpportunityHelper.validateCloseOpportunity((List<Opportunity>) Trigger.old);
                OpportunityHelper.deleteCloseWonOpportunity((List<Opportunity>) Trigger.old);
            }
            when AFTER_DELETE {
                OpportunityHelper.notifyOwnersOpportunityDeleted((List<Opportunity>) Trigger.old);
            }
            when AFTER_UNDELETE {
                OpportunityHelper.assignPrimaryContact((Map<Id, Opportunity>) Trigger.newMap);
            }
        }
    }

}