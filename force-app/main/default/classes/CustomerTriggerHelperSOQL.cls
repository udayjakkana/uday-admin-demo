public class CustomerTriggerHelperSOQL{

    public static void isAfterUpdateCall(List<apex_customer__c> customerList, Map<id, apex_customer__c> newMapCustomer, Map<id, apex_customer__c> oldMapCustomer) {
        createInvoiceRecords(customerList, oldMapCustomer);
        updateInvoiceDesc(customerList, newMapCustomer);
    }
    
    public static void createInvoiceRecords(List<apex_customer__c> customerList, Map<id, apex_customer__c> oldMapCustomer) {
        List<Apex_invoice__c> invoiceList = new List<apex_invoice__c>();
        for(apex_customer__c objCustomer:customerList) {
            if(objCustomer.apex_customer_status__c=='Active' && oldMapCustomer.get(objCustomer.id).apex_customer_status__c=='Inactive'){
                apex_invoice__c objinvoice = new apex_invoice__c();
                objInvoice.apex_status__c = 'Pending';
                objInvoice.apex_customer__c = objCustomer.id;
                invoiceList.add(objInvoice);
            }
        }
        insert invoiceList;
    }
    
    public static void updateInvoiceDesc(List<Apex_Customer__c> customerList, Map<id, apex_customer__c> newMapCustomer ) {
        List<apex_customer__c> customerListWithInvoices=[select id, name, (select id, name, apex_description__c from Invoices__r) from apex_customer__c where id in:newMapCustomer.keySet()];
        
        List<apex_invoice__c> invoicesToUpdate = new List<apex_invoice__c>();
        List<apex_invoice__c> invList = customerListWithInvoices[0].Invoices__r;
        
        for(apex_invoice__c objInv:invList){
            objInv.apex_description__c='OK TO PAY';
            invoicesToUpdate.add(objInv);
        }
        
        update invoicesToUpdate;
    }

}