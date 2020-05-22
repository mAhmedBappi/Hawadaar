import Foundation

protocol HawadaarManagerDelegate {
    func didServerResponse(_ hawadaarManager: HawadaarManager, data: String)
    func didFailWithError(_ hawadaarManager: HawadaarManager, error: Error)
    func didServerInitialResponse(_ hawadaarManager: HawadaarManager, data: ParamsModel)
    func didFailServerInitialResponse(_ hawadaarManager: HawadaarManager, error: Error)
    func didModeChanged(_ hawadaarManager: HawadaarManager, data: String)
    func didModeChangeFail(_ hawadaarManager: HawadaarManager, error: Error)
}

struct HawadaarManager{
    var delegate: HawadaarManagerDelegate?
    var params:ParamsModel?
    
    
    func requestToStart(type: String){
        let urlTuple = setStartRequestURL(type)
        makeRequest(urlString: urlTuple.0, postString: urlTuple.1, handler: handleEDForNormal)
    }
    
    func requestToChangeMode(type: String){
        let urlTuple = setStartRequestURL(type)
        makeRequest(urlString: urlTuple.0, postString: urlTuple.1, handler: handleEDForModeChange)
    }
    
    func setStartRequestURL(_ type: String) -> (String, String){
        let url = "http://localhost:5000/start"
        let postString: String
        if type == "pmv"{
        postString = "type=pmv"
        }
        else{
            postString = "type=sp&spValue=\(params!.spValue)"
        }
        return (url, postString)
    }
    
    func requestToStop(){
        let url = "http://localhost:5000/stop"
        makeRequest(for: url, handler: handleEDForNormal)
    }
    
    func connectToServer(){
        let url = "http://localhost:5000/init"
        makeRequest(for: url, handler: handleEDForConnection)
    }
    
    func handleEDForModeChange(_ error: Error?, _ data: Data?){
        if error != nil{
            self.delegate?.didModeChangeFail(self, error: error!)
            return
        }
        
        if let safeData = data{
            let dataString = String(data: safeData, encoding: .utf8)!
            self.delegate?.didModeChanged(self, data: dataString)
        }
    }
    
    func handleEDForConnection(_ error: Error?, _ data: Data?){
        if error != nil{
            self.delegate?.didFailServerInitialResponse(self, error: error!)
            return
        }
        
        if let safeData = data{
            if let p = self.parseJason(safeData){
                self.delegate?.didServerInitialResponse(self, data: p)
            }
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
    
    func makeRequest(for urlString: String, handler: @escaping (Error?, Data?) -> Void){
        if let url = URL(string: urlString){
            
            let session = URLSession(configuration: .default)
            
            let dataTask = session.dataTask(with: url) { (data, response, error) in
                handler(error, data)
            }
            dataTask.resume()
        }
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
    
    func parseJason(_ data: Data) -> ParamsModel?{
        let decoder = JSONDecoder()
        
        do{
            let decodedData = try decoder.decode(ParamsData.self, from: data)
            
            let id = decodedData.id
            let city = decodedData.city
            let temp = decodedData.indoorTemp
            let humidity = decodedData.humidity
            let spVal = decodedData.spValue
            let spTol = decodedData.spTol
            let pmvCR = decodedData.pmvCRange
            let mode = decodedData.mode
            let met = decodedData.met
            let clo = decodedData.clo
            
            return ParamsModel(conditionId: id, cityName: city, temprature: temp, humidity: humidity,
                               spValue: spVal, spTol: spTol, pmvCRange: pmvCR, mode: mode, met: met, clo: clo)
            
        }catch{
            delegate?.didFailServerInitialResponse(self, error: error)
            return nil
        }
    }
}
