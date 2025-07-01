//
//  FriendListTests.swift
//  FriendListTests
//
//  Created by Rita Huang on 2025/6/4.
//

import XCTest
@testable import FriendList

final class FriendListTests: XCTestCase {

    func testMergeSelectsLatestFriend() {
        let vm = FriendViewModel(type: .friendsOnly)
        let old = Friend(status: .finish, name: "Bob", isTop: "0", fid: "001", updateDate: "20190101")
        let new = Friend(status: .finish, name: "Bob", isTop: "0", fid: "001", updateDate: "20190201")
        let result = vm.merge([old], [new])
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.updateDate, "20190201")
    }

    func testMergeSkipsInviting() {
        let vm = FriendViewModel(type: .friendsOnly)
        let inviting = Friend(status: .inviting, name: "Sam", isTop: "0", fid: "002", updateDate: "20190102")
        let result = vm.merge([], [inviting])
        XCTAssertTrue(result.isEmpty)
    }

}
