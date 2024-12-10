//
//  SearchView.swift
//  ExplorePage
//
//  Created by HKBeast on 09/12/24.
//

import SwiftUI
import Combine

// MARK: - Search Bar View
struct SearchBar: View {
    @StateObject var viewModel = SearchViewModel() // Initialize the view model
    @EnvironmentObject var appViewModel : AppViewModel
    
    
    var body: some View {
        HStack {
            // Magnifying glass icon with padding
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray) // Use gray to keep it subtle
                .padding(.leading, 12)
            
            // TextField for search text
            TextField("Search...", text: $viewModel.query)
                .padding(8)
                .foregroundColor(.white)
                .accentColor(.white) // To change the cursor and selection color to white
            // Perform action when the search query is updated
                .onChange(of: viewModel.searchQuery) { newSearchQuery in
                    // Update the parent view with the new search query
                    appViewModel.fetchDataByString(filterString: newSearchQuery)
                }
            
        }
        .background(Color.gray.opacity(0.3)) // Background with slight opacity
        .cornerRadius(25) // Slightly rounded corners for a smoother look
        .frame(height: 40) // Fixed height for the search bar
        .padding(.horizontal) // Add padding on the horizontal sides
    }
}


// ViewModel to manage search logic with debouncing
class SearchViewModel: ObservableObject {
    @Published var query: String = "" { // Binds to the text field in the view
        didSet {
            debounceSearch()
        }
    }
    
    @Published var searchQuery: String = "" // Final search query after debouncing
    
    private var cancellable: AnyCancellable?
    
    init() {
        debounceSearch()
    }
    
    // Debounce the search query input
    private func debounceSearch() {
        cancellable?.cancel() // Cancel any previous subscription
        
        // Apply debounce logic
        cancellable = $query
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main) // 500ms debounce interval
            .sink { [weak self] query in
                self?.searchQuery = query // Update the final search query
            }
    }
}

//struct SearchView: View {
//    @StateObject var viewModel = SearchViewModel() // Initialize the view model
//    @EnvironmentObject var appViewModel : ViewModel
//
//    var body: some View {
//        VStack {
//            TextField("Search", text: $viewModel.query) // Bind text input to view model query
//                .backgroundStyle((Color.gray.opacity(0.3)))
//                .textFieldStyle(RoundedBorderTextFieldStyle())
//                .foregroundStyle(Color.gray.opacity(0.3))
//             
//              
//
//            // Perform action when the search query is updated
//            .onChange(of: viewModel.searchQuery) { newSearchQuery in
//                // Update the parent view with the new search query
//                appViewModel.fetchDataByString(filterString: newSearchQuery)
//            }
//        }
//        .padding()
//    }
//}

