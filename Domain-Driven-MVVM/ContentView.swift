//
//  ContentView.swift
//  Domain-Driven-MVVM
//
//  Created by Christian Leovido on 19/01/2022.
//

import SwiftUI
import Combine

public struct ContentView: View {
    @ObservedObject var viewModel: ReceiptManagementViewModel = .init()
    
    public var body: some View {
        NavigationView {
            VStack {
                List {
                    ForEach(viewModel.receipts) { receipt in
                        Text(receipt.name)
                    }
                }
            }
            .alert(
                isPresented: $viewModel.isErrorPresented,
                error: viewModel.error,
                actions: {
                    Button("OK") {
                        viewModel.actions.send(.dismissErrorAlert)
                    }
                })
            .onAppear() {
                viewModel.actions.send(.fetchReceipts)
            }
            .navigationTitle(Text("My Receipts"))
        }
    }
}

public struct ContentView_Preview: PreviewProvider {
    public static var previews: some View {
        ContentView(viewModel: .init(client: .mock, analyticsClient: .mock))
    }
}
