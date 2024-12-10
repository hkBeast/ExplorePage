//
//  ExplorePageApp.swift
//  ExplorePage
//
//  Created by HKBeast on 09/12/24.
//

import SwiftUI

@main
struct ExplorePageApp: App {
    @StateObject private var imageCacheManager = ImageCacheManager()
    var body: some Scene {
        WindowGroup {
            ExplorePageView()
                .environmentObject(imageCacheManager)
        }
    }
}
