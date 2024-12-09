//
//  ExplorePage.swift
//  ExplorePage
//
//  Created by HKBeast on 09/12/24.
//

import SwiftUI

struct ExplorePageView: View {
    @StateObject var viewModel = ViewModel()
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header Section with Explore Title and Icon Buttons
            HeaderView()
                .padding(.horizontal)

            // Discover Section
            DiscoverView()
                .environmentObject(viewModel)
        }
        .padding(.vertical, 10)
        .background(Color.black)
    }
}

// MARK: - Header View
struct HeaderView: View {
    var body: some View {
        HStack {
            Text("Explore")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.white)
            Spacer()
            HStack {
                IconButton(systemName: "heart.fill")
                IconButton(systemName: "music.note")
            }
        }
    }
}





// MARK: - Icon Button View
struct IconButton: View {
    let systemName: String
    
    var body: some View {
        Image(systemName: systemName)
            .font(.title2)
            .foregroundColor(.white)
            .padding()
            .background(Color.gray.opacity(0.3))
            .clipShape(Circle())
    }
}

// MARK: - Preview
struct ExplorePageView_Previews: PreviewProvider {
    static var previews: some View {
        ExplorePageView()
    }
}
