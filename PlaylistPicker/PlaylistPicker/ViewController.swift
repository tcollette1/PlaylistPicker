//
//  ViewController.swift
//  PlaylistPicker
//
//  Created by Thomas Collette on 6/22/21.
//

import UIKit
import MediaPlayer

class ViewController: UIViewController,UITableViewDelegate,UITableViewDataSource {

    let dateFormatter = DateFormatter()
    let myFormatter = DateFormatter()
    var musicList = ""
    var idList = ""
    var corrected = false
    var repChoice = ""
    let weekdays = ["Sunday","Monday","Tuesday","Wednesday","Thursday","Friday","Saturday"]
    var myLists = [Playlist]()
    var daysToPlay = [String]()
    var playLists = [String]()
    var dateString = "00:00 AM"
    var timeString = "00:00"    
    var dayName = ""
    var stepperView = ""
    var sepNum: Int = 5
    var lastTime: Int = 12
    var idFreq: Int = 2

    @IBOutlet weak var subButton: UIButton!
    @IBOutlet weak var allButton: UIButton!
    @IBOutlet weak var songsButton: UIButton!
    @IBOutlet weak var timeButton: UIButton!
    @IBOutlet weak var setTime: UIDatePicker!
    @IBOutlet weak var incNum: UILabel!
    @IBOutlet weak var lastNum: UILabel!
    @IBOutlet weak var startTime: UILabel!
    @IBOutlet weak var idNum: UILabel!
    @IBOutlet weak var timeIdNum: UILabel!
    @IBOutlet weak var daysList: UILabel!
    @IBOutlet weak var sepLabel: UILabel!
    @IBOutlet weak var switchList: UISegmentedControl!
    @IBOutlet weak var repLimit: UISegmentedControl!
    @IBOutlet weak var setDay: UIStackView!
    @IBOutlet weak var minSeparation: UIStepper!
    @IBOutlet weak var lastPlayed: UIStepper!
    @IBOutlet weak var idStep: UIStepper!
    @IBOutlet weak var timeIdStep: UIStepper!
    @IBOutlet weak var playlistChoices: UITableView!
    @IBOutlet weak var playName: UITextField!
    @IBOutlet weak var idArtist: UITextField!
    @IBOutlet weak var playView: UIView!
    @IBOutlet weak var daysView: UIView!
    @IBOutlet weak var idView: UIView!
    @IBOutlet weak var songStep: UIView!
    @IBOutlet weak var timeStep: UIView!
    @IBOutlet weak var timeView: UIView!
    @IBOutlet weak var limitsView: UIView!
    @IBOutlet weak var mainView: UIView!

