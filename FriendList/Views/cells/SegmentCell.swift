//
//  SegmentCell.swift
//  FriendList
//
//  Created by Rita Huang on 2025/6/8.
//


import UIKit

class SegmentCell: BaseCollectionViewCell {
    @IBOutlet weak var viewHighlight: UIView!
    @IBOutlet weak var viewBadge: UIView!
    @IBOutlet weak var lblBadge: UILabel!
    
    func configure(_ model: SegmentModel) {
        lblTitle.text = model.title
        lblTitle.font = model.isSelected ? .boldSystemFont(ofSize: 13.0) : .systemFont(ofSize: 13.0)
        viewHighlight.isHidden = !model.isSelected
        lblBadge.text = (model.badgeCount > 98) ? "99+" : "\(model.badgeCount)"
        viewBadge.isHidden = model.badgeCount == 0
    }
}
