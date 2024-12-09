//
//  ViewModel.swift
//  demoProject
//
//  Created by HKBeast on 27/11/24.
//

import UIKit

class ViewModel{
    
    var repository:Repository
    
    init(repository:Repository){
        self.repository = repository
    }
    func getSortedList(){
        if let array = repository.fetchDataFromServer(){
            
        }
        
    }
 
    
    
    
}

class Repository{
    func fetchDataFromServer()->[JSONDataModel]?{
        // get the data from the URL
        
     return nil
    }
}


func getSumofLongestContigenousSubarray(array:[Int])->Int{
    // check if array count is zero return 0
    // currentSum
    // maxSum
    // start
    // end
    //tempStart
    
    // for loop 1..<count oif array
    // if item is > currentSum+item
       // current sum = item
       // tempStart = indexOfItem
    //else
      // currentSum += item
    
    // if currentSum > maxSum
       // maxSum = currentSum
       // start = tempSum
        // end = indexOfItem
    
    //return maxSum
    
return 0
}

func getSumofLongestSubarray(array:[Int])->Int{
    // check if array count is zero return 0
    // currentSum
    // maxSum
 
    
    // for loop 1..<count oif array
      // currentSum = max(item,currentSum+item)
      // maxSum = max(currentSum,maxSum)
    //return maxSum
    
return 0
}


func getLongestSubArrayWithoutRepetation (array:[String])->Int{
    
    array.indices.forEach { right in
        
    }
    return 0
}

struct JsonModel:Decodable{
    let Id:Int
    let name:String
}

// Define a custom error for invalid URL
enum FetchError: Error {
    case invalidURL
    case decodingError
}

func fetchDataFrom(url:String)async throws->JsonModel?{
    guard let validURL = URL(string: url) else {
        throw FetchError.invalidURL
    }
    
    let (data,response) = try await URLSession.shared.data(from: validURL)
    
    if let res = response as? HTTPURLResponse, res.statusCode == 200 {
        
    }
    do {
        let model = try JSONDecoder().decode(JsonModel.self,from: data)
        return model
    }catch{
        throw FetchError.decodingError
    }
    

}

let user = User(id: 1, name: "John Doe", email: "john@example.com")

do {
    let encoder = JSONEncoder()
    encoder.keyEncodingStrategy = .convertToSnakeCase  // Optional: Convert keys to snake_case
    
    let jsonData = try encoder.encode(user)
    let jsonString = String(data: jsonData, encoding: .utf8)
    print(jsonString)  // {"id":1,"name":"John Doe","email":"john@example.com"}
} catch {
    print("Error encoding user: \(error)")
}

$moveModel{
    
    // check if moveModel have value
    
    // for each value in 0...moveModel[old]-1
    
          // check oldParent and newParent at same index is not same
    
               // check if rootview or current parent have view with tag oldParentID
    
                    // check if that item edit state is true
    
                         // remove View for that childID from parent
    
                  
    
    
    
    
    
                   // check if root view have view tag with parentID.parentID and it is draw
                        // change the baseFrame of view with tag parentID and it is not a page
                             // change all childs center of that Parent if parent is Edit
    
                               // add child at parentID view tag and it is edit
    
                                   // with given base frame and startTime and order
    
    
}

/*
Function changeParentOfModel(modelId, parentId, atNewIndex):
    Lock the operation to ensure thread safety

    Initialize `didSucceed` to `false`

    Retrieve the `model` for `modelId`
    If `model` is not found, try retrieving it as a `page`
    If still not found, return `null`

    Retrieve the `parentModel` for `parentId`
    If `parentModel` is not found, try retrieving it as a `page`
    If still not found, return `null`

    Get the dimensions of `model` as per the root (`modelRootDimensions`)
    Initialize an empty list `parentChangeInfos`
    Get the dimensions of `parentModel` as per the root (`parentRootDimensions`)

    If `parentModel` has no parent:
        Create `ParentChangeInfo` objects for `model` and `parentModel`
        Populate initial data for both using `loadData`

        Calculate the new dimensions of `model` relative to `parentModel`
        Update the parent of `model` to `parentModel` at `atNewIndex`
        Move `model` to its new position and update timing and duration

        Reload data for `model` and `parentModel`
        Add their `ParentChangeInfo` objects to `parentChangeInfos`
        Mark `didSucceed` as `true`

    Else:
        Create an array `parentChangeInfoArray` for the children of `parentModel` plus `model` and `parentModel`
        Populate initial data for all child models, `model`, and `parentModel` into the array using `loadData`

        Check if the new child can be accommodated in `parentModel`
        If successful:
            If `parentModel` has no existing children:
                Calculate the new dimensions of `parentModel` and move it
                Update timing and duration for `parentModel`

                Calculate new dimensions of `model` relative to `parentModel`
                Update the parent of `model` and move it to its new position
                Flip `model` if needed
                Mark `didSucceed` as `true`

            Else:
                For each existing child of `parentModel`:
                    Record its current dimensions in `childDimensions`

                Calculate new dimensions of `parentModel` with the new child
                Move and update timing for `parentModel`

                For each existing child:
                    Recalculate and move to its new position relative to `parentModel`

                Add the new `model`:
                    Calculate dimensions of `model` relative to `parentModel`
                    Update its parent and move it
                    Flip `model` if needed
                    Mark `didSucceed` as `true`

                Update the `ParentChangeInfo` objects for all affected models and add to `parentChangeInfos`

    If `didSucceed`:
        Return `parentChangeInfos`
    Else:
        Return `null`

*/
