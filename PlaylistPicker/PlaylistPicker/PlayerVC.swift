//
//  PlayerVC.swift
//  PlaylistPicker
//
//  Created by Thomas Collette on 8/31/21.
//

import UIKit
import MediaPlayer

class PlayerVC: UIViewController {
    var songData: SongData = SongData()
    var queueArrays: QueueArrays = QueueArrays()
    let mp = MPMusicPlayerController.applicationMusicPlayer
    var timer2 = Timer()
    var isClockRunning = false
    var isEdited = false
    var isPlaying = false
    var isTimerRunning = false
    var sameHour = false
    var myLists = [Playlist]()
    var artists = Array(repeating: "", count: 15)
    let dayFormatter = DateFormatter()
    let myFormatter = DateFormatter()
    var dateString = "01:00"
    var idArtist = ""
    var playListName = ""
    var trackNum = 1
    @IBOutlet weak var clockButton: UIButton!
    @IBOutlet weak var editMusic: UIButton!
    @IBOutlet weak var playlistSetUp: UIButton!
    @IBOutlet weak var playStart: UIButton!
    @IBOutlet weak var viewLists: UIButton!
    @IBOutlet weak var imageAlbum: UIImageView!
    @IBOutlet weak var artistList: UILabel!
    @IBOutlet weak var currentList: UILabel!
    @IBOutlet weak var labelDuration: UILabel!
    @IBOutlet weak var labelElapse: UILabel!
    @IBOutlet weak var labelRem: UILabel!
    @IBOutlet weak var labelTime: UILabel!
    @IBOutlet weak var labelTitle: UILabel!
    @IBOutlet weak var sepIndex: UILabel!
    @IBOutlet weak var progressBar: UIProgressView!
    @IBAction func cancel(_ unwindSegue: UIStoryboardSegue) {}
    @IBAction func save(_ unwindSegue: UIStoryboardSegue) {
        if let editViewController = unwindSegue.source as? MusicController {
            queueArrays.myList = editViewController.musicList
            if isTimerRunning == true { // pre-transition
                if trackNum > songData.trackIndex { // pre-transition return always 1 < 2+
                    trackNum = songData.trackIndex
                    queueArrays.myList.removeSubrange(0...trackNum - 1)
                }
            }
            else { // timer is off, trackIndex > 1, array truncates at trackNum 
                trackNum = songData.trackIndex
                queueArrays.myList.removeSubrange(0...trackNum - 1)
            }
            queueArrays.listResults = MPMediaItemCollection(items: queueArrays.myList)
            isEdited = true
            if isTimerRunning == false {
                isTimerRunning = true
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        imageAlbum.image = UIImage(named: "playlistpicker-icon_256x256.png")
        queueArrays.myQuery = MPMediaQuery.songs()
        let predicate = MPMediaPropertyPredicate(value: false,
                                                 forProperty: MPMediaItemPropertyIsCloudItem,
                                                 comparisonType: .equalTo)
        queueArrays.myQuery.addFilterPredicate(predicate)
        failSafe()
        updateNowPlayingInfo()
        NotificationCenter.default.addObserver(self, selector: #selector(self.dayStart(_:)), name: .NSCalendarDayChanged, object: nil)
        playStart.alpha = 0.5
        viewLists.fadedGray()
        playlistSetUp.fadedGray()
        editMusic.fadedGray()
        editMusic.alpha = 0
    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let musicVC = segue.destination as? MusicController {
            if queueArrays.myList == nil || queueArrays.myList.isEmpty {
                let hourStart = myLists[0].dateString
                myFormatter.dateFormat = "HH:mm"
                let timeConvert = myFormatter.date(from: hourStart!)
                myFormatter.dateFormat = "hh:mm a"
                let hourStarts = myFormatter.string(from: timeConvert!)
                let alertController = UIAlertController(title: "Missing Data", message: "Playlist Picker has not yet generated a playlist queue. The next scheduled queue will run at \(hourStarts)", preferredStyle: .alert)
                alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: {action in}))
                present(alertController, animated: true, completion: nil)
            }
            else {
                if isTimerRunning == true {
                    trackNum = 1
                }
                else {
                    trackNum = songData.trackIndex
                }
                musicVC.tracksPlayed = trackNum - 1
                musicVC.musicList = queueArrays.myList
            }
        }
    }
    func failSafe() {
        let date = Date()
        let calendar = Calendar.current
        let day = calendar.component(.weekday, from: date)
        dayFormatter.dateFormat = "e"
        let weekday = dayFormatter.weekdaySymbols[day-1]
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Playlist")
            fetchRequest.predicate = NSPredicate(format: "playDays CONTAINS %@", weekday)
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "dateString", ascending: true)]
            let context = CoreDataManager.shared.mainContext
            do {
                myLists = try ((context.fetch(fetchRequest) as? [Playlist])!)
                if myLists.count == 0 {
                    let alertController = UIAlertController(title: "Missing Data", message: "No music playlists exist for \(weekday). Please press the “Playlist Set Up” button to schedule at least 2 playlists for \(weekday)", preferredStyle: .alert)
                    alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: {action in}))
                    present(alertController, animated: true, completion: nil)
                }
                if myLists.count < 2 {
                    let alertController = UIAlertController(title: "Low Playlist Count", message: "Not enough music playlists exist for \(weekday). Schedule at least 2 playlists for each day you will run the app in “Playlist Set Up”", preferredStyle: .alert)
                    alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: {action in}))
                    present(alertController, animated: true, completion: nil)
                }
            }
            catch let error as NSError {
                print("Could not load data. \(error), \(error.localizedDescription)")
            }
        let unixDate = Date(timeIntervalSinceNow: -31000000)
        let thisTime = Double(-7200)
        let lastTime = Date(timeIntervalSinceNow:thisTime)
        var artistSet = [MPMediaItem]()
        var lastArtists = Array(repeating: "", count: 15)
        if let songs = queueArrays.myQuery.items {
            artistSet = songs.filter { ($0.lastPlayedDate ?? unixDate) > lastTime as Date }
            artistSet = artistSet.sorted{$0.lastPlayedDate ?? unixDate < $1.lastPlayedDate ?? unixDate}
        }
        for performer in artistSet {
           let artist = performer.artist ?? "No Artist"
            lastArtists.append(artist)
            lastArtists.remove(at: 0)
        }
        artists = lastArtists
        artists.reverse()
        artistList.text = artists.joined(separator: "\n")
    }
    @IBAction func clockButton(_ sender:UIButton!) {
        isClockRunning = true
        let calendar = Calendar.current
        var hourStart = myLists[0].dateString
        var hourEnd = myLists[1].dateString
        myFormatter.dateFormat = "HH:mm"
        let date = Date()
        let curHour = calendar.component(.hour, from: date)
        let curMinute = calendar.component(.minute, from: date)
        var timeConvert = myFormatter.date(from: hourStart!)
        var endTime = myFormatter.date(from: hourEnd!)
        var hour = calendar.component(.hour, from: timeConvert!) // start time
        let minute = calendar.component(.minute, from: timeConvert!)
        var endHour = calendar.component(.hour, from: endTime!) // end time
        if isClockRunning == true {
            if curHour == 0 && hour == 0 { // midnight hour
                let playAlert = UIAlertController(title: "Playlist Check", message: "If a scheduled playlist is running now, press “Queue Next Playlist”. Press “Play Now” to begin scheduled playlist at once", preferredStyle: UIAlertController.Style.alert)
                playAlert.addAction(UIAlertAction(title: "Queue Next Playlist", style: .default, handler: {action in self.selfStart()}))
                playAlert.addAction(UIAlertAction(title: "Play Now", style: .default, handler: {action in self.playNow()}))
                present(playAlert, animated: true, completion: nil)
            }
            if curHour < hour { // > 0 but < 4 before Smooth runs, part of failSafe()?
                let day = calendar.component(.weekday, from: date)
                dayFormatter.dateFormat = "e"
                var weekday = dayFormatter.weekdaySymbols[day-1]
                if weekday == dayFormatter.weekdaySymbols[0] {
                    weekday = dayFormatter.weekdaySymbols[6]
                }
                else {
                    weekday = dayFormatter.weekdaySymbols[day-2]
                }
                let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Playlist")
                fetchRequest.predicate = NSPredicate(format: "playDays CONTAINS %@", weekday)
                fetchRequest.sortDescriptors = [NSSortDescriptor(key: "dateString", ascending: true)]
                let context = CoreDataManager.shared.mainContext
                do {
                    let yesterList = try context.fetch(fetchRequest) as! [Playlist]
                    let count = yesterList.count
                    let lastList = yesterList[count - 1]
                    myLists.insert(lastList, at: 0)
                    let playAlert = UIAlertController(title: "Playlist Check", message: "If a scheduled playlist is running now, press “Queue Next Playlist”. Press “Play Now” to begin scheduled playlist at once", preferredStyle: UIAlertController.Style.alert)
                    playAlert.addAction(UIAlertAction(title: "Queue Next Playlist", style: .default, handler: {action in self.selfStart()}))
                    playAlert.addAction(UIAlertAction(title: "Play Now", style: .default, handler: {action in self.playNow()}))
                    present(playAlert, animated: true, completion: nil)
                }
                catch let error as NSError {
                    print("Could not load data. \(error), \(error.localizedDescription)")
                }
            }
            if hour == curHour && curMinute >= minute { // need handler for minute of curHour
                let playAlert = UIAlertController(title: "Playlist Check", message: "If a scheduled playlist is running now, press “Queue Next Playlist”. Press “Play Now” to begin scheduled playlist at once", preferredStyle: UIAlertController.Style.alert)
                playAlert.addAction(UIAlertAction(title: "Queue Next Playlist", style: .default, handler: {action in self.selfStart()}))
                playAlert.addAction(UIAlertAction(title: "Play Now", style: .default, handler: {action in self.playNow()}))
                present(playAlert, animated: true, completion: nil)
            }
            else { // is this even working?!
                if myLists.count > 0 {
                    let inertAlert = UIAlertController(title: "No Playlist To Run" , message: "No playlist is scheduled until \(hourStart!)", preferredStyle: UIAlertController.Style.alert)
                    inertAlert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                }
                else {
                    let inertAlert = UIAlertController(title: "No Playlists" , message: "You have no playlists scheduled today", preferredStyle: UIAlertController.Style.alert)
                    inertAlert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                }
            }
            while hour < curHour { // 20 < 21 will Queue New Age or Play Now Desert, endHour is 22
                if endHour == curHour { // at 22 loop ends, only New Age remains
                    sameHour = true
                    if myLists.count > 2 {
                        myLists.remove(at: 0)
                        hourStart = myLists[0].dateString
                        timeConvert = myFormatter.date(from: hourStart!)
                        hour = calendar.component(.hour, from: timeConvert!)
                        hourEnd = myLists[1].dateString
                        endTime = myFormatter.date(from: hourEnd!)
                        endHour = calendar.component(.hour, from: endTime!) // 20 is last endHour
                    }
                    else if myLists.count == 2 { // 22 < 23 would restart loop, so break?
                        myLists.remove(at: 0)
                        hourStart = myLists[0].dateString
                        timeConvert = myFormatter.date(from: hourStart!)
                        hour = calendar.component(.hour, from: timeConvert!)
                        endHour = 24
                    }
                    let playAlert = UIAlertController(title: "Playlist Start/Reset", message: "", preferredStyle: UIAlertController.Style.alert)
                    if mp.playbackState != .playing {
                        playAlert.addAction(UIAlertAction(title: "Play Now", style: .default, handler: {action in self.playNow()}))
                        playAlert.message = "No scheduled playlist is running. Press “Play Now” to run a scheduled playlist"
                    }
                    else {
                        playAlert.addAction(UIAlertAction(title: "Start/Reset Playlist", style: .default, handler: {action in self.selfStart()}))
                        playAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: {action in self.sameHour = false;self.selfStart()})) // need a new function to handle
                        playAlert.message = "A scheduled playlist is running its first hour. Press “Reset Playlist” to reset and restart the playlist, or “Cancel” to continue as is"
                    }
                    present(playAlert, animated: true, completion: nil)
                    break
                }
                else if endHour < curHour {
                    if myLists.count > 2 {
                        myLists.remove(at: 0)
                        hourStart = myLists[0].dateString
                        timeConvert = myFormatter.date(from: hourStart!)
                        hour = calendar.component(.hour, from: timeConvert!)
                        hourEnd = myLists[1].dateString
                        endTime = myFormatter.date(from: hourEnd!)
                        endHour = calendar.component(.hour, from: endTime!) // 20 is last end hour
                    }
                    else if myLists.count == 2 { // hour 23
                        myLists.remove(at: 0)
                        hourStart = myLists[0].dateString
                        timeConvert = myFormatter.date(from: hourStart!)
                        hour = calendar.component(.hour, from: timeConvert!)
                        endHour = 24
                    }
                }
                else { // lands on current playlist, either to start it or queue next
                    let queueNext = (UIAlertAction(title: "Queue Next Playlist", style: .default, handler: {action in self.selfStart()}))
                    let playAlert = UIAlertController(title: "Playlist Check", message: "", preferredStyle: UIAlertController.Style.alert)
                    playAlert.addAction(queueNext)
                    if mp.nowPlayingItem == nil {
                        queueNext.isEnabled = false
                        playAlert.message = "No scheduled playlist is running. Press “Play Now” to run a scheduled playlist"
                    }
                    else {
                        queueNext.isEnabled = true
                        playAlert.message = "If a scheduled playlist is running now, press “Queue Next Playlist”. Press “Play Now” to start a scheduled playlist"
                    }
                    playAlert.addAction(UIAlertAction(title: "Play Now", style: .default, handler: {action in self.playNow()}))
                    present(playAlert, animated: true, completion: nil)
                    break
                }
                hourStart = myLists[0].dateString
                timeConvert = myFormatter.date(from: hourStart!)
                hour = calendar.component(.hour, from: timeConvert!)
            } // end while loop
            UIView.animate(withDuration: 0.5, delay: 5, options: .curveEaseIn, animations: {
                sender.backgroundColor = UIColor.red
                sender.transform = CGAffineTransform(scaleX: 0.05, y: 0.05)
            }, completion: nil)
            editMusic.alpha = 1
        }// end if clockRunning
    }
    func selfStart() {
        if myLists[0].repChoice != "Artist" || myLists[0].repChoice != "Album" {
            sepIndex.text = "Separation component inactive"
            if sameHour == false {
                if myLists.count > 1 {
                    myLists.remove(at: 0)
                }
            }
        }
        else {
            sepIndex.text = "\(myLists[0].repChoice!) separation: \(myLists[0].sepNum) songs"
            if sameHour == false {
                if myLists.count > 1 {
                    myLists.remove(at: 0)
                }
            }
        }
        dateString = myLists[0].dateString! // last is 10 pm
        idArtist = myLists[0].idArtist!
        playListName = myLists[0].playListName!
        currentList.text = "Playlist in queue: \(playListName) | ID Artist: \(idArtist)"
        isPlaying = true
        playStart.setBackgroundImage(UIImage(systemName: "pause"), for: .normal)
        playStart.alpha = 1
        playStart.tintColor = .yellow
        runTimer()
        updateNowPlayingInfo()
    }
    func playNow() {
        dateString = myLists[0].dateString!
        playStart.setBackgroundImage(UIImage(systemName: "pause"), for: .normal)
        playStart.alpha = 1
        playStart.tintColor = .yellow
        isPlaying = true
        runTimer()
        updateNowPlayingInfo()
    }
    @IBAction func startButton(_ sender:UIButton!) {
        if mp.playbackState == .paused || mp.playbackState == .stopped {
            isPlaying = true
            playStart.setBackgroundImage(UIImage(systemName: "pause"), for: .normal)
            playStart.tintColor = .yellow
            playStart.alpha = 1
            mp.play()
        }
        else if mp.playbackState == .playing {
            isPlaying = false
            playStart.setBackgroundImage(UIImage(systemName: "play"), for: .normal)
            playStart.tintColor = .green
            playStart.alpha = 1
            mp.pause()
        }
    }
    func runTimer() {
        timer2 = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(self.tick), userInfo: nil, repeats: true)
        timer2.tolerance = 0.05
    }
    @objc func updateNowPlayingInfo() {
        if let currentTrack = mp.nowPlayingItem {
            songData.trackIndex = mp.indexOfNowPlayingItem + 1
            let songName = currentTrack.title
            let songArtist = (currentTrack.artist ?? "Various")
            labelTitle.text = "\(songData.trackIndex!) - \(songArtist) - \(songName ?? "Untitled")"
            var albumImage = currentTrack.artwork?.image(at: imageAlbum.bounds.size)
            if albumImage == nil {
                albumImage = UIImage(named: "playlistpicker-icon_256x256.png")
            }
            imageAlbum.image = albumImage
            songData.trackDuration = currentTrack.playbackDuration
            songData.pID = currentTrack.persistentID
            let trackDurationMinutes = Int(songData.trackDuration / 60)
            let trackDurationSeconds = Int(songData.trackDuration.truncatingRemainder(dividingBy: 60))
            labelDuration.text = "Length: \(trackDurationMinutes):" + String(format: "%02d", trackDurationSeconds)
            if songArtist != "\(idArtist)" && songArtist != artists[0] {
                artists.removeLast()
                artists.insert(songArtist, at: 0)
            }
            artistList.text = artists.joined(separator: "\n")
        }
    }
    @objc func playTime() -> Double {
        if isPlaying == true {
           mp.play()
        }
        let trackElapsed = mp.currentPlaybackTime.rounded(.up)
        return trackElapsed
    }
    @objc func tick(timer2: Timer) {
        let date = Date()
        labelTime.text = DateFormatter.localizedString(from: date, dateStyle: .full, timeStyle: .medium)
        if myLists.count > 0 {
            let calendar = Calendar.current
            let hourStart = dateString
            myFormatter.dateFormat = "HH:mm"
            let timeConvert = myFormatter.date(from: hourStart)
            let hour = calendar.component(.hour, from: timeConvert!)
            let minute = calendar.component(.minute, from: timeConvert!)
            let curHour = calendar.component(.hour, from: date)
            let curMinute = calendar.component(.minute, from: date)
            if curHour >= hour && curMinute >= minute {
                if isTimerRunning == false {
                    isTimerRunning = true
                    fetchList()
                }
            }
        }
        if let currentTrack = mp.nowPlayingItem {
            var trackRemaining = Int(songData.trackDuration ?? 5.0) - Int(playTime())
            trackRemaining = max(trackRemaining, 0)
            if isTimerRunning == true {
                if songData.trackDuration > 0 {
                    if trackRemaining < 2 {
                        isPlaying = false
                        mp.stop()
                        mp.setQueue(with: queueArrays.listResults)
                        mp.shuffleMode = .off
                        mp.repeatMode = .all
                        mp.prepareToPlay()
                        mp.play()
                        isPlaying = true
                        isTimerRunning = false
                        if myLists.count > 0 {
                            dateString = myLists[0].dateString!
                        }
                        if isEdited == false {
                            currentList.text = "Current playlist: \(playListName) | ID Artist: \(idArtist)"
                            currentList.textColor = .white
                            sepIndex.textColor = .white
                        }
                        else {
                            currentList.text = "Playlist \(playListName) has been updated"
                            currentList.textColor = .systemTeal
                            sepIndex.textColor = .white
                            isEdited = false
                        }
                    }
                }
                else { // is stream of zero duration playing?
                    isPlaying = false
                    mp.stop()
                    mp.setQueue(with: queueArrays.listResults)
                    mp.shuffleMode = .off
                    mp.repeatMode = .all
                    mp.prepareToPlay()
                    mp.play()
                    isPlaying = true
                    isTimerRunning = false
                    if myLists.count > 0 {
                        dateString = myLists[0].dateString!
                    }
                    currentList.text = "Current playlist: \(playListName) | ID Artist: \(idArtist)"
                    currentList.textColor = .white
                    sepIndex.textColor = .white
                }
            }
            if currentTrack.persistentID != songData.pID {
                updateNowPlayingInfo()
            }
            let trackElapsedMinutes = Int(playTime() / 60)
            let trackElapsedSeconds = Int(playTime().truncatingRemainder(dividingBy: 60))
            labelElapse.text = "\(trackElapsedMinutes):" + String(format: "%02d", trackElapsedSeconds)
            let trackRemainingMinutes = trackRemaining / 60
            let trackRemainingSeconds = trackRemaining % 60
            labelRem.text = "\(trackRemainingMinutes):" + String(format: "%02d", trackRemainingSeconds)
            let playbackProgress = Float(playTime()/songData.trackDuration)
            progressBar.setProgress(playbackProgress, animated: true)
        }
        else { // dead start
            mp.setQueue(with: (queueArrays.listResults))
            mp.shuffleMode = .off
            mp.repeatMode = .all
            mp.prepareToPlay()
            mp.play()
            isTimerRunning = false
            isPlaying = true
            currentList.text = "Current playlist: \(playListName) | ID Artist: \(idArtist)"
            currentList.textColor = .white
            sepIndex.textColor = .white
            if myLists.count > 0 {
                dateString = myLists[0].dateString!
            }
        }
    }
    func fetchList() {
        if myLists[0].repChoice! == "Artist" {
            fetchPlaylist()
        }
        else if myLists[0].repChoice! == "Album" {
            fetchAlbumPlaylist()
        }
        else {
            fetchTheBlues()
        }
    }
    func fetchPlaylist() {
        idArtist = myLists[0].idArtist!
        let predicate = MPMediaPropertyPredicate(value: "\(myLists[0].musicList!)",
                                                 forProperty: MPMediaPlaylistPropertyName,
                                                 comparisonType: .equalTo)
        queueArrays.myQuery.addFilterPredicate(predicate)
        let unixDate = Date(timeIntervalSinceReferenceDate: 0) // 80.8
        let thisTime = Double(Int(myLists[0].lastTime)*(-3600))
        let lastTime = Date(timeIntervalSinceNow:thisTime) // 77
        var collection = [MPMediaItem]() // 84.2
        queueArrays.myList = [MPMediaItem]() // 84.2
        if let songs = queueArrays.myQuery.items {
            collection = songs.filter { ($0.lastPlayedDate ?? unixDate) < lastTime as Date }
            if mp.playbackState != .stopped {
                queueArrays.myList = collection.filter{($0.persistentID != songData.pID)} //84.3
            }
            else {
                queueArrays.myList = collection
            }
        }
        queueArrays.myQuery.removeFilterPredicate(predicate)
        queueArrays.myList = queueArrays.myList.shuffled()
        var artistsList = artists[0..<Int(myLists[0].sepNum)]
        for performer in queueArrays.myList {
            let artist = performer.artist ?? "No Artist"
            if artistsList.contains(where: artist.contains) {
                if let index = queueArrays.myList.firstIndex(of: performer) {
                    queueArrays.myList.remove(at: index)
                }
            }
            else {
                artistsList.removeLast()
                artistsList.insert(artist, at: 0)
            }
        }
        let voicerPredicate = MPMediaPropertyPredicate(value: "\(myLists[0].idList!)",
                                                       forProperty: MPMediaPlaylistPropertyName,
                                                       comparisonType: .equalTo)
        queueArrays.myQuery.addFilterPredicate(voicerPredicate)
        var voiceCollection = [MPMediaItem]()
        if let voicers = queueArrays.myQuery.items {
            voiceCollection = voicers.sorted{$0.lastPlayedDate ?? unixDate < $1.lastPlayedDate ?? unixDate}
        }
        queueArrays.myQuery.removeFilterPredicate(voicerPredicate)
        var interR = 0
        var indexV = 0
        if myLists[0].idFreq < 10 {
            if voiceCollection.count * Int(myLists[0].idFreq) > queueArrays.myList.count {
                currentList.textColor = .red
                currentList.text = "Song/voicer ratio is too low. Playlist cannot run"
            }
            else {
                repeat {
                    queueArrays.myList.insert(voiceCollection[indexV], at:interR)
                    interR += Int(myLists[0].idFreq) + 1 // determine prior by idFreq * voicer.count?
                    indexV += 1
                } while indexV < voiceCollection.count
                queueArrays.myList.removeSubrange(interR + Int(myLists[0].idFreq)..<queueArrays.myList.count)
                currentList.textColor = .green
                playListName = myLists[0].playListName!
                currentList.text = "Queued Playlist: \(playListName) | ID Artist: \(idArtist)"
                sepIndex.textColor = .green
                sepIndex.text = "Artist separation: \(Int(myLists[0].sepNum)) songs\nID separation: \(Int(myLists[0].idFreq)) songs"
                queueArrays.listResults = MPMediaItemCollection(items: queueArrays.myList)
                if myLists.count > 0 {
                    myLists.remove(at: 0)
                }
            }
        }
        else {
            var times = [Int]()
            for timePlay in queueArrays.myList {
                let duration = Int(timePlay.playbackDuration)
                times.append(duration)
            }
            let sum = times.reduce(0, +)
            let trackRemaining = Int(songData.trackDuration) - Int(playTime())
            var sumTimes = Int(myLists[0].idFreq*60)
            let coEfficient = sumTimes*(voiceCollection.count + 2)
            sumTimes = sumTimes + trackRemaining
            var indexT = -1
            if sum > coEfficient {
                repeat {
                    if sumTimes < Int(myLists[0].idFreq*60) {
                        indexT += 1
                        sumTimes += Int(times[indexT])
                        interR += 1
                    }
                    else {
                        queueArrays.myList.insert(voiceCollection[indexV], at: interR)
                        indexV += 1
                        interR += 1
                        if sumTimes > Int(myLists[0].idFreq)*2 {
                            sumTimes = Int((myLists[0].idFreq*2) - 1)
                        }
                        sumTimes = sumTimes - Int(myLists[0].idFreq*60)
                    }
                } while indexV < voiceCollection.count
                queueArrays.myList.removeSubrange(interR + 10..<queueArrays.myList.count)
                currentList.textColor = .green
                playListName = myLists[0].playListName!
                currentList.text = "Queued Playlist: \(playListName) | ID Artist: \(idArtist)"
                sepIndex.textColor = .green
                sepIndex.text = "Artist separation: \(Int(myLists[0].sepNum)) songs\nID separation: \(Int(myLists[0].idFreq)) minutes"
                queueArrays.listResults = MPMediaItemCollection(items: queueArrays.myList)
                if myLists.count > 0 {
                    myLists.remove(at: 0)
                }
            }
            else {
                currentList.textColor = .red
                currentList.text = "Song/voicer ratio is too low. Playlist cannot run"
            }
        }
    }
    func fetchAlbumPlaylist() {
        idArtist = myLists[0].idArtist!
        let predicate = MPMediaPropertyPredicate(value: "\(myLists[0].musicList!)",
                                                 forProperty: MPMediaPlaylistPropertyName,
                                                 comparisonType: .equalTo)
        queueArrays.myQuery.addFilterPredicate(predicate)
        let unixDate = Date(timeIntervalSinceReferenceDate: 0)
        let thisTime = Double(Int(myLists[0].lastTime)*(-3600))
        let lastTime = Date(timeIntervalSinceNow:thisTime)
        var collection = [MPMediaItem]()
        queueArrays.myList = [MPMediaItem]()
        if let songs = queueArrays.myQuery.items {
            collection = songs.filter { ($0.lastPlayedDate ?? unixDate) < lastTime as Date }
            if mp.playbackState != .stopped {
                queueArrays.myList = collection.filter{($0.persistentID != songData.pID)} //84.3
            }
            else {
                queueArrays.myList = collection
            }
        }
        queueArrays.myQuery.removeFilterPredicate(predicate)
        queueArrays.myList = queueArrays.myList.shuffled()
        var albumList = Array(repeating: "", count: Int(myLists[0].sepNum))
        for performer in queueArrays.myList {
            let album = performer.albumTitle ?? "No Album"
            if albumList.contains(where: album.contains) {
                if let index = queueArrays.myList.firstIndex(of: performer) {
                    queueArrays.myList.remove(at: index)
                }
            }
            else {
                albumList.removeLast()
                albumList.insert(album, at: 0)
            }
        }
        let voicerPredicate = MPMediaPropertyPredicate(value: "\(myLists[0].idList!)",
                                                       forProperty: MPMediaPlaylistPropertyName,
                                                       comparisonType: .equalTo)
        queueArrays.myQuery.addFilterPredicate(voicerPredicate)
        var voiceCollection = [MPMediaItem]()
        if let voicers = queueArrays.myQuery.items {
            voiceCollection = voicers.sorted{$0.lastPlayedDate ?? unixDate < $1.lastPlayedDate ?? unixDate}
        }
        queueArrays.myQuery.removeFilterPredicate(voicerPredicate)
        var interR = 0
        var indexV = 0
        if myLists[0].idFreq < 10 {
            if voiceCollection.count * Int(myLists[0].idFreq) > queueArrays.myList.count {
                currentList.textColor = .red
                currentList.text = "Song/voicer ratio is too low. Playlist cannot run"
            }
            else {
                repeat {
                    queueArrays.myList.insert(voiceCollection[indexV], at:interR)
                    interR += Int(myLists[0].idFreq) + 1
                    indexV += 1
                } while indexV < voiceCollection.count
                queueArrays.myList.removeSubrange(interR + Int(myLists[0].idFreq)..<queueArrays.myList.count)
                currentList.textColor = .green
                playListName = myLists[0].playListName!
                currentList.text = "Queued Playlist: \(playListName) | ID Artist: \(idArtist)"
                sepIndex.textColor = .green
                sepIndex.text = "Album separation: \(Int(myLists[0].sepNum)) songs\nID separation: \(Int(myLists[0].idFreq)) songs"
                queueArrays.listResults = MPMediaItemCollection(items: queueArrays.myList)
                if myLists.count > 0 {
                    myLists.remove(at: 0)
                }
            }
        }
        else {
            var times = [Int]()
            for timePlay in queueArrays.myList {
                let duration = Int(timePlay.playbackDuration)
                times.append(duration)
            }
            let sum = times.reduce(0, +)
            let trackRemaining = Int(songData.trackDuration) - Int(playTime())
            var sumTimes = Int(myLists[0].idFreq*60)  // 900
            let coEfficient = sumTimes*(voiceCollection.count + 2) // 9900
            sumTimes = sumTimes + trackRemaining // 1140 = sumTimes + 4 min
            var indexT = -1
            if sum > coEfficient { // 21600 > 9900
                repeat {
                    if sumTimes < Int(myLists[0].idFreq*60) { // 1140 > 15 vs 1140 > 900
                        indexT += 1 // step thru times
                        sumTimes += Int(times[indexT])
                        interR += 1 // step thru songs
                    }
                    else { //
                        queueArrays.myList.insert(voiceCollection[indexV], at: interR)
                        indexV += 1 // step thru voicers
                        interR += 1 // step thru songs
                        if sumTimes > Int(myLists[0].idFreq*120) { // if > 1800
                            sumTimes = Int((myLists[0].idFreq*120) - 1)
                        }
                        sumTimes = sumTimes - Int(myLists[0].idFreq*60) // 1140 - 900 = 240
                    }
                } while indexV < voiceCollection.count
                queueArrays.myList.removeSubrange(interR + 10..<queueArrays.myList.count)
                currentList.textColor = .green
                playListName = myLists[0].playListName!
                currentList.text = "Queued Playlist: \(playListName) | ID Artist: \(idArtist)"
                sepIndex.textColor = .green
                sepIndex.text = "Album separation: \(Int(myLists[0].sepNum)) songs\nID separation: \(Int(myLists[0].idFreq)) minutes"
                queueArrays.listResults = MPMediaItemCollection(items: queueArrays.myList)
                if myLists.count > 0 {
                    myLists.remove(at: 0)
                }
            }
            else {
                currentList.textColor = .red
                currentList.text = "Song/voicer ratio is too low. Playlist cannot run"
            }
        }
    }
    func fetchTheBlues() {
        let voicerPredicate = MPMediaPropertyPredicate(value: "\(myLists[0].idList!)",
                                                       forProperty: MPMediaPlaylistPropertyName,
                                                       comparisonType: .equalTo)
        queueArrays.myQuery.addFilterPredicate(voicerPredicate)
        var voiceCollection = [MPMediaItem]()
        let unixDate = Date(timeIntervalSinceReferenceDate: 0)
        if let voicers = queueArrays.myQuery.items {
            voiceCollection = voicers.sorted{$0.lastPlayedDate ?? unixDate < $1.lastPlayedDate ?? unixDate}
        }
        queueArrays.myQuery.removeFilterPredicate(voicerPredicate)
        let bluesPredicate = MPMediaPropertyPredicate(value: "\(myLists[0].musicList!)",
                                                 forProperty: MPMediaPlaylistPropertyName,
                                                 comparisonType: .equalTo)
        queueArrays.myQuery.addFilterPredicate(bluesPredicate)
        if queueArrays.myList != nil {
            queueArrays.myList.removeAll()
        }
        var collection = [MPMediaItem]()
        if let songs = queueArrays.myQuery.items {
            collection = songs
        }
        queueArrays.myQuery.removeFilterPredicate(bluesPredicate)
        collection.insert(voiceCollection[0], at: 0)
        queueArrays.listResults = MPMediaItemCollection(items: collection)
        currentList.textColor = .green
        playListName = myLists[0].playListName!
        currentList.text = "Queued Playlist: \(playListName) | ID Artist: \(idArtist)"
        sepIndex.textColor = .green
        sepIndex.text = "Separation component inactive"
        if myLists.count > 0 {
            myLists.remove(at: 0)
        }
    }
    @objc func dayStart(_ notification : NSNotification) {
        let date = Date()
        let calendar = Calendar.current
        let day = calendar.component(.weekday, from: date)
        dayFormatter.dateFormat = "e"
        let weekday = dayFormatter.weekdaySymbols[day-1]
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Playlist")
        fetchRequest.predicate = NSPredicate(format: "playDays CONTAINS %@", weekday)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "dateString", ascending: true)]
        let context = CoreDataManager.shared.mainContext
        do {
            myLists = try context.fetch(fetchRequest) as! [Playlist]
        }
        catch let error as NSError {
            print("Could not load data. \(error), \(error.localizedDescription)")
        }
        dateString = myLists[0].dateString!
    }
}
