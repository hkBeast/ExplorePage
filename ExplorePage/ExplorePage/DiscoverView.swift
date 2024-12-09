//
//  DiscoverView.swift
//  ExplorePage
//
//  Created by HKBeast on 09/12/24.
//

import SwiftUI

// MARK: - Discover View
struct DiscoverView: View {
    @State private var searchText: String = ""
    @State private var selectedFilters: Set<String> = []
    @EnvironmentObject var viewModel: ViewModel
    
    private let filters = ["All", "Trending", "Latest", "Popular", "Recommended"]
    private let results = Array(1...20).map { "Item \($0)" }
    private let gridLayout = [GridItem(.flexible()), GridItem(.flexible())]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Discover Title
            Text("Discover")
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal)
            
            // Search Bar
            SearchBar(searchText: $searchText)
            
            // Filter Tabs
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    // "All" filter
                    FilterButton(text: "All", isSelected: selectedFilters.contains("All")) {
                        toggleFilter("All")
                    }
                    
                    // Other filters
                    if let filters = viewModel.responseData?.problemFilter {
                        ForEach(filters, id: \.self) { filter in
                            FilterButton(
                                text: filter.title,
                                isSelected: selectedFilters.contains(filter.title)
                            ) {
                                toggleFilter(filter.title)
                                viewModel.fetchDatawhere(filterSet: selectedFilters)
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }
            
            // Results Grid
            if viewModel.isDataAvilable{
                if let resultCardData = viewModel.filterData{
                    ScrollView {
                        LazyVGrid(columns: gridLayout, spacing: 16) {
                            
                            ForEach(resultCardData, id: \.self) { result in
                                ResultCard(cardData: result)
                            }
                        }
                        .padding(.horizontal)
                    }
                }else{
                    ScrollView {
                        LazyVGrid(columns: gridLayout, spacing: 16) {
                            
                            // show 6 grid items
                        }
                        .padding(.horizontal)
                    }
                }
            }else{
                // show No Data is avilable with empty box
            }
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
    
    // MARK: - Filtered Results
 
}

