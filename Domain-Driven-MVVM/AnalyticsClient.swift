//
//  AnalyticsProvider.swift
//  Domain-Driven-MVVM
//
//  Created by Christian Leovido on 19/01/2022.
//

import Foundation
import Combine

public struct AnalyticsClient {
    public var trackEvent: (String) -> AnyPublisher<Void, Never>
    
    static func updateServer(event: String) {
        // ...
    }
    
    public init(trackEvent: @escaping (String) -> AnyPublisher<Void, Never>) {
        self.trackEvent = trackEvent
    }
}

public extension AnalyticsClient {
    static let live: AnalyticsClient = .init(
        trackEvent: { event in
            Just(())
                .map({
                    updateServer(event: event)
                })
                .eraseToAnyPublisher()
        }
    )
    static let mock: AnalyticsClient = .init(
        trackEvent: { event in
            Just(())
                .eraseToAnyPublisher()
        }
    )
    static var failing: AnalyticsClient = .init(
        trackEvent: { _ in
            fatalError("AnalyticsClient.trackEvent not implemented")
        }
    )
}
