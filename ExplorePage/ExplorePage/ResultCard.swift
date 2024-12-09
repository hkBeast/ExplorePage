//
//  ResultCard.swift
//  ExplorePage
//
//  Created by HKBeast on 09/12/24.
//


// MARK: - Result Card View
import SwiftUI

struct ResultCard: View {
    var cardData: ExploreData
    
    @State private var showShimmer: Bool = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            VStack {
                    // Async Image
                    AsyncImage(url:URL(string:  cardData.thumbImage)) { image in
                        image
                            .resizable()
                            .frame(height: 150)
                            .clipped()
                            .cornerRadius(10)
                    } placeholder: {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(.systemGray5))
                            .frame(height: 150)
                            .shimmerEffect(active: true)
                    }
                }
            
            // Title and Description
            VStack(alignment: .leading, spacing: 5) {
                Text(cardData.title)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(Color.white)
                
                HStack {
                    Text(cardData.sessions)
                        .font(.subheadline)
                        .foregroundColor(Color.gray)
                    Spacer()
                    Text(cardData.description)
                        .font(.subheadline)
                        .foregroundColor(Color.gray)
                }
            }
            .padding()
        }
        .cornerRadius(10)
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 3)
      
    }
}


extension View {
    func shimmerEffect(active: Bool) -> some View {
        self.overlay(
            active ?
            ShimmerView()
                .mask(self)
            : nil
        )
    }
}

struct ShimmerView: View {
    @State private var startPoint: UnitPoint = .leading
    @State private var endPoint: UnitPoint = .trailing
    @State private var animationActive: Bool = true
    
    var body: some View {
        LinearGradient(
            gradient: Gradient(colors: [Color.white.opacity(0.3), Color.white.opacity(0.7), Color.white.opacity(0.3)]),
            startPoint: startPoint,
            endPoint: endPoint
        )
        .onAppear {
            startAnimation()
        }
        .onDisappear {
            stopAnimation()
        }
    }
    
    private func startAnimation() {
        animationActive = true
        withAnimation(Animation.linear(duration: 1.5).repeatForever(autoreverses: false)) {
            startPoint = .trailing
            endPoint = .leading
        }
    }
    
    private func stopAnimation() {
        animationActive = false
    }
}


