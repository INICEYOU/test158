import UIKit
import Contacts

func createContact() {
    let newContact = CNMutableContact()
    
    newContact.givenName = "77"
}

let contact1 = CNMutableContact()
contact1.givenName = "77"
let contact2 = CNMutableContact()
contact2.givenName = "77"

var set0: Set<CNContact> = [contact1]
var set1: Set<CNContact> = [contact1 , contact2]
var set2: Set<CNContact> = [contact2]
var set3 = set2.contains(contact1)
var set4 = set1.subtracting(set2)
var set5: Set<CNContact> = set0.union(set2)

if contact1 == contact2 {
    print("==")
}

if contact1.isEqual(contact2)  {
    print("isEqual")
}

let contact0: Any? = CNContact()
if let contact00 = contact0 as? CNMutableContact {
    print("5474577")
}

extension CNMutableContact
{
    // MARK: - Hashable
    
    // Одинаковым считаются контакты с одинаковым значением полей: Имя, Номера телефонов, Email адреса, Адрес
    
    private func isContactEqual (to contact: CNContact) -> Bool
    {
        if givenName == contact.givenName
        {
            return true
        }
        
        return false
    }
    
    open override func isEqual(_ object: Any?) -> Bool
    {
        
        
        if let mutableContact = object as? CNMutableContact
        {
            return isContactEqual(to: mutableContact)
        }
        
        if let contact = object as? CNContact
        {
            return isContactEqual(to: contact)
        }
        
        return false
    }
    
    open override var hashValue: Int
    {
        return givenName.hashValue
//            ^ hashValuePhoneNumbers ^ hashValueEmailAddresses ^ hashValuePostalAddresses
    }
    
//    var hashValuePhoneNumbers: Int
//    {
//        var hashValue: Int = 77
//        
//        for phoneNumber in phoneNumbers
//        {
//            hashValue ^= phoneNumber.value.stringValue.hashValue
//        }
//        
//        return hashValue
//    }
//    
//    var hashValueEmailAddresses: Int
//    {
//        var hashValue: Int = 77
//        
//        for email in emailAddresses
//        {
//            hashValue ^= String(email.value).hashValue
//        }
//        
//        return hashValue
//    }
//    
//    var hashValuePostalAddresses: Int
//    {
//        var hashValue: Int = 77
//        
//        for address in postalAddresses
//        {
//            hashValue ^= CNPostalAddressFormatter.string(from: address.value, style: .mailingAddress ).hashValue
//        }
//        
//        return hashValue
//    }
    
    static func == (lhs: CNMutableContact ,rhs: CNMutableContact ) -> Bool
    {
        return //true
            lhs.givenName          == rhs.givenName
//            && lhs.phoneNumbersSet    == rhs.phoneNumbersSet
//            && lhs.emailAddressesSet  == rhs.emailAddressesSet
//            && lhs.postalAddressesSet == rhs.postalAddressesSet
    }
    
//    var phoneNumbersSet: Set<String>
//    {
//        var set: Set<String> = []
//        
//        for phoneNumber in phoneNumbers
//        {
//            set.insert(phoneNumber.value.stringValue)
//        }
//        
//        return set
//    }
//    
//    var emailAddressesSet: Set<String>
//    {
//        var set: Set<String> = []
//        
//        for email in emailAddresses
//        {
//            set.insert(String(email.value))
//        }
//        
//        return set
//    }
//    
//    var postalAddressesSet: Set<String>
//    {
//        var set: Set<String> = []
//        
//        for address in postalAddresses
//        {
//            set.insert(CNPostalAddressFormatter.string(from: address.value, style: .mailingAddress ))
//        }
//        
//        return set
//    }
}
