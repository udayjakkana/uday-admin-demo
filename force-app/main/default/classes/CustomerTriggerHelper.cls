public class CustomerTriggerHelper {

    public static void createInvoiceRecord(List<Apex_Customer__c> customers, Map<id, Apex_customer__c> oldCustomersMap) {
    
        List<apex_invoice__c> invoiceList = new List<apex_invoice__c>();
        
        for(Apex_Customer__c customer: customers) {
            if(customer.Apex_Customer_Status__c == 'Active' && oldCustomersMap.get(customer.id).Apex_Customer_Status__c == 'Inactive') {
                Apex_Invoice__c invoice = new Apex_Invoice__c();
                invoice.apex_status__c = 'Pending';
                invoice.apex_customer__c = customer.id;
                invoiceList.add(invoice);
            }
        }
        insert invoiceList;
    
    }
    
}