//
//  Request.swift
//  Domain-Driven-MVVM
//
//  Created by Christian Leovido on 19/01/2022.
//

import Foundation

public enum Constants {
    static let baseURL = URL(string: "https://domain.com/receipts")!
}

public struct ReceiptRequest: Codable {
    let name: String
}

public struct Receipt: Identifiable, Hashable, Decodable {
    public let id: String
    public let name: String
}

public enum URLMethod {
    case GET
    case POST
    case PUT
    case DELETE
}
