//
//  SearchView.swift
//  ExplorePage
//
//  Created by HKBeast on 09/12/24.
//

import SwiftUI

// MARK: - Search Bar View
struct SearchBar: View {
    @Binding var searchText: String
    
    var body: some View {
        HStack {
            // Magnifying glass icon with padding
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray) // Use gray to keep it subtle
                .padding(.leading, 12)
            
            // TextField for search text
            TextField("Search...", text: $searchText)
                .padding(8)
                .foregroundColor(.white)
                .accentColor(.white) // To change the cursor and selection color to white
        }
        .background(Color.gray.opacity(0.3)) // Background with slight opacity
        .cornerRadius(25) // Slightly rounded corners for a smoother look
        .frame(height: 40) // Fixed height for the search bar
        .padding(.horizontal) // Add padding on the horizontal sides
    }
}