    override func viewDidLoad() {
        super.viewDidLoad()
        getPlaylists()
        setupViewController()
        playlistChoices.delegate = self
        playlistChoices.dataSource = self
        dateFormatter.dateFormat = "hh:mm a"
        dateString = dateFormatter.string(from: setTime.date)
        myFormatter.dateFormat = "HH:mm"
        timeString = myFormatter.string(from: setTime.date)
        startTime.text = "Start Time: \(dateString)"
        incNum.text = "None"
        lastNum.text = "12 hours"
        switchList.selectedSegmentIndex = 0
        switchList.addTarget(self, action: #selector(segueChange), for: .valueChanged)
        repLimit.addTarget(self, action: #selector(repControl), for: .valueChanged)
    }
    func savePlaylist() throws {
        let context = CoreDataManager.shared.mainContext
        context.perform {
            let entity = Playlist.entity()
            let playlist = Playlist(entity: entity, insertInto: context)
            playlist.dateString = self.timeString
            playlist.idFreq = Int16(self.idFreq)
            playlist.idList = self.idList
            playlist.lastTime = Int16(self.lastTime)
            playlist.musicList = self.musicList
            playlist.playDays = self.daySorter()
            playlist.playListName = self.playName.text
            playlist.sepNum = Int16(self.sepNum)
            playlist.repChoice = self.repChoice
            playlist.idArtist = self.idArtist.text
            do {
                try context.save()
            } catch let error as NSError {
                print("Fail: \(error.localizedDescription)")
            }
        }
    }
    func daySorter() -> String {
        let playDays = daysToPlay
        var myDays = [String]()
        var dayIndex = [Int]()
        let dayFormatter = DateFormatter()
        for days in playDays {
            dayFormatter.dateFormat = "e"
            let weekday = dayFormatter.date(from: days)
            let weekdayString = dayFormatter.string(from: weekday!)
            let dayInt = Int(weekdayString)
            dayIndex.append(dayInt!)
        }
        dayIndex.sort()
        for myDay in dayIndex {
            myDays.append(dayFormatter.weekdaySymbols[myDay-1])
        }
        let theseDays = myDays.joined(separator: " ")
        return theseDays
    }
    func getPlaylists() {
        let mediaQuery = MPMediaQuery.playlists()
        let thisQuery = mediaQuery.collections
        for playlist in thisQuery! {
            let myList = (playlist.value(forProperty: MPMediaPlaylistPropertyName)!)
            playLists.append(myList as! String)
        }
    }
    func setupViewController() {
        for case let view in mainView.subviews {
            view.fadedGray()
        }
        songsButton.darkGreyRounded()
        songsButton.titleLabel?.font = UIFont(name: "Helvetica-Bold", size: 17)
        timeButton.darkGreyRounded()
        timeButton.titleLabel?.font = UIFont(name: "Helvetica-Bold", size: 17)
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return playLists.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let myLists = playLists.sorted()
        let theList = myLists[indexPath.row]
        var config = cell.defaultContentConfiguration()
        config.text = theList
        config.textProperties.font = UIFont(name: "Helvetica-Bold", size: 17)!
        cell.contentConfiguration = config
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if switchList.selectedSegmentIndex == 0 {
            playLists = playLists.sorted()
            let position = indexPath.row
            musicList = playLists[position]
        }
        else {
            playLists = playLists.sorted()
            let position = indexPath.row
            idList = playLists[position]
        }
    }
    @IBAction func submitButton(_ sender: UIButton) {
        let time = setTime.date
        let dater = Date().timeIntervalSince(time)
        var myFlag = false
        guard let myMusic = playName.text, myMusic != "" else {
            for case let view in mainView.subviews {
                view.fadedGray()
            }
            let alertController = UIAlertController(title: "Missing Info", message: "Playlist Name is missing. Please enter a descriptive name for your playlist", preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: {action in self.playView.orangeWarned()}))
            present(alertController, animated: true, completion: nil)
            return
        }
        guard let myArtist = idArtist.text, myArtist != "" else {
            for case let view in mainView.subviews {
                view.fadedGray()
            }
            let alertController = UIAlertController(title: "Missing Info", message: "ID Artist name is missing. Please enter the exact name of the ID name", preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: {action in self.idView.orangeWarned()}))
            present(alertController, animated: true, completion: nil)
            return
        }
        if musicList == "" {
            for case let view in mainView.subviews {
                view.fadedGray()
            }
            let alertController = UIAlertController(title: "Missing Info", message: "Music playlist is not set. Please make sure the “Playlist for” switch is set to Music and choose a music playlist from the table", preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: {action in self.playView.orangeWarned()}))
            present(alertController, animated: true, completion: nil)
        }
        else if idList == "" {
            for case let view in mainView.subviews {
                view.fadedGray()
            }
            let alertController = UIAlertController(title: "Missing Info", message: "ID playlist is not set. Please make sure the “Playlist for” switch is set to ID and choose an ID playlist from the table", preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: {action in self.playView.orangeWarned()}))
            present(alertController, animated: true, completion: nil)
        }
        else if dater > -900 && dater < 900 && corrected == false {
            for case let view in mainView.subviews {
                view.fadedGray()
            }
            timeView.orangeWarned()
            let dateAlert = UIAlertController(title: "Start Time Check", message: "The start time setting was not affected. To start this playlist at the current time, press Use Current, or Change to edit it", preferredStyle: UIAlertController.Style.alert)
            dateAlert.addAction(UIAlertAction(title: "Use Current", style: .cancel, handler: {action in self.corrected = true;self.timeView.fadedGray()}))
            dateAlert.addAction(UIAlertAction(title: "Change", style: .default, handler: { action in self.corrected = true}))
            present(dateAlert, animated: true, completion: nil)
        }
        else if daysToPlay.isEmpty {
            for case let view in mainView.subviews {
                view.fadedGray()
            }
            let alertController = UIAlertController(title: "Missing Info", message: "No days for the playlist to run are set. Please choose one or more days from the “Days to Run Playlist” buttons", preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: {action in self.daysView.orangeWarned()}))
            present(alertController, animated: true, completion: nil)
        }
        else {
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Playlist")
            fetchRequest.predicate = NSPredicate(format: "dateString CONTAINS %@", timeString)
            let context = CoreDataManager.shared.mainContext
            do {
                myLists = try context.fetch(fetchRequest) as! [Playlist]
                if myLists.count > 0 {
                    for days in myLists {
                        let daysToStart = days.playDays
                        let daysWanted = daysToPlay.joined(separator: " ")
                        let components = daysToStart!.components(separatedBy: " ")
                        let component = daysWanted.components(separatedBy: " ")
                        if components.contains (where: component.contains(_:)) {
                            let alertController = UIAlertController(title: "Playlist Conflict", message: "A playlist with this start time and day(s) already exists. Only one playlist can be scheduled at a specific day and time", preferredStyle: .alert)
                            alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: {action in self.daysView.orangeWarned(); self.timeView.orangeWarned()}))
                            present(alertController, animated: true, completion: nil)
                            myFlag = true
                            break
                        }
                    }
                }
                if myFlag == false {
                    do {
                        try savePlaylist()
                    } catch let error as NSError {
                        print("Fail: \(error.localizedDescription)!")
                    }
                    let alertController = UIAlertController(title: "Playlist Saved!", message: "", preferredStyle: .alert)
                    alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: {action in self.reset()}))
                    let paragraphStyle = NSMutableParagraphStyle()
                    paragraphStyle.alignment = NSTextAlignment.left
                    let messageText = NSMutableAttributedString(
                        string: "Playlist \(myMusic) is set with these parameters:\nMusic Playlist: \(musicList)\nID Playlist: \(idList)\nStart Time: \(dateString)\nDays to Run: \(daySorter())\nLimit \(repChoice) Repetition: \(sepNum) songs\nSong Repeat Threshold: \(lastTime) hours\nID Runs: Every \(idFreq) \(stepperView)\nID Artist Name: \(myArtist)",
                        attributes: [
                            NSAttributedString.Key.paragraphStyle: paragraphStyle,
                            NSAttributedString.Key.font: UIFont.systemFont(ofSize: 13.0)
                        ]
                    )
                    alertController.setValue(messageText, forKey: "attributedMessage")
                    present(alertController, animated: true, completion: nil)
                    for case let btn as UIButton in daysView.subviews {
                        btn.isSelected = false
                    }
                    for case let btn as UIButton in setDay.subviews {
                        btn.isSelected = false
                    }
                    for case let view in mainView.subviews {
                        view.fadedGray()
                    }
                    setTime.setDate(Date(), animated: true)
                    switchList.selectedSegmentIndex = 0
                    repLimit.selectedSegmentIndex = -1
                    corrected = false
                    playlistChoices.reloadData()
                    daysList.text = ""
                    allButton.isHidden = false
                }
            }
            catch let error as NSError {
                print("Could not load data. \(error), \(error.localizedDescription)")
            }
        }
    }
    @IBAction func datePickerChanged(_ sender: UIDatePicker!) {
        dateString = dateFormatter.string(from: sender.date)
        myFormatter.dateFormat = "HH:mm"
        timeString = myFormatter.string(from: sender.date)
        startTime.text = "Start Time: \(dateString)"
        timeView.fadedGray()
    }
    @IBAction func stepperChange(_ sender:UIStepper) {
        sepNum = Int(sender.value)
        var result = 0
        if repChoice == "Album" {
            switch sepNum {
            case 5:
                result = 2
                incNum.text = "\(result) songs"
            case 10:
                result = 3
                incNum.text = "\(result) songs"
            case 15:
                result = 4
                incNum.text = "\(result) songs"
            case 20:
                result = 5
                incNum.text = "\(result) songs"
            default:
                result = 2
                incNum.text = "\(result) songs"
            }
            if result != 0 {
                sepNum = result
            }
        }
        else {
        incNum.text = "\(sepNum) songs"
        }
    }
    @IBAction func stepChange(_ sender:UIStepper) {
        lastTime = Int(sender.value)
        var result = 0
        switch lastTime {
        case 84:
            result = 120
            lastNum.text = "5 days"
        case 96:
            result = 168
            lastNum.text = "7 days"
        default:
            result = lastTime
            lastNum.text = "\(lastTime) hours"
        }
        if result != 0 {
            lastTime = result
        }
    }
    @IBAction func segueChange(_ sender: UISegmentedControl) {
        playlistChoices.reloadData()
    }
    @IBAction func repControl(_ sender: UISegmentedControl) {
        if repLimit.selectedSegmentIndex == 1 {
            repChoice = "Album"
            sepNum = 2
            incNum.text = "\(sepNum) songs"
            sepLabel.text = "Limit Repetition By: Album"
        }
        else if repLimit.selectedSegmentIndex == 0 {
            repChoice = "Artist"
            sepNum = 5
            incNum.text = "\(sepNum) songs"
            sepLabel.text = "Limit Repetition By: Artist"
        }
        else {
            repChoice = ""
        }
    }
    func reset() {
        UIView.animate(withDuration: 0.75, delay: 0.25, options: .curveEaseIn, animations: { [self] in
            songsButton.alpha = 1
            timeButton.alpha = 1
            if stepperView == "songs" {
                songStep.transform = CGAffineTransform(translationX: 0, y: 75)
            }
            else {
                timeStep.transform = CGAffineTransform(translationX: 0, y: 75)
            }
        }, completion: nil)
        repChoice = ""
        playName.text = ""
        daysToPlay.removeAll()
        dateString = ""
    }
    @IBAction func cancelButton(_ sender:UIButton) {
        UIView.animate(withDuration: 0.5, delay: 0.5, options: .curveEaseIn, animations: { [self] in
            songsButton.alpha = 1
            timeButton.alpha = 1
            if stepperView == "songs" {
                songStep.transform = CGAffineTransform(translationX: 0, y: 75)
            }
            else {
                timeStep.transform = CGAffineTransform(translationX: 0, y: 75)
            }
        }, completion: nil)
        idFreq = 0
    }
    @IBAction func idChange(_ sender:UIStepper) { // idFreq only works if touched
        idFreq = Int(sender.value)
        idNum.text = String(idFreq)
        timeIdNum.text = String(idFreq)
    }
    @IBAction func songsIDButton(_ sender: UIButton!) {
        stepperView = "songs"
        idFreq = 2
        idNum.text = String(idFreq)
        sender.titleLabel?.font = UIFont(name: "Helvetica-Bold", size: 17)
        UIView.animate(withDuration: 0.5, delay: 0.5, options: .curveEaseOut, animations: { [self] in
            sender.alpha = 0
            timeButton.alpha = 0
            songStep.transform = CGAffineTransform(translationX: 0, y: -75)
        }, completion: nil)
    }
    @IBAction func timeIDButton(_ sender: UIButton!) {
        stepperView = "minutes"
        idFreq = 10
        timeIdNum.text = String(idFreq)
        sender.titleLabel?.font = UIFont(name: "Helvetica-Bold", size: 17)
        UIView.animate(withDuration: 0.5, delay: 0.5, options: .curveEaseOut, animations: { [self] in
            sender.alpha = 0
            songsButton.alpha = 0
            timeStep.transform = CGAffineTransform(translationX: 0, y: -75)
        }, completion: nil)
    }
    @IBAction func allDays(_ sender: UIButton!) {
        if daysToPlay.isEmpty {
            daysToPlay = weekdays
            daysList.text = daysToPlay.joined(separator: " ")
            for case let btn as UIButton in setDay.subviews {
                btn.isSelected = true
            }
        }
        else {
            if sender.isSelected == true {
                for case let btn as UIButton in setDay.subviews {
                    btn.isSelected = false
                }
                daysToPlay.removeAll()
                daysList.text = daysToPlay.joined()
            }
        }
        sender.isSelected = !sender.isSelected
    }
    @IBAction func sunDays(_ sender: UIButton!) {
        dayName = weekdays[sender.tag - 1]
        if sender.isSelected == true {
            daysToPlay.removeAll(where: dayName.contains)
        }
        else {
            daysToPlay.append(dayName)
        }
        daysList.text = daysToPlay.joined(separator: " ")
        allButton.isHidden = true
        sender.isSelected = !sender.isSelected
    }
    @IBAction func monDays(_ sender: UIButton!) {
        dayName = weekdays[sender.tag - 1]
        if sender.isSelected == true {
            daysToPlay.removeAll(where: dayName.contains)
        }
        else {
            daysToPlay.append(dayName)
        }
        daysList.text = daysToPlay.joined(separator: " ")
        allButton.isHidden = true
        sender.isSelected = !sender.isSelected
    }
    @IBAction func tuesDays(_ sender: UIButton!) {
        dayName = weekdays[sender.tag - 1]
        if sender.isSelected == true {
            daysToPlay.removeAll(where: dayName.contains)
        }
        else {
            daysToPlay.append(dayName)
        }
        daysList.text = daysToPlay.joined(separator: " ")
        allButton.isHidden = true
        sender.isSelected = !sender.isSelected
    }
    @IBAction func wedDays(_ sender: UIButton!) {
        dayName = weekdays[sender.tag - 1]
        if sender.isSelected == true {
            daysToPlay.removeAll(where: dayName.contains)
        }
        else {
            daysToPlay.append(dayName)
        }
        daysList.text = daysToPlay.joined(separator: " ")
        allButton.isHidden = true
        sender.isSelected = !sender.isSelected
    }
    @IBAction func thursDays(_ sender: UIButton!) {
        dayName = weekdays[sender.tag - 1]
        if sender.isSelected == true {
            daysToPlay.removeAll(where: dayName.contains)
        }
        else {
            daysToPlay.append(dayName)
        }
        daysList.text = daysToPlay.joined(separator: " ")
        allButton.isHidden = true
        sender.isSelected = !sender.isSelected
    }
    @IBAction func friDays(_ sender: UIButton!) {
        dayName = weekdays[sender.tag - 1]
        if sender.isSelected == true {
            daysToPlay.removeAll(where: dayName.contains)
        }
        else {
            daysToPlay.append(dayName)
        }
        daysList.text = daysToPlay.joined(separator: " ")
        allButton.isHidden = true
        sender.isSelected = !sender.isSelected
    }
    @IBAction func satDays(_ sender: UIButton!) {
        dayName = weekdays[sender.tag - 1]
        if sender.isSelected == true {
            daysToPlay.removeAll(where: dayName.contains)
        }
        else {
            daysToPlay.append(dayName)
        }
        daysList.text = daysToPlay.joined(separator: " ")
        allButton.isHidden = true
        sender.isSelected = !sender.isSelected
    }
}

