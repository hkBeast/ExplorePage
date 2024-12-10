//
//  ResultCard.swift
//  ExplorePage
//
//  Created by HKBeast on 09/12/24.
//


// MARK: - Result Card View
import SwiftUI
import Kingfisher
import SwiftUI
import Kingfisher

struct ImageStateView: View {
    var imageUrl: String? // The URL for the image to load
    var image: UIImage? // Optional image for fallback (cached)
    var imageLoadFailed: Bool
    var retryCount: Int
    var maxRetryAttempts: Int
    var retryImageLoad: (() -> Void)
    
    var body: some View {
        Group {
            if let image = image, !imageLoadFailed {
                // If image is available and loading has not failed, show the cached image
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 150)
                    .clipped()
                    .cornerRadius(10)
            } else if imageLoadFailed {
                // Show fallback content with retry button if loading failed
                VStack {
                    Image(systemName: "photo.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 50, height: 50)
                        .foregroundColor(.gray)
                    if retryCount < maxRetryAttempts {
                        Button("Retry") {
                            retryImageLoad()
                        }
                        .padding(.top, 8)
                        .buttonStyle(BorderedButtonStyle())
                    }
                }
                .frame(height: 150)
                .cornerRadius(10)
                .background(Color.gray.opacity(0.3))
            } else if let imageUrl = imageUrl {
                // If no image is available, load from URL using Kingfisher
                KFImage(URL(string: imageUrl))
                    .onSuccess { result in
                        // Image loaded successfully, cache it if needed
                        self.image = result.image
                    }
                    .onFailure { error in
                        // Handle image loading failure
                        self.imageLoadFailed = true
                        print("Error loading image: \(error.localizedDescription)")
                    }
                    .resizable()
                    .scaledToFit()
                    .frame(height: 150)
                    .clipped()
                    .cornerRadius(10)
            } else {
                // Loading state (show placeholder or processing state)
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .frame(height: 150)
                    .cornerRadius(10)
                    .background(Color.gray.opacity(0.3))
            }
        }
    }
}


struct LockButtonView: View {
    var isPremium: Bool
    
    var body: some View {
        if isPremium {
            VStack {
                Spacer()
                HStack {
                    Image(systemName: "lock.fill")
                        .resizable()
                        .frame(width: 30, height: 30)
                        .foregroundColor(.white)
                        .padding(10)
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(15)
                    Spacer()
                }
                Spacer()
            }
            .padding([.bottom, .leading], 10)
        }
    }
}


struct ResultCard: View {
    var cardData: ExploreData
    var isPremium: Bool // Add this property to track if the card is premium
    
    @State private var cachedImage: UIImage? = nil
    @State private var imageLoadFailed: Bool = false
    @State private var retryCount: Int = 0
    
    private let imageCache = ImageCache.default
    private let retryInterval: TimeInterval = 5 // Interval for retrying in seconds
    private let maxRetryAttempts = 3 // Max number of retry attempts

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            GeometryReader { geometry in
                VStack {
                    ZStack {
                        // ImageStateView to handle image loading states
                        ImageStateView(
                            image: cachedImage,
                            imageLoadFailed: imageLoadFailed,
                            retryCount: retryCount,
                            maxRetryAttempts: maxRetryAttempts,
                            retryImageLoad: retryImageLoad
                        )
                        .frame(width: geometry.size.width)
                        
                        // LockButtonView to show lock button if it's premium
                        LockButtonView(isPremium: isPremium)
                    }
                }
            }
            .frame(height: 150)

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

    private func retryImageLoad() {
        guard retryCount < maxRetryAttempts else {
            return // Prevent further retries after max attempts
        }

        // Reset the state
        imageLoadFailed = false
        retryCount += 1

        // Retry after a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + retryInterval) {
            KFImage(URL(string: cardData.thumbImage))
                .onSuccess { result in
                    cachedImage = result.image
                    imageCache.store(result.image, forKey: cardData.thumbImage)
                    imageLoadFailed = false
                    retryCount = 0
                }
                .onFailure { error in
                    imageLoadFailed = true
                    print("Retry failed: \(error.localizedDescription)")
                }
                .resizable()
                .scaledToFill()
                .frame(width: UIScreen.main.bounds.width, height: 150)
                .clipped()
                .cornerRadius(10)
        }
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



class ImageCacheManager: ObservableObject {
    private var imageCache = NSCache<NSURL, UIImage>()
    
    func getCachedImage(for url: URL) -> UIImage? {
        return imageCache.object(forKey: url as NSURL)
    }
    
    func cacheImage(_ image: UIImage, for url: URL) {
        imageCache.setObject(image, forKey: url as NSURL)
    }
    
    func clearCache() {
        imageCache.removeAllObjects()
    }
}


