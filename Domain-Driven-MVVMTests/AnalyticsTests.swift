//
//  AnalyticsTests.swift
//  Domain-Driven-MVVMTests
//
//  Created by Christian Leovido on 19/01/2022.
//

import XCTest
import Combine
@testable import Domain_Driven_MVVM

final class AnalyticsTests: XCTestCase {
    private var subscriptions: Set<AnyCancellable> = []

    func testAnalytics() throws {
        
        var analyticsClient: AnalyticsClient = .failing
        analyticsClient.trackEvent = { event in
            Just(())
                .eraseToAnyPublisher()
        }
        
        let viewModel: ReceiptManagementViewModel = .init(client: .mock, analyticsClient: analyticsClient)
        
        viewModel.actions.send(.fetchReceipts)
    }
}
