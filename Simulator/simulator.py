from flask import Flask, request, jsonify
import urllib.request, json
from manager import hawadaarManager
from thermal import thermalModule

simulator = Flask(__name__)
m = hawadaarManager()
t = thermalModule()

@simulator.route('/start', methods = ["POST"])
def start():
    if request.method == "POST":
        modeType = request.form['type']
        params = readParamsFromFile()
        # print("MODE STARTED:", end = ' ')
        # print(modeType)
        if modeType == "sp":
            spVal = request.form['spValue']
            params['newSPValue'] = float(spVal)
            # print("SET POINT VALUE:", end = ' ')
            # print(spVal)
        return m.parseStartRequest(modeType, params)

@simulator.route('/stop')
def stop():
    return m.parseStopRequest()

@simulator.route('/init')
def init():
    data = readParamsFromFile()
    # print("Got INIT request from a application")
    return jsonify(data)

@simulator.route('/changeParams', methods = ["POST"])
def changeParams():
    if request.method == "POST":
        tol = float(request.form['tol'])
        cRange = float(request.form['cRange'])
        met = float(request.form['met'])
        clo = float(request.form['clo'])

        data = readParamsFromFile()
        data["met"] = met
        data["clo"] = clo
        data["pmvCRange"] = cRange
        data["spTol"] = tol

        return m.parseChangeParamsRequest(data)

def readParamsFromFile():
    with open('weather.json', 'r') as wFile, open('modeParams.json', 'r') as pFile:
        weather = json.load(wFile)
        params = json.load(pFile)

        dictionary = { 
            "id" : weather['id'],
            "city" : weather['city'],
            "outdoorTemp" : weather['outdoorTemp'],
            "indoorTemp" : weather['indoorTemp'],
            "humidity" : weather['humidity'], 
            "spValue" : params['spValue'], 
            "spTol" : params['spTol'],
            "pmvCRange": params['pmvCRange'],
            "met": params['met'],
            "clo": params['clo'],
            "mode" : params['mode']
        }
        return dictionary
        
def initModeParams(spValue = 30.0, spTol = 1.0, pmvCRange = 0.5, met = 1.2, clo = 0.61, mode = "off"):
    dictionary = {"spValue" : spValue, "spTol" : spTol, "pmvCRange": pmvCRange, "met": met, "clo": clo, "mode": mode}
    with open("modeParams.json", "w") as outfile: 
        json.dump(dictionary, outfile)

def initDevices():
    dictionary = {"ac" : 0, "fan": 0, "heater": 0}
    with open("devicesStatus.json", "w") as outfile: 
        json.dump(dictionary, outfile)

if __name__ == "__main__":
    initModeParams()
    initDevices()
    t.startThread()
    simulator.run(debug=True, use_reloader=False)