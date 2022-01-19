//
//  Domain_Driven_MVVMTests.swift
//  Domain-Driven-MVVMTests
//
//  Created by Christian Leovido on 19/01/2022.
//

import XCTest
import Combine
@testable import Domain_Driven_MVVM

final class Domain_Driven_MVVMTests: XCTestCase {
    private var subscriptions: Set<AnyCancellable> = []

    func testFetchReceipts() throws {
        // Given
        let viewModel: ReceiptManagementViewModel = .init(client: .failing, analyticsClient: .mock)

        let expectation = expectation(description: "receipts should be filled")
        let expectedReceipts = [Receipt(id: UUID().uuidString, name: "Fancy receipt")]
        
        viewModel.client.fetchReceipts = {
            return Just(expectedReceipts)
                .setFailureType(to: ReceiptError.self)
                .eraseToAnyPublisher()
        }
        
        viewModel.analyticsClient.trackEvent = { _ in
            return Just(())
                .eraseToAnyPublisher()
        }
        
        // When
        viewModel.actions.send(.fetchReceipts)
        
        // Then
        viewModel.$receipts.sink(receiveValue: { newReceipts in
            if !newReceipts.isEmpty {
                XCTAssertEqual(newReceipts, expectedReceipts)
                expectation.fulfill()
            }
        })
            .store(in: &subscriptions)
        
        wait(for: [expectation], timeout: 0.1)
        
    }
    
    func testFetchReceiptsError() throws {
        // Given
        let viewModel: ReceiptManagementViewModel = .init(client: .failing, analyticsClient: .mock)
        
        let expectation = expectation(description: "should produce error")
        let expectedError = ReceiptError.message("Too many requests")
        
        viewModel.client.fetchReceipts = {
            Fail(error: expectedError)
                .eraseToAnyPublisher()
        }
        // When
        viewModel.actions.send(.fetchReceipts)
        
        // Then
        viewModel.$error.sink(receiveValue: { newError in
            if let newError = newError {
                XCTAssertEqual(newError, expectedError)
                XCTAssertEqual(newError.localizedDescription, "[ReceiptError] Too many requests")
                expectation.fulfill()
            }
        })
            .store(in: &subscriptions)
        
        wait(for: [expectation], timeout: 1)
    }

    func testCreateReceipt() throws {
        // Given
        let viewModel: ReceiptManagementViewModel = .init(client: .failing, analyticsClient: .mock)
        
        let expectation = expectation(description: "should create a new receipt")
        let expectedReceipt = Receipt(id: UUID().uuidString, name: "Fanciest receipt")
        
        viewModel.client.createReceipt = { receiptRequest in
            return Just(())
                .setFailureType(to: ReceiptError.self)
                .eraseToAnyPublisher()
        }
        
        viewModel.client.fetchReceipts = {
            return Just([expectedReceipt])
                .setFailureType(to: ReceiptError.self)
                .eraseToAnyPublisher()
        }
        
        // When
        viewModel.actions.send(.createReceipt(.init(name: "Fancy receipt")))
        
        // Then
        viewModel.$receipts.sink(receiveValue: { newReceipts in
            if !newReceipts.isEmpty {
                XCTAssertEqual(newReceipts, [expectedReceipt])
                expectation.fulfill()
            }
        })
            .store(in: &subscriptions)
        
        wait(for: [expectation], timeout: 1)
    }
    
    func testCreateReceiptError() throws {
        // Given
        let viewModel: ReceiptManagementViewModel = .init(client: .failing, analyticsClient: .mock)
        
        let expectedError = ReceiptError.message("Error 500")
        
        viewModel.client.createReceipt = { receiptRequest in
            Fail(error: expectedError)
                .eraseToAnyPublisher()
        }
        
        // When
        viewModel.actions.send(.createReceipt(.init(name: "Fancy receipt")))
        
        // Then
        XCTAssertEqual(viewModel.error, expectedError)
    }
    
    func testFetchReceiptsErrorShowingAlert() throws {
        // Given
        let viewModel: ReceiptManagementViewModel = .init(client: .failing, analyticsClient: .mock)
        let expectedError = ReceiptError.message("No internet connection mocked")
        
        viewModel.client.fetchReceipts = {
            Fail(error: expectedError)
                .eraseToAnyPublisher()
        }
        
        // When
        viewModel.actions.send(.fetchReceipts)
        
        // Then
        viewModel.error = expectedError
        XCTAssertEqual(viewModel.isErrorPresented, true)
    }
    
    func testFetchReceiptsErrorDismissAlert() throws {
        // Given
        let viewModel: ReceiptManagementViewModel = .init(client: .failing, analyticsClient: .mock)
        let expectedError = ReceiptError.message("No internet connection mocked")
        
        viewModel.client.fetchReceipts = {
            Fail(error: expectedError)
                .eraseToAnyPublisher()
        }
        
        // When
        viewModel.actions.send(.fetchReceipts)
        
        // Then
        viewModel.error = expectedError
        
        XCTAssertEqual(viewModel.isErrorPresented, true)
        viewModel.actions.send(.dismissErrorAlert)
        XCTAssertEqual(viewModel.isErrorPresented, false)
    }
}
