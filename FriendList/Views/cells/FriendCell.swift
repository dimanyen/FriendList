//
//  FriendCell.swift
//  FriendList
//
//  Created by Rita Huang on 2025/6/8.
//


import UIKit

class FriendCell: BaseCollectionViewCell {
    @IBOutlet weak var btnMore: UIButton!
    @IBOutlet weak var btnInvite: UIButton!
    
    func configure(with friend: Friend) {
        lblTitle.text = friend.name
        imgView.isHidden = !friend.isTopFriend()
        // Check status with enum directly after refactoring `Friend.status`.
        btnInvite.isHidden = friend.status != .invited
        btnMore.isHidden = !btnInvite.isHidden
        btnAction.layer.borderColor = btnAction.tintColor.cgColor
        btnAction.layer.borderWidth = 1.0
        btnAction.setTitle("轉帳", for: .normal)
        if btnInvite.isHidden {
            btnInvite.setTitle("", for: .normal)
        } else {
            btnInvite.setTitle("邀請中", for: .normal)
            btnInvite.layer.borderColor = btnInvite.tintColor.cgColor
            btnInvite.layer.borderWidth = 1.0
        }
    }
}