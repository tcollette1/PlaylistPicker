//
//  Styles.swift
//  PlaylistPicker
//
//  Created by Thomas Collette on 7/14/21.
//

import UIKit

extension UIView {
    func fadedGray() {
        self.backgroundColor = UIColor.htwMainActiveDisabled
        self.layer.cornerRadius = 16
    }
    
    func orangeWarned() {
        self.backgroundColor = UIColor.htwMainActive
    }
}
extension UIButton {
    func darkGreyRounded() {
        self.backgroundColor = UIColor.htwDarkBlueGrey
        self.layer.cornerRadius = 16
    }
    func litWhenEditing() {
        self.backgroundColor = UIColor.htwMainActiveEditing
        self.layer.cornerRadius = 16
    }
}
