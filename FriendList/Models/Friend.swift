import Foundation

// Use `Codable` enum to represent friend status instead of raw integers.
// This improves type safety when decoding JSON data.
enum StatusType: Int, Codable {
    case invited, finish, inviting
}

struct FriendListResponse: Codable {
    let response: [Friend]
}

struct Friend: Codable, Hashable {
    // Replace `Int` with strongly typed `StatusType` for better readability.
    let status: StatusType
    let name: String
    let isTop: String // "0", "1"
    let fid: String // "001"
    let updateDate: String //"2019/08/02" or "20190804"
    
    func isTopFriend() -> Bool {
        return isTop == "1"
    }
}
