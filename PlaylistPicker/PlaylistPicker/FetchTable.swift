//
//  FetchTable.swift
//  PlaylistPicker
//
//  Created by Thomas Collette on 8/6/21.
//

import UIKit

class iTableViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var playlistSetUp: UIButton!
    @IBOutlet weak var listsToday: UILabel!
    @IBOutlet weak var nowPlaying: UILabel!
    @IBOutlet var iTableView: UITableView!

    var myLists = [Playlist]()
    var thisDayList = Array(repeating: "", count: 10)
    let dayFormatter = DateFormatter()
    let myFormatter = DateFormatter()

    override func viewDidLoad(){
        super.viewDidLoad()
        iTableView.delegate = self
        iTableView.dataSource = self
        load()
        playlistSetUp.fadedGray()
        todayList()
        listsToday.sizeToFit()
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        load()
    }
    let persistentContainer = NSPersistentContainer.init(name: "PlaylistPicker")
    lazy var fetchedResultsController: NSFetchedResultsController<Playlist> = {
        // Create Fetch Request
        let fetchRequest: NSFetchRequest<Playlist> = Playlist.fetchRequest()
        // Configure Fetch Request
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "playListName", ascending: true)]
        let context = CoreDataManager.shared.mainContext        // Create Fetched Results Controller
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)
        // Configure Fetched Results Controller
        fetchedResultsController.delegate = self        
        return fetchedResultsController
    }()
    
    func load(){
        persistentContainer.loadPersistentStores { (persistentStoreDescription, error) in
            if let error = error {
                print("Unable to Load Persistent Store")
                print("\(error), \(error.localizedDescription)!")
            } else {
                do {
                    try self.fetchedResultsController.performFetch()
                } catch {
                    let fetchError = error as NSError
                    print("Unable to Perform Fetch Request")
                    print("\(fetchError), \(fetchError.localizedDescription)!")
                }
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let quotes = fetchedResultsController.fetchedObjects else { return 0 }
        return quotes.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell = UITableViewCell(style: UITableViewCell.CellStyle.subtitle, reuseIdentifier: "cell")        
        configureCell(cell, at:indexPath)
        return cell
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath){
        if(editingStyle == .delete){
            let quote = fetchedResultsController.object(at: indexPath)
            quote.managedObjectContext?.delete(quote)
            let context = CoreDataManager.shared.mainContext
            do {
                try context.save()
                tableView.reloadData()
            } catch let error as NSError {
                print("Could not save. \(error), \(error.userInfo)")
            }
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath){
        let playlist = fetchedResultsController.object(at: indexPath)
        let idNum = playlist.idFreq
        var idText = ""
        if idNum < 10 {
            idText = "songs"
        }
        else {
            idText = "minutes"
        }
        let thisTime = playlist.dateString!
        myFormatter.dateFormat = "HH:mm"
        let timeConvert = myFormatter.date(from: thisTime)
        myFormatter.dateFormat = "hh:mm a"
        let hourStarts = myFormatter.string(from: timeConvert!)
        let alertController = UIAlertController(title: "\(playlist.playListName!) Playlist Settings", message: "", preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: {action in}))
        let paraStyle = NSMutableParagraphStyle()
        paraStyle.alignment = NSTextAlignment.left
        let messageText = NSMutableAttributedString(
            string: "Music Playlist: \(playlist.musicList!)\nID Playlist: \(playlist.idList!)\nStart Time: \(hourStarts)\nDays to Run: \(playlist.playDays!)\nLimit \(playlist.repChoice!) Repetition: \(playlist.sepNum) songs\nSong Repeat Threshold: \(playlist.lastTime) hours\nID Runs: Every \(playlist.idFreq) \(idText)\nID Artist Name: \(playlist.idArtist!)",
            attributes: [
                NSAttributedString.Key.paragraphStyle: paraStyle,
                NSAttributedString.Key.font: UIFont.systemFont(ofSize: 13.0)
            ]
        )
        alertController.setValue(messageText, forKey: "attributedMessage")
        present(alertController, animated: true, completion: nil)
    }
    
    func configureCell(_ cell: UITableViewCell, at indexPath: IndexPath) {
        let playlist = fetchedResultsController.object(at: indexPath)
        var config = cell.defaultContentConfiguration()
        let thisTime = playlist.dateString!
        myFormatter.dateFormat = "HH:mm"
        let timeConvert = myFormatter.date(from: thisTime)
        myFormatter.dateFormat = "hh:mm a"
        let hourStarts = myFormatter.string(from: timeConvert!)
        let daysPlay = playlist.playDays!
        config.text = playlist.playListName
        config.textProperties.font = UIFont(name: "Helvetica-Bold", size: 18)!
        config.secondaryText = "\(hourStarts)  \(daysPlay)"
        cell.contentConfiguration = config
    }
    func todayList() {
        let date = Date()
        let calendar = Calendar.current
        let day = calendar.component(.weekday, from: date)
        dayFormatter.dateFormat = "e"
        let weekday = dayFormatter.weekdaySymbols[day-1]
        nowPlaying.text = "\(weekday)’s Playlists"
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Playlist")
        fetchRequest.predicate = NSPredicate(format: "playDays CONTAINS %@", weekday)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "dateString", ascending: true)]
        let context = CoreDataManager.shared.mainContext
        do {
            myLists = try context.fetch(fetchRequest) as! [Playlist]
            for days in myLists {
                let listSummary = days.playListName
                let hourStart =  days.dateString
                dayFormatter.dateFormat = "HH:mm"
                let timeConvert = dayFormatter.date(from: hourStart!)
                dayFormatter.dateFormat = "hh:mm a"
                let hourStarts = dayFormatter.string(from: timeConvert!)
                thisDayList.removeLast()
                thisDayList.insert("\(hourStarts) - \(listSummary!)", at: 0)
            }
        }
        catch let error as NSError {
            print("Could not load data. \(error), \(error.localizedDescription)")
        }
        thisDayList.reverse()
        let final = thisDayList.filter{$0.count > 0}
        listsToday.text = final.joined(separator: "\n")
    }
}

extension iTableViewController: NSFetchedResultsControllerDelegate {
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        iTableView.beginUpdates()
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        iTableView.endUpdates()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch (type) {
        case .insert:
            if let indexPath = newIndexPath {
                iTableView.insertRows(at: [indexPath], with: .fade)
            }
            break;
        case .delete:
            if let indexPath = indexPath {
                iTableView.deleteRows(at: [indexPath], with: .fade)
            }
            break;
        case .update:
            if let indexPath = indexPath, let cell = iTableView.cellForRow(at: indexPath) {
                configureCell(cell, at: indexPath)
            }
            break;
        case .move:
            if let indexPath = indexPath {
                iTableView.deleteRows(at: [indexPath], with: .fade)
            }
    
            if let newIndexPath = newIndexPath {
                iTableView.insertRows(at: [newIndexPath], with: .fade)
            }
            break;
        }
    }
}
