//
//  RequestManagementViewModel.swift
//  Domain-Driven-MVVM
//
//  Created by Christian Leovido on 19/01/2022.
//

import Foundation
import Combine

public enum ReceiptAction {
    case fetchReceipts
    case createReceipt(ReceiptRequest)
    case dismissErrorAlert
}

extension ReceiptAction: CustomStringConvertible {
    public var description: String {
        switch self {
        case .dismissErrorAlert:
            return "DomainAction.dismissErrorAlert"
        case let .createReceipt(request):
            return "DomainAction.createReceipt [\(request)]"
        case .fetchReceipts:
            return "DomainAction.fetchReceipts"
        }
    }
}

public enum ReceiptError: Hashable, Error {
    case message(String)
}

extension ReceiptError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case let .message(description):
            return "[ReceiptError] \(description)"
        }
    }
}

public final class ReceiptManagementViewModel: ObservableObject {
    public var client: Client
    public var analyticsClient: AnalyticsClient
    
    // Inputs
    public let actions: PassthroughSubject<ReceiptAction, Never>
    
    // Outputs
    @Published public var receipts: [Receipt] = []
    @Published public var error: ReceiptError?
    @Published public var isErrorPresented: Bool = false
    
    public private(set) var subscriptions: Set<AnyCancellable> = []
    
    public init(client: Client = .live,
                analyticsClient: AnalyticsClient = .live) {
        self.client = client
        self.analyticsClient = analyticsClient
        self.receipts = .init([])
        self.actions = PassthroughSubject()
        
        setupSubscriptions()
    }
    
    private func setupSubscriptions() {
        
        let sharedPublisher = actions.share()
        
        // - MARK: Subscriber for Analytics
        sharedPublisher
            .map(\.description)
            .flatMap(analyticsClient.trackEvent)
            .sink { _ in }
            .store(in: &subscriptions)
        
        $error.sink { newError in
            self.isErrorPresented = true
        }
        .store(in: &subscriptions)
        
        // - MARK: Subscriber for Reducer
        sharedPublisher.sink { [weak self] action in
            guard let self = self else {
                return
            }
            
            switch action {
            case .dismissErrorAlert:
                self.isErrorPresented = false
            case .fetchReceipts:
                self.client.fetchReceipts()
                    .print()
                    .receive(on: DispatchQueue.main)
                    .sink(receiveCompletion: { result in
                        switch result {
                        case let .failure(error):
                            self.error = error
                        case .finished: break
                        }
                    }, receiveValue: { newRequests in
                        self.receipts = newRequests
                    })
                    .store(in: &self.subscriptions)
            case let .createReceipt(receiptRequest):
                self.client.createReceipt(receiptRequest)
                    .print()
                    .sink(receiveCompletion: { result in
                        switch result {
                        case let .failure(error):
                            self.error = error
                        case .finished: break
                        }
                    }, receiveValue: { newRequests in
                        self.actions.send(.fetchReceipts)
                    })
                    .store(in: &self.subscriptions)
            }
        }
        .store(in: &subscriptions)
    }
}
