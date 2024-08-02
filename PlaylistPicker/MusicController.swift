//
//  MusicController.swift
//  Playlist Picker
//
//  Created by Thomas Collette on 3/7/23.
//

import UIKit
import MediaPlayer

class MusicController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    var musicList = [MPMediaItem()]
    var tracksPlayed = 0
    var artist = ""
    var duration = 0.0
    @IBOutlet weak var musicTable: UITableView!
    @IBOutlet weak var editButton: UIButton!
    @IBOutlet weak var topButton: UIButton!
    @IBAction func didTapEdit(sender: UIButton!) {
        if musicTable.isEditing {
            musicTable.isEditing = false
            sender.setTitle("Show Controls", for: .normal)
            sender.titleLabel?.font = UIFont.boldSystemFont(ofSize: 17)
            sender.darkGreyRounded()
            let rowToScroll = IndexPath(row: tracksPlayed, section: 0)
            self.musicTable.selectRow(at: rowToScroll, animated: true, scrollPosition: .none)
        }
        else {
            musicTable.isEditing = true
            sender.litWhenEditing()
            sender.setTitle("Finish", for: .normal)
            sender.titleLabel?.font = UIFont.boldSystemFont(ofSize: 17)
        }
    }
    @IBAction func backToTop(sender: UIButton!) {
        scrollToRow()
        sender.titleLabel?.font = UIFont.boldSystemFont(ofSize: 17)
    }
    override func viewDidLoad(){
        super.viewDidLoad()
        musicTable.delegate = self
        musicTable.dataSource = self
        scrollToRow()
        editButton.darkGreyRounded()
        editButton.setTitle("Show Controls", for: .normal)
        editButton.titleLabel?.font = UIFont(name: "Helvetica-Bold", size: 17)
        topButton.darkGreyRounded()
        topButton.setTitle("Back to Top", for: .normal)
        topButton.titleLabel?.font = UIFont(name: "Helvetica-Bold", size: 17)
    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        musicList = musicTable.dataSource as? [MPMediaItem] ?? musicList
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return musicList.count
    }
    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        musicList.swapAt(sourceIndexPath.row, destinationIndexPath.row)
        musicTable.reloadData()
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView .cellForRow(at: indexPath)?.textLabel?.textColor = .red
    }
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            musicList.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        var config = cell.defaultContentConfiguration()
        let musicArray = MPMediaItemCollection(items: musicList)
        if indexPath.row < tracksPlayed {
            config.textProperties.color = .htwDarkBlueGrey
            config.secondaryTextProperties.color = .htwDarkBlueGrey
        }
        if indexPath.row == tracksPlayed {
            config.textProperties.color = .htwSelectedCell
            config.secondaryTextProperties.color = .htwSelectedCell
        }
        config.text = musicArray.items[indexPath.row].title
        artist = musicArray.items[indexPath.row].artist!
        duration = musicArray.items[indexPath.row].playbackDuration
        let trackDurationMinutes = Int(duration / 60)
        let trackDurationSeconds = Int(duration.truncatingRemainder(dividingBy: 60))
        config.secondaryText = "\(artist) - \(trackDurationMinutes):" + String(format: "%02d", trackDurationSeconds)
        cell.contentConfiguration = config
        return cell
    }
    func scrollToRow() {
        let rowToScroll = IndexPath(row: tracksPlayed, section: 0)
        self.musicTable.scrollToRow(at: rowToScroll, at: .top, animated: false)
        self.musicTable.selectRow(at: rowToScroll, animated: true, scrollPosition: .none)
    }
}

