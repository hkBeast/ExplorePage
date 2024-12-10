//
//  DiscoverView.swift
//  ExplorePage
//
//  Created by HKBeast on 09/12/24.
//

import SwiftUI

// MARK: - Discover View
struct DiscoverView: View {
    @State private var selectedFilters: Set<String> = []
    @EnvironmentObject var viewModel: AppViewModel
  
    private let gridLayout = [GridItem(.flexible()), GridItem(.flexible())]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Discover Title
            Text("Discover")
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal)
            
            // Search Bar
            SearchBar()
                .environmentObject(viewModel)
                .frame(height: 60)
            
            // Filter Tabs
            FilterTabsView(
                selectedFilters: $selectedFilters,
                responseFilters: viewModel.responseData?.problemFilter,
                onFilterChange: { viewModel.fetchDatawhere(filterSet: selectedFilters) }
            )
            
            // Display state views
            if viewModel.loadingState {
                LoadingView()
            } else if !viewModel.filterData.isEmpty {
                ResultsGridView(resultCardData: viewModel.filterData, gridLayout: gridLayout, isPremiumUser: false)
            } else {
                NoDataView()
            }
        }
    }
}



struct FilterTabsView: View {
    @Binding var selectedFilters: Set<String>
    var responseFilters: [FilterModel]?
    var onFilterChange: () -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                // "All" filter
                FilterButton(text: "All", isSelected: selectedFilters.contains("All")) {
                    toggleFilter("All")
                    onFilterChange()
                }
                
                // Other filters
                if let filters = responseFilters {
                    ForEach(filters, id: \.self) { filter in
                        FilterButton(
                            text: filter.title,
                            isSelected: selectedFilters.contains(filter.title)
                        ) {
                            toggleFilter(filter.title)
                            onFilterChange()
                        }
                    }
                }
            }
            .padding(.horizontal)
        }
    }
    
    // MARK: - Toggle Filter
    private func toggleFilter(_ filter: String) {
        if filter == "All" {
            // Deselect all filters and select "All" if "All" is selected
            if selectedFilters.contains("All") {
                selectedFilters.removeAll()
            } else {
                selectedFilters = ["All"]
            }
        } else {
            // Handle multi-select logic for other filters
            if selectedFilters.contains("All") {
                selectedFilters.remove("All")
            }
            
            if selectedFilters.contains(filter) {
                selectedFilters.remove(filter)
            } else {
                selectedFilters.insert(filter)
            }
        }
    }
}

struct ResultsGridView: View {
    var resultCardData: [ExploreData]
    var gridLayout: [GridItem]
    var isPremiumUser :Bool

    var body: some View {
        ScrollView {
            LazyVGrid(columns: gridLayout, spacing: 16) {
                ForEach(resultCardData, id: \.self) { result in
                    ResultCard(cardData: result, isPremium: isPremiumUser)
                        .frame(width: 200)
                }
            }
            .padding(.horizontal)
        }
    }
}
struct LoadingView: View {
    var body: some View {
        VStack {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle())
            Text("Loading...")
                .foregroundColor(.gray)
                .font(.subheadline)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct NoDataView: View {
    var body: some View {
        VStack {
            Image(systemName: "tray")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .foregroundColor(.gray)
            Text("No Data Available")
                .font(.headline)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
