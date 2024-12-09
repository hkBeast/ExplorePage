//
//  APIHandler.swift
//  ExplorePage
//
//  Created by HKBeast on 09/12/24.
//

import SwiftUI
class ApIHandler{
    
    func loadJSON<T: Codable>(from filename: String, as type: T.Type = T.self) throws -> T? {
        // Get the file URL from the app's bundle
        guard let url = Bundle.main.url(forResource: filename, withExtension: "json") else {
            throw ErrorHandler.FileNotFound
            
        }

        do {
            // Load the data from the file
            let data = try Data(contentsOf: url)
            
            // Decode the JSON data into the model type
            let decoder = JSONDecoder()
            let decodedData = try decoder.decode(T.self, from: data)
            
            return decodedData
        } catch {
            throw ErrorHandler.DecodingError
        }
    }

}

enum ErrorHandler:Error{
    case DecodingError
    case FileNotFound
}



class ViewModel : ObservableObject{
    @Published var responseData:Response?
    @Published var filterData:[ExploreData]?
    var isDataAvilable :Bool = true
    let apiHandler = ApIHandler()
    
    
    init() {
        fetchData()
    }
    
    func fetchData() {
        do {
            isDataAvilable = true
            // Attempt to load the JSON data as a specific model type (e.g., JourneyProgress)
            if let data: Response = try apiHandler.loadJSON(from: "data") {
                responseData = data
                // Handle the successful data loading here
            }
        } catch ErrorHandler.FileNotFound {
            isDataAvilable = false
            print("Error: The file could not be found.")
        } catch ErrorHandler.DecodingError {
            isDataAvilable = false
            print("Error: Failed to decode the JSON data.")
        } catch {
            isDataAvilable = false
            print("An unknown error occurred: \(error.localizedDescription)")
        }
    }
    
    
    func fetchDatawhere(filterSet: Set<String>?) {
        if (filterSet?.contains("All") == true) {
            // Fetch all data if allData is true or "All" is in the filterSet
            isDataAvilable = true
            filterData = responseData?.data
        } else {
            // Handle cases where specific filters are applied
            guard let filters = filterSet, !filters.isEmpty else {
                // If filters are nil or empty, return no data
                isDataAvilable = false
                filterData = nil
                return
            }
            
            // Filter the response data based on the provided filters
            isDataAvilable = true
            let filteredData = responseData?.data.filter { data in
                // Check if any of the problems match the filter criteria
                !data.problems.filter { filters.contains($0) }.isEmpty
            }
            filterData = filteredData
        }
    }

}
