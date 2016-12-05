//
//  MasterViewController.swift
//  test158
//
//  Created by Nice on 01/12/2016.
//  Copyright © 2016 Andrey Kozhurin. All rights reserved.
//

import UIKit
import CoreData
import Contacts

class MasterViewController: UITableViewController, NSFetchedResultsControllerDelegate
{
    var detailViewController: DetailViewController? = nil
    var managedObjectContext: NSManagedObjectContext? = nil
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        if let split = self.splitViewController {
            let controllers = split.viewControllers
            self.detailViewController = (controllers[controllers.count-1] as! UINavigationController).topViewController as? DetailViewController
        }
        
        storyboardPreparation()
        getContacts()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.clearsSelectionOnViewWillAppear = self.splitViewController!.isCollapsed
        super.viewWillAppear(animated)
    }
    
    // MARK: - Functions
    
    func storyboardPreparation () {
        self.refreshControl?.addTarget(self, action: #selector(MasterViewController.refreshControllValueCanged), for: .valueChanged)
        self.refreshControl?.beginRefreshing()
    }
    
    func refreshControllValueCanged () {
        refreshControl?.endRefreshing()
    }
    
    // MARK: - Segues
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        if segue.identifier == "showDetail" {
            if let indexPath = self.tableView.indexPathForSelectedRow {
                let object = self.fetchedResultsController.object(at: indexPath)
                let controller = (segue.destination as! UINavigationController).topViewController as! DetailViewController
                
                if let data = object.object as NSData?
                {
                    if let unarchiveCNContact = NSKeyedUnarchiver.unarchiveObject(with: data as Data) as? CNContact
                    {
                        controller.detailItem = unarchiveCNContact
                    }
                }
                controller.navigationItem.leftBarButtonItem = self.splitViewController?.displayModeButtonItem
                controller.navigationItem.leftItemsSupplementBackButton = true
            }
        }
    }
    
    // MARK: - Table View
    
    override func numberOfSections(in tableView: UITableView) -> Int
    {
        return self.fetchedResultsController.sections?.count ?? 0 // 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        let sections = self.fetchedResultsController.sections
        if let sectionInfo = sections?[section] {
            return sectionInfo.numberOfObjects
        }
        return 0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        let contact = self.fetchedResultsController.object(at: indexPath)
        configureCell(cell, withObject: contact)
        return cell
    }
    
    func configureCell(_ cell: UITableViewCell, withObject object: VCard)
    {
        if let name = object.givenName {
            cell.textLabel!.text = name
        } else {
            cell.textLabel!.text = "Unknown"
        }
    }
    
    // MARK: - Fetched results controller
    
    var fetchedResultsController: NSFetchedResultsController<VCard>
    {
        if _fetchedResultsController != nil { return _fetchedResultsController! }
        
        let fetchRequest: NSFetchRequest<VCard> = VCard.fetchRequest()
        
        // Set the batch size to a suitable number.
        fetchRequest.fetchBatchSize = 20
        
        // Edit the sort key as appropriate.
        let sortDescriptor = NSSortDescriptor(key: "givenName", ascending: true)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        let aFetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.managedObjectContext!, sectionNameKeyPath: nil, cacheName: nil )
        aFetchedResultsController.delegate = self
        _fetchedResultsController = aFetchedResultsController
        
        do { try _fetchedResultsController!.performFetch() }
        catch {
            let nserror = error as NSError
            fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
        }
        
        return _fetchedResultsController!
    }
    var _fetchedResultsController: NSFetchedResultsController<VCard>? = nil
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>){}
}

// MARK: - Contacts

extension MasterViewController
{
    func getContacts()
    {
        let backgroundQueue = DispatchQueue(label: "com.akozhur.backgroundFetchingContactsQueue",
                                            qos: .background,
                                            attributes: .concurrent)
        
        let authorizationStatus = CNContactStore.authorizationStatus(for: .contacts)
        
        switch authorizationStatus
        {
        case .authorized:
            backgroundQueue.async { self.retrieveContacts() }
        default:
            CNContactStore().requestAccess(for: .contacts )
            { authorized, error -> Void in
                
                if authorized { backgroundQueue.async { self.retrieveContacts() } }
                else {
                    DispatchQueue.main.async {
                        self.refreshControl?.endRefreshing()
                        if error != nil {
                            let alertController = UIAlertController(title: "Error", message: error!.localizedDescription, preferredStyle: .alert)
                            alertController.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
                            self.present(alertController, animated: true, completion: nil)
                        }
                    }
                }
            }
        }
    }
    
    func retrieveContacts ()
    {
        // контакты из телефона
        let contactsFromDevice: Set<CNContact> = LibraryAPI.sharedInstance.getContactsFromDevice()
        
        // контакты из файла
        // let contactsFromFile = LibraryAPI.sharedInstance.getContactsFromFile()
        
        // создать контакты
        let vcardContactsData = LibraryAPI.sharedInstance.createVCardContacts
        // контакты из vCard
        let vcardContacts = LibraryAPI.sharedInstance.extractVCardContacts(from: vcardContactsData)
        
        // исключить телефонные контакты из контактов, полученных из vcard
        let allContacts = vcardContacts.union(contactsFromDevice)
        
        let privateContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        privateContext.persistentStoreCoordinator = managedObjectContext?.persistentStoreCoordinator
        privateContext.perform
            {
                let entity = NSEntityDescription.entity(forEntityName: "VCard", in: privateContext)
                
                // добавить уникальные контакты в базу
                for contact in allContacts
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
                
                DispatchQueue.main.async {
                    try? self._fetchedResultsController?.performFetch()
                    self.tableView.reloadData()
                    self.refreshControl?.endRefreshing()
                }
        }
    }
}
