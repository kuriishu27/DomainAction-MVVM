//
//  Client.swift
//  Domain-Driven-MVVM
//
//  Created by Christian Leovido on 19/01/2022.
//

import Foundation
import Combine

public func createURLRequest(url: URL, endpoint: String, params: [String: Any], method: URLMethod) -> URLRequest {
    var request = URLRequest(url: Constants.baseURL.appendingPathComponent(endpoint))
    request.httpBody = try! JSONSerialization.data(withJSONObject: params, options: [])
    request.httpMethod = "POST"
    
    return request
}

public struct Client {
    public var createReceipt: (ReceiptRequest) -> AnyPublisher<Void, ReceiptError>
    public var fetchReceipts: () -> AnyPublisher<[Receipt], ReceiptError>
    
    public init(createReceipt: @escaping (ReceiptRequest) -> AnyPublisher<Void, ReceiptError>,
                fetchReceipts: @escaping () -> AnyPublisher<[Receipt], ReceiptError>) {
        self.createReceipt = createReceipt
        self.fetchReceipts = fetchReceipts
    }
}

public extension Client {
    static let live: Client = .init(
        createReceipt: { receiptRequest in
            
            guard let data = try? JSONEncoder().encode(receiptRequest),
                  let params = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
                return Fail(error: ReceiptError.message("invalid")).eraseToAnyPublisher()
            }
            
            let request = createURLRequest(url: Constants.baseURL, endpoint: "create", params: params, method: .POST)
            
            return URLSession.shared.dataTaskPublisher(for: request)
                .map(\.response)
                .map({ response in
            guard let response = response as? HTTPURLResponse, (200...399) ~= response.statusCode else {
                return
            }
                return
            })
                .mapError({ ReceiptError.message($0.localizedDescription) })
                .eraseToAnyPublisher()
        },
        fetchReceipts: {
            URLSession.shared.dataTaskPublisher(for: URL(string: "https://example.com/")!)
                .map(\.data)
                .decode(type: [Receipt].self, decoder: JSONDecoder())
                .mapError({ ReceiptError.message($0.localizedDescription) })
                .eraseToAnyPublisher()
        })
    
    static var mock: Client = .init(
        createReceipt: { receiptRequest in
            Just(())
                .setFailureType(to: ReceiptError.self)
                .eraseToAnyPublisher()
        },
        fetchReceipts: {
            Just([
                Receipt(
                    id: UUID().uuidString,
                    name: "Test receipt \(Int.random(in: 0...1_000))"
                ),
                Receipt(
                    id: UUID().uuidString,
                    name: "Test receipt \(Int.random(in: 0...1_000))"
                ),
                Receipt(
                    id: UUID().uuidString,
                    name: "Test receipt \(Int.random(in: 0...1_000))"
                ),
                Receipt(
                    id: UUID().uuidString,
                    name: "Test receipt \(Int.random(in: 0...1_000))"
                )
            ])
                .setFailureType(to: ReceiptError.self)
                .eraseToAnyPublisher()
        })
    
    static var failing: Client = .init(
        createReceipt: { receiptRequest in
            fatalError("Client.createRequest not implemented")
        },
        fetchReceipts: {
            fatalError("Client.fetchRequests not implemented")
        })
}
