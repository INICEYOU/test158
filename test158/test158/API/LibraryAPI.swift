//
//  LibraryAPI.swift
//  test158
//
//  Created by Nice on 02/12/2016.
//  Copyright © 2016 Andrey Kozhurin. All rights reserved.
//

import UIKit
import Contacts

class LibraryAPI: NSObject
{
    
    class var sharedInstance: LibraryAPI {
        struct Singleton {
            static let instance = LibraryAPI()
        }
        return Singleton.instance
    }
    
    private let persistencyManager: PersistencyManager
    
    override init() {
        persistencyManager = PersistencyManager()
        
        super.init()
    }
    
    func getContactsFromDevice () -> Set<CNContact>
    {
        return persistencyManager.getContactsFromDevice()
    }
    
    func getContactsFromFile () -> Set<CNContact>
    {
        return persistencyManager.getContactsFromFile()
    }
    
    var createVCardContacts : Data?
    {
        return persistencyManager.createVCardContacts
    }
    
    func extractVCardContacts (from data: Data?) -> Set<CNContact>
    {
        return persistencyManager.extractVCardContacts(from : data)
    }
}
