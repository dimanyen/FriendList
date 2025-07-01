import Foundation
import Combine

class ApiService {
    static let shared = ApiService()
    // Base URL now comes from `NetworkConfig` for easier maintenance.
    private let baseURL = NetworkConfig.baseURL

    private init() {}

    func fetchUserData() -> AnyPublisher<[User], Error> {
        fetchData(from: "\(baseURL)/man.json")
            .decode(type: UserResponse.self, decoder: JSONDecoder())
            .map { $0.response }
            .eraseToAnyPublisher()
    }
    
    func fetchFriendList1() -> AnyPublisher<[Friend], Error> {
        fetchData(from: "\(baseURL)/friend1.json")
            .decode(type: FriendListResponse.self, decoder: JSONDecoder())
            .map { $0.response }
            .eraseToAnyPublisher()
    }

    func fetchFriendList2() -> AnyPublisher<[Friend], Error> {
        fetchData(from: "\(baseURL)/friend2.json")
            .decode(type: FriendListResponse.self, decoder: JSONDecoder())
            .map { $0.response }
            .eraseToAnyPublisher()
    }

    func fetchFriendListWithInvites() -> AnyPublisher<[Friend], Error> {
        fetchData(from: "\(baseURL)/friend3.json")
            .decode(type: FriendListResponse.self, decoder: JSONDecoder())
            .map { $0.response }
            .eraseToAnyPublisher()
    }

    func fetchEmptyFriendList() -> AnyPublisher<[Friend], Error> {
        fetchData(from: "\(baseURL)/friend4.json")
            .decode(type: FriendListResponse.self, decoder: JSONDecoder())
            .map { $0.response }
            .eraseToAnyPublisher()
    }

    private func fetchData(from urlString: String) -> AnyPublisher<Data, Error> {
        guard let url = URL(string: urlString) else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }

        return URLSession.shared.dataTaskPublisher(for: url)
            .tryMap { output in
                guard let response = output.response as? HTTPURLResponse, response.statusCode == 200 else {
                    throw URLError(.badServerResponse)
                }
                return output.data
            }
            .eraseToAnyPublisher()
    }
}
