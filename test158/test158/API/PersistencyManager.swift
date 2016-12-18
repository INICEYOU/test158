//
//  PersistencyManager.swift
//  test158
//
//  Created by Nice on 02/12/2016.
//  Copyright © 2016 Andrey Kozhurin. All rights reserved.
//

import UIKit
import Contacts
import CoreData

class PersistencyManager: NSObject
{
    fileprivate func deleteAllObjects(context: NSManagedObjectContext) {
        
        let entitesByName = context.persistentStoreCoordinator!.managedObjectModel.entitiesByName
        
        for (name, _) in entitesByName {
            
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: name)
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            
            do { try context.execute(deleteRequest) }
            catch { print("handle the error") }
        }
        
        try? context.save()
        
    }
    
    func getContactsFromDevice () -> Set<CNContact>
    {
        var result: Set<CNContact> = []
        let contactStore = CNContactStore()
        
        do {
            try contactStore.enumerateContacts(with: CNContactFetchRequest(keysToFetch: Constants.Contact.keysToFetch as! [CNKeyDescriptor] ))
            {
                (contact, cursor) -> Void in
                
                // добавить контакты из телефона
                result.insert(contact)
            }
        }
        catch{
            print("the error of fetching contacts from device")
            return []
        }
        return result
    }
    
    func getContactsFromFile () -> Set<CNContact>
    {
        var result = Set<CNContact>()
        
        if let path = Bundle.main.path(forResource:"example", ofType: "vcf"){
            let fm = FileManager()
            let exists = fm.fileExists(atPath: path)
            if exists
            {
                let c = fm.contents(atPath: path)
                let contactsFromFile = try! CNContactVCardSerialization.contacts(with: c!)
                result = Set(contactsFromFile)
            }
        }
        
        return result
    }
    
    // Сериализованы 4 поля из всех содержащихся в vCard полей
    
    var createVCardContacts : Data?
    {
        var result: [Any] = []
        
        // Количество генерируемых контактов
        let amount = 10000 // > 2 !
        
        // Тестовый контакт совпадающий со стандартным на iphone
        var vcardTest: [Any] = ["vcard"]
        var testArr = [Any]()
        testArr.append(["n","","text",["","David","",""]])
        testArr.append(["tel","","text","555-610-6679"])
        testArr.append(["adr","","text",["","","1747 Steuart Street","Tiburon","CA","94920","USA"]])
        vcardTest.append(testArr)
        result.append(vcardTest)
        
        //if amount < 2 { return nil }
        
        // Создание N количества разных контактов
        for i in 2...amount
        {
            var vcard: [Any] = ["vcard"]
            var arr = [Any]()
            arr.append(["n","","text",["","Name #\(i)","",""]])
            arr.append(["tel","","text","\(i * 125)32523"])
            arr.append(["email","","text","\(i * 325)@gmail.com"])
            arr.append(["adr","","text",["","","1747 Steuart Street","Tiburon","CA","\(i * 10)","USA"]])
            vcard.append(arr)
            result.append(vcard)
        }
        
        // Создание json data файла
        if JSONSerialization.isValidJSONObject(result) {
            return try! JSONSerialization.data(withJSONObject: result, options: .prettyPrinted)
        } else {
            print( "JSONObject  is Invalid" )
        }
        return nil
    }
    
    func extractVCardContacts (from data: Data?) -> Set<CNContact>
    {
        var result = Set<CNContact>()
        
        do {
            if let data = data,
                let json = try JSONSerialization.jsonObject(with: data, options: []) as? [Any]
            {
                // [ ["vcard" , array ] ]
                for array in json
                {
                    if let vcard = array as? [Any]
                    {
                        // ["vcard" , array ]
                        
                        if vcard.count != 2 { continue }
                        
                        guard let vcardLabel = vcard[0] as? String , let vcardValue = vcard[1] as? [[Any]]
                            else {
                                continue
                        }
                        
                        if vcardLabel != "vcard" { continue }
                        
                        let contact = CNMutableContact()
                        
                        // array = [ ["tel", ...] , ["email", ...]  ]
                        for value in vcardValue
                        {
                            
                            if let rowName = value[0] as? String {
                                
                                switch rowName
                                {
                                case "n":
                                    // ["n","","text",["","David","",""]]
                                    
                                    if let nameArray = value[3] as? [String] {
                                        contact.givenName = nameArray[1]
                                    }
                                case "tel":
                                    // ["tel","","text","555-610-6679"]
                                    
                                    if let phoneNumber = value[3] as? String
                                    {
                                        let label = CNLabeledValue(label: CNLabelWork,
                                                                   value:CNPhoneNumber(stringValue: phoneNumber))
                                        
                                        if contact.phoneNumbers.isEmpty
                                        {
                                            contact.phoneNumbers = [label]
                                        } else {
                                            contact.phoneNumbers.append(label)
                                        }
                                    }
                                    
                                case "email":
                                    // ["email","","text","fwehf@gmail.com"]
                                    
                                    if let email = value[3] as? NSString
                                    {
                                        let labeledValue = CNLabeledValue(label: CNLabelOther,
                                                                          value: email)
                                        
                                        if contact.emailAddresses.isEmpty
                                        {
                                            contact.emailAddresses = [labeledValue]
                                        } else {
                                            contact.emailAddresses.append(labeledValue)
                                        }
                                    }
                                    
                                case "adr":
                                    // ["adr","","text",["","","1747 Steuart Street","Tiburon","CA","94920","USA"]]
                                    
                                    if let fullAddress = value[3] as? [String]
                                    {
                                        
                                        
                                        let homeAddress = CNMutablePostalAddress()
                                        
                                        for (index, address) in fullAddress.enumerated()
                                        {
                                            if address == "" { continue }
                                            
                                            switch index {
                                            case 2:
                                                homeAddress.street = address
                                            case 3:
                                                homeAddress.city = address
                                            case 4:
                                                homeAddress.state = address
                                            case 5:
                                                homeAddress.postalCode = address
                                            case 6:
                                                homeAddress.country = address
                                            case 7:
                                                homeAddress.isoCountryCode = address
                                            default:
                                                break
                                            }
                                        }
                                        let labeledValue = CNLabeledValue(label:CNLabelHome, value:homeAddress)
                                        
                                        if contact.postalAddresses.isEmpty
                                        {
                                            contact.postalAddresses = [labeledValue as! CNLabeledValue<CNPostalAddress>]
                                        } else {
                                            contact.postalAddresses.append(labeledValue as! CNLabeledValue<CNPostalAddress>)
                                        }
                                    }
                                // Для теста реализованы только 4 поля
                                default: break
                                }
                            }
                        }
                        result.insert(contact)
                    }
                }
            }
        } catch {
            print("error in JSONSerialization")
        }
        return result
    }
    
    func insert(contacts: Set<CNContact> , coordinator: NSPersistentStoreCoordinator? , completion: @escaping () -> Void)
    {
        let privateContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        privateContext.persistentStoreCoordinator = coordinator
        privateContext.perform
            {
                // Удалить прошлые значения в базе
                self.deleteAllObjects(context: privateContext)
                
                let entity = NSEntityDescription.entity(forEntityName: "VCard", in: privateContext)
                
                // добавить уникальные контакты в базу
                for contact in contacts
                {
                    let vCard = VCard(entity: entity!, insertInto: privateContext)
                    vCard.givenName = contact.givenName == "" ? "Unknown" : contact.givenName
                    vCard.object = NSKeyedArchiver.archivedData(withRootObject: contact) as NSData?
                    privateContext.insert(vCard)
                }
                
                // Save the context.
                do { try privateContext.save() }
                catch {
                    let nserror = error as NSError
                    fatalError("Unresolved error in private context \(nserror), \(nserror.userInfo)")
                }
                
                completion()
        }
    }
    
    
    // Сохранить данные в файл при первом запуске и в дальнейшем загружать из файла контакты
    
    //    fileprivate var contactsData : Set<MyContact> = []
    //    fileprivate let filename = NSHomeDirectory().appending("/Documents/contactsData.bin")
    //
    //    override init()
    //    {
    //        super.init()
    //
    //        if let data = try? Data(contentsOf: URL(fileURLWithPath: filename))
    //        {
    //            print("load from file")
    //            contactsData = extractJsonContacts(from: data)
    //        } else {
    //            print("save to file")
    //            let jsonContactsData = createJsonContacts
    //            do {
    //                try jsonContactsData?.write(to: URL(fileURLWithPath: filename ), options: .atomic)
    //                contactsData = extractJsonContacts(from: jsonContactsData)
    //            } catch {
    //                print("Handler error of reading file")
    //            }
    //
    //        }
    //    }
    //    func getContacts () -> Set<MyContact>
    //    {
    //        return contactsData
    //    }
    //
    //    
    
}
