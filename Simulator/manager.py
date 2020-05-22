from setPoint import SetPoint
from pmv import PMV
import json

class hawadaarManager:
    setPointObject = SetPoint()
    pmvObject = PMV()

    isPMVRunning = False
    isSETPOINTRunning = False

    def parseStartRequest(self, type, params):
        if type == "pmv":
            if self.isPMVRunning:
                return "PMV mode is already running"
            elif self.isSETPOINTRunning:
                self.stopSetPoint()

            params['mode'] = "pmv"
            d = {"spValue": params["spValue"], "spTol": params["spTol"], "pmvCRange": params["pmvCRange"], "met": params["met"], 
                    "clo": params["clo"], "mode": params["mode"]}
            with open("modeParams.json", "w") as outfile: 
                json.dump(d, outfile)

            return self.startPMV(params)
        elif type == "sp":
            if self.isSETPOINTRunning:
                return "SET POINT mode is already running"
            elif self.isPMVRunning:
                self.stopPMV()
            
            params['mode'] = "sp"
            params['spValue'] = params['newSPValue']
            params.pop('newSPValue')
            
            d = {"spValue": params["spValue"], "spTol": params["spTol"], "pmvCRange": params["pmvCRange"], "met": params["met"], 
                    "clo": params["clo"], "mode": params["mode"]}
            with open("modeParams.json", "w") as outfile: 
                json.dump(d, outfile)

            return self.startSetPoint(params)
        else:
            return "UnKnown request"
    #----------------------------------
    #start / stop PMV mode
    def startPMV(self, params):
        self.pmvObject.updateParams(params)
        self.pmvObject.manager(1)
        self.isPMVRunning = True
        return "PMV mode activated"
    def stopPMV(self):
        self.pmvObject.manager(2)
        self.isPMVRunning = False
        return "PMV mode stopped"
    #----------------------------------
    #----------------------------------
    #start / stop set point mode
    def startSetPoint(self, params):
        self.setPointObject.updateParams(params)
        self.setPointObject.manager(1)
        self.isSETPOINTRunning = True
        return "SET POINT mode activated"
    def stopSetPoint(self):
        self.setPointObject.manager(2)
        self.isSETPOINTRunning = False
        return "SET POINT mode stopped"
    #----------------------------------

    def parseStopRequest(self):
        if self.isPMVRunning:
            return self.stopPMV()
        elif self.isSETPOINTRunning:
            return self.stopSetPoint()
        return "No Mode is running"
    
    def parseConnectionRequest(self):
        return "connection is alive"

    def parseChangeParamsRequest(self, params):
        d = {"spValue": params["spValue"], "spTol": params["spTol"], "pmvCRange": params["pmvCRange"], "met": params["met"], 
                    "clo": params["clo"], "mode": params["mode"]}

        with open("modeParams.json", "w") as outfile: 
            json.dump(d, outfile)

        if self.isPMVRunning:
            self.parseStopRequest()
            self.parseStartRequest("pmv", params)
        elif self.isSETPOINTRunning:
            self.parseStopRequest()
            params['newSPValue'] = self.setPointObject.setTemprature
            self.parseStartRequest("sp", params)
        
        return "Parameters updated"
        