//
//  AppViewModel.swift
//  ExplorePage
//
//  Created by HKBeast on 10/12/24.
//

import SwiftUI

class AppViewModel: ObservableObject {
    @Published var responseData: Response?
    @Published var filterData: [ExploreData] = []
    @Published var loadingState = false
    @Published var isInternetAvilable = true
    @Published var currentPage = 1
    @Published var totalPages = 1

    let apiHandler = ApIHandler()

    init() {
        fetchData()
    }

    func fetchData() {
        do {
            loadingState = true
            // Attempt to load the JSON data as a specific model type (e.g., JourneyProgress)
            if let data: Response = try apiHandler.loadJSON(from: "data") {
                responseData = data
                loadingState = false
                
                // Handle the successful data loading here
            }
        } catch ErrorHandler.FileNotFound {
          
            print("Error: The file could not be found.")
        } catch ErrorHandler.DecodingError {
         
            print("Error: Failed to decode the JSON data.")
        } catch {
            
            print("An unknown error occurred: \(error.localizedDescription)")
        }
    }
    

    func loadNextPage() {
        guard currentPage < totalPages, !loadingState else { return }
        currentPage += 1
        fetchData()
    }

    func fetchDatawhere(filterSet: Set<String>?) {
        if filterSet?.contains("All") == true {
            loadingState = true
            filterData = responseData?.data ?? []
            loadingState = false
        } else {
            loadingState = true
            filterData = responseData?.data.filter { item in
                guard let filters = filterSet else { return false }
                return !item.problems.filter { filters.contains($0) }.isEmpty
            } ?? []
            loadingState = false
             
        }
    }
    
    func fetchDataByString(filterString: String) {
        // Fetch all data if filterString is "All"
        loadingState = true
        if filterString.lowercased() == "all" || filterString.isEmpty {
           
            filterData = responseData?.data ?? []
            loadingState = false
        } else {
            // Filter the response data based on the provided string
            
            let filteredData = responseData?.data.filter { data in
                // Check if any problem contains the filterString (case-insensitive)
                data.problems.contains { $0.lowercased().contains(filterString.lowercased()) }
            }
            filterData = filteredData ?? []
            loadingState = false
        }
    }
}
