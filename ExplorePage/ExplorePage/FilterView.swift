//
//  FilterView.swift
//  ExplorePage
//
//  Created by HKBeast on 09/12/24.
//

import SwiftUI
// MARK: - Filter Button View
struct FilterButton: View {
    let text: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        HStack(spacing: 4) { // Minimal gap between text and checkmark
            Text(text)
                .padding(.vertical, 8) // Vertical padding for the text
                .padding(.leading, 8) // Padding on the left side of text
                .padding(.trailing, 8) // Padding between text and checkmark

            // Checkmark Image when selected
            if isSelected {
                Image(systemName: "checkmark")
                    .foregroundColor(.white) // Color of the checkmark
                    .padding(.trailing, 12) // Padding on the right side of the checkmark
            }
        }
        .background(Color.gray.opacity(0.3))
        .foregroundColor(.white)
        .cornerRadius(25) // Fully rounded corners
        .onTapGesture {
            action()
        }
    }
}
