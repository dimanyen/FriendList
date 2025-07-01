//
//  SegmentModel.swift
//  FriendList
//
//  Created by Rita Huang on 2025/6/8.
//


struct SegmentModel: Hashable {
    let title: String
    // Rename to follow Swift naming convention.
    let isSelected: Bool
    let badgeCount: Int
}