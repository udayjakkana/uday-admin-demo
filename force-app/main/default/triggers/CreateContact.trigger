trigger CreateContact on Account (after insert) {
    List<Contact> contacts = new List<Contact>();
    for(Account account:Trigger.new) {
        Contact contact = new Contact();
        contact.lastName=account.Name;
        contacts.add(contact);
    }
    insert contacts;
}