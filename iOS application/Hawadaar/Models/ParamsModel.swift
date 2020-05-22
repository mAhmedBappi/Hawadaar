import Foundation

struct ParamsModel {
    var conditionId: Int
    var cityName: String
    var temprature: Double
    var humidity: Double
    var spValue: Double
    var spTol: Double
    var pmvCRange: Double
    var mode: String
    var met: Double
    var clo: Double
    
    var tempratureString: String{
        return String(format: "%.1f", temprature)
    }
    
    var humidityString: String{
        return String(format: "%.0f", humidity)
    }
    
    var conditionName : String{
        switch conditionId {
        case 200...232:
            return "cloud.bolt"
        case 300...321:
            return "cloud.drizzle"
        case 500...531:
            return "cloud.rain"
        case 600...622:
            return "cloud.snow"
        case 701...781:
            return "cloud.fog"
        case 800:
            return "sun.max"
        case 801...804:
            return "cloud.bolt"
        default:
            return "cloud"
        }
    }
}
