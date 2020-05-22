//
//  SettingsManager.swift
//  Hawadaar
//
//  Created by Muhammad Ahmed Bappi on 16/05/2020.
//  Copyright © 2020 Muhammad Ahmed Bappi. All rights reserved.
//

import UIKit

protocol SettingsManagerDelegate {
    func didFailWithError(_ settingsManager: SettingsManager, error: Error)
    func didServerResponse(_ settingsManager: SettingsManager, data: String)
}

struct SettingsManager {
    var delegate : SettingsManagerDelegate?
    
    let sections = ["Set Point mode", "PMV mode"]
    let numOfRows = [1, 3]
    
    let sectionLabels = [["Tolerence"],
                         ["Comfort range", "Metabolic activity", "Clothing insulation"]]
    
    var tol = "1.0"
    var pmvCRange = "0.5"
    var metValue = 1.2
    var cloValue = 0.67
    
    let metValues = [("Basketball", 6.3), ("Calisthenics", 3.5), ("Cooking", 1.8), ("Dancing", 3.4), ("Driving a car", 1.5), ("Driving, heavy vehicle", 3.2), ("Filing, seated", 1.2), ("Filing, standing", 1.4), ("Heavy machine work", 4.0), ("House cleaning", 2.7), ("Lifting/packing", 2.1), ("Light machine work", 2.2), ("shovel work", 4.4), ("Reading, seated", 1.0), ("Reclining", 0.8), ("Seated, quiet", 1.0), ("Sleeping", 0.7), ("Standing, relaxed", 1.21), ("Table sawing", 1.8), ("Tennis", 3.8), ("Typing", 1.1), ("Walking 2mph", 2.0), ("Walking 3mph", 2.6), ("Walking 4mph", 3.8), ("Walking about", 1.7), ("Wrestling", 7.8), ("Writing" , 1.0)]
    
    let cloValues = [("Winters Attire", 0.96), ("Formal attire", 0.67), ("Summers (Female)", 0.54), ("Sweat pants/shirt", 0.74), ("office Full sleeves", 0.61), ("Office half sleeves", 0.57), ("Summer indoor", 0.5), ("Winter Indoor", 1.0), ("Shorts and Shirt", 0.36)]
    
    let tolValuesForPicker = ["0.5", "1.0", "1.5", "2.0", "2.5", "3.0"]
    let cRangeValuesForPicker = ["0.5", "1.0", "1.5", "2.0", "2.5", "3.0"]
    
    var metValuesForPicker : [String]{
        var temp: [String] = []
        for val in metValues{
            temp.append(val.0)
        }
        return temp
    }
    
    var cloValuesForPicker : [String]{
        var temp: [String] = []
        for val in cloValues{
            temp.append(val.0)
        }
        return temp
    }
    
    var metValueString : String{
        for val in metValues{
            if metValue == val.1{
                return val.0
            }
        }
        return "Error"
    }
    
    var cloValueString: String{
        for val in cloValues{
            if cloValue == val.1{
                return val.0
            }
        }
        return "Error"
    }
    
    var sectionDetailLabels: [[String]]{
        return [["\(tol)   >"],["\(pmvCRange)   >", "\(metValueString)   >", "\(cloValueString)   >"]]
    }
    
    var tempChangedValues = ["0.5", "0.5", "Basketball", "Winters Attire"]
    
    func stringToValue(_ type: String, str: String) -> Double{
        if type == "met"{
            for val in metValues{
                if str == val.0{
                    return val.1
                }
            }
        }
        else{
            for val in cloValues{
                if str == val.0{
                    return val.1
                }
            }
        }
        return -1.0
    }
    
    func updateParamsRequest(){
        let url = "http://localhost:5000/changeParams"
        let postString = "tol=\(tol)&cRange=\(pmvCRange)&met=\(metValue)&clo=\(cloValue)"
        makeRequest(urlString: url, postString: postString, handler: handleEDForNormal)
    }
    
    func makeRequest(urlString: String, postString: String, handler: @escaping (Error?, Data?) -> Void){
        if let url = URL(string: urlString){
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.httpBody = postString.data(using: String.Encoding.utf8)

            let dataTask = URLSession.shared.dataTask(with: request) { (data, response, error) in
                handler(error, data)
            }
            dataTask.resume()
        }
    }
    
    func handleEDForNormal(_ error: Error?, _ data: Data?){
        if error != nil{
            self.delegate?.didFailWithError(self, error: error!)
            return
        }
        
        if let safeData = data{
            let dataString = String(data: safeData, encoding: .utf8)!
            self.delegate?.didServerResponse(self, data: dataString)
        }
    }
}
