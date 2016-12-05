//
//  CNContact.swift
//  test158
//
//  Created by Nice on 01/12/2016.
//  Copyright © 2016 Andrey Kozhurin. All rights reserved.
//

import UIKit
import Contacts

extension CNContact
{
    // Одинаковым считаются контакты с одинаковым значением полей: Имя, Номера телефонов, Email адреса, Адрес
    
    // Для простоты решения это лишь расширение класса CNContact. По хорошему лучше создать подкласс от CNContact и добавить туда методы
    
    // MARK: - Hashable
    
    open override var hashValue: Int
    {
        return givenName.hashValue ^ hashValuePhoneNumbers ^ hashValueEmailAddresses ^ hashValuePostalAddresses
    }
    
    var hashValuePhoneNumbers: Int
    {
        var hashValue: Int = 77
        
        for phoneNumber in phoneNumbers
        {
            hashValue ^= phoneNumber.value.stringValue.hashValue
        }
        
        return hashValue
    }
    
    var hashValueEmailAddresses: Int
    {
        var hashValue: Int = 77
        
        for email in emailAddresses
        {
            hashValue ^= String(email.value).hashValue
        }
        
        return hashValue
    }
    
    var hashValuePostalAddresses: Int
    {
        var hashValue: Int = 77
        
        for address in postalAddresses
        {
            hashValue ^= CNPostalAddressFormatter.string(from: address.value, style: .mailingAddress ).hashValue
        }
        
        return hashValue
    }
    
    // MARK: - Сравнение
    
    open override func isEqual(_ object: Any?) -> Bool
    {
        if let contact = object as? CNContact
        {
            return givenName          == contact.givenName
                && phoneNumbersSet    == contact.phoneNumbersSet
                && emailAddressesSet  == contact.emailAddressesSet
                && postalAddressesSet == contact.postalAddressesSet
        }
        
        return false
    }
    
    static func == (lhs: CNContact ,rhs: CNContact ) -> Bool
    {
        return lhs.givenName          == rhs.givenName
            && lhs.phoneNumbersSet    == rhs.phoneNumbersSet
            && lhs.emailAddressesSet  == rhs.emailAddressesSet
            && lhs.postalAddressesSet == rhs.postalAddressesSet
    }
    
    var phoneNumbersSet: Set<String>
    {
        var set: Set<String> = []
        
        for phoneNumber in phoneNumbers
        {
            set.insert(phoneNumber.value.stringValue)
        }
        
        return set
    }
    
    var emailAddressesSet: Set<String>
    {
        var set: Set<String> = []
        
        for email in emailAddresses
        {
            set.insert(String(email.value))
        }
        
        return set
    }

    var postalAddressesSet: Set<String>
    {
        var set: Set<String> = []
        
        for address in postalAddresses
        {
            set.insert(CNPostalAddressFormatter.string(from: address.value, style: .mailingAddress ))
        }
        
        return set
    }
}
