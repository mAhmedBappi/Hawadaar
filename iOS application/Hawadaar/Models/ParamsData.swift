import Foundation

struct ParamsData: Decodable {
    let id: Int
    let city: String
    let indoorTemp: Double
    let humidity: Double
    let spValue: Double
    let spTol: Double
    let pmvCRange: Double
    let met: Double
    let clo: Double
    let mode: String
}
