from pythermalcomfort.models import pmv
from pythermalcomfort.psychrometrics import v_relative
import time, threading, json

class PMV:
    setOfDevices = {"ac": 0, "fan": 0, "heater": 0}
    airVelocityFan = 1.4 #units -> m/s
    airVelocityAC = 0.5 #units -> m/s

    setPointThread = None
    stopFlag = False
    runningFlag = False

    tempratureReadingFlag = True
    tempratureReadingRunningFlag = False
    
    #variables to calculate PMV:
    #--------------------------------------------
    comfortRange = [-0.5, 0.5]
    tempOut = 35.0
    tempAir = 33.0 #units -> degrees
    tempRadiant = 33.0 #units -> degrees
    relativeAirVelocity = 0.0 #units -> m/s
    relativeHumidity = 50.0 #units -> percentage
    metabolicRate = 1.3 #units -> met
    clothingInsulation = 0.6 #units -> clo
    #--------------------------------------------

    #constructor
    #--------------------------------------------
    def __init__(self):
        self.setPointThread = threading.Thread(target = self.start, args = (lambda : self.stopFlag, ))
        self.setPointThread.setDaemon(True)
    #--------------------------------------------

    #--------------------------------------------
    #API
    def manager(self, flag):
        if flag == 1:
            if self.runningFlag == False:
                self.printInitialParams()
                self.setPointThread.start()
                self.runningFlag = True
                return "100" #"setPoint is Started"
            else:
                return "200" #"setPoint is already running"
        elif flag == 2:
            if self.runningFlag == True:
                self.stop()
                self.setPointThread.join()
                self.updateSPValues()
                print("\n******************************")
                print("PMV mode deactivated")
                print("******************************\n")
                return "300" #"SetPoint has stopped"
            else:
                return "400" #"Start Point is not started yet"
    
    def updateParams(self, params):
        self.tempOut = params["outdoorTemp"]
        self.tempAir = params["indoorTemp"]
        self.tempRadiant = params["indoorTemp"]
        self.relativeHumidity = params["humidity"]
        self.comfortRange[0] = -1 * params["pmvCRange"]
        self.comfortRange[1] = params["pmvCRange"]
        self.metabolicRate = params["met"]
        self.clothingInsulation = params["clo"]
        self.updateDeviceStatus()

    def updateDeviceStatus(self):
        with open('devicesStatus.json', 'r') as openfile:
            d = json.load(openfile)
            self.setOfDevices["ac"] = d["ac"]
            self.setOfDevices["fan"] = d["fan"]
            self.setOfDevices["heater"] = d["heater"]
    #--------------------------------------------
    def printInitialParams(self):
        print("\n******************************")
        print("PMV mode activated...")
        print("******************************")
        temp = "Current indoor temprature value: " + str(self.tempAir)
        print(temp)
        print("*-----------------------------")
        print("Printing the parameters to calculate pmv")
        print("*-----------------------------")
        temp = "Comfort range: " + str(self.comfortRange[0]) + " to " + str(self.comfortRange[1])
        print(temp) 
        temp = "Temperature_Air: " + str(self.tempAir)
        print(temp)
        temp = "Temperature_radiant: " + str(self.tempRadiant)
        print(temp)
        temp = "Relative air velocity: " + str(self.relativeAirVelocity)
        print(temp)
        temp = "Relative humidity: " + str(self.relativeHumidity)
        print(temp)
        temp = "Metabolic rate: " + str(self.metabolicRate)
        print(temp)
        temp = "Clothing insulation: " + str(self.clothingInsulation)
        print("******************************\n")

    def updateSPValues(self):
        self.setPointThread = threading.Thread(target = self.start, args = (lambda : self.stopFlag, ))
        self.setPointThread.setDaemon(True)
        self.stopFlag = False
        self.runningFlag = False
    
    def convertToMet(self, m):
        result = (1/58) * m
        return result

    def turnOnFan(self):
        self.setOfDevices["fan"] = 1
        self.updateDeviceFile()
        print("\n!!!!!!!!!!!!!!!!!!!!!!!!")
        print("!!!! FAN TURNED ON !!!!!")
        print("!!!!!!!!!!!!!!!!!!!!!!!!\n")

    def turnOnAC(self):
        self.setOfDevices["ac"] = 1
        self.updateDeviceFile()
        print("\n!!!!!!!!!!!!!!!!!!!!!!!!")
        print("!!!!! AC TURNED ON !!!!!")
        print("!!!!!!!!!!!!!!!!!!!!!!!!\n")

    def turnOffFan(self):
        self.setOfDevices['fan'] = 0
        self.updateDeviceFile()
        print("\n!!!!!!!!!!!!!!!!!!!!!!!!")
        print("!!!! FAN TURNED OFF !!!!")
        print("!!!!!!!!!!!!!!!!!!!!!!!!\n")
    
    def updateDeviceFile(self):
        d  = {"ac": self.setOfDevices["ac"], "fan": self.setOfDevices["fan"], "heater": self.setOfDevices["heater"]}
        with open("devicesStatus.json", "w") as outfile: 
            json.dump(d, outfile)

    def allDevicesOff(self):
        return self.setOfDevices["ac"] == 0 and self.setOfDevices["fan"] == 0 and self.setOfDevices["heater"] == 0
    
    def inComfortRange(self, pmvValue):
        return pmvValue >= self.comfortRange[0] and pmvValue <= self.comfortRange[1]
    
    def switchOffAllDevices(self):
        s = "\n!!!!!!!!!!!!!!!!!!!!!!!!"
        if self.setOfDevices["ac"] == 1:
            s += "\n!!!! AC TURNED OFF !!!!!"
            self.setOfDevices["ac"] = 0
        if self.setOfDevices["fan"] == 1:
            s+="\n!!!! FAN TURNED OFF !!!!"
            self.setOfDevices["fan"] = 0
        s+= "\n!!!!!!!!!!!!!!!!!!!!!!!!\n"
        self.setOfDevices["heater"] = 0

        self.updateDeviceFile()
        self.relativeAirVelocity = 0.0
        print(s)

    def calculatePMV(self):
        vr = v_relative(self.relativeAirVelocity, self.metabolicRate)
        result = pmv(self.tempAir, self.tempRadiant, vr, self.relativeHumidity, self.metabolicRate, self.clothingInsulation, wme=0, standard='ASHRAE', units='SI')
        return result

    def stopUpateInFile(self):
        data = None
        with open('modeParams.json', 'r') as openfile:  
            data = json.load(openfile)
        data['mode'] = "off"
        with open("modeParams.json", "w") as outfile: 
            json.dump(data, outfile)
        self.setOfDevices["ac"] = 0
        self.setOfDevices["fan"] = 0
        self.setOfDevices["heater"] = 0
        self.updateDeviceFile()
    
    def readTemprature(self):
        time.sleep(6)
        if self.tempratureReadingRunningFlag == False:
            with open('weather.json', 'r') as openfile:
                d = json.load(openfile)
                self.tempAir = d['indoorTemp']
                self.tempRadiant = d['indoorTemp']
                self.tempOut = d['outdoorTemp']
        else:
            self.tempratureReadingRunningFlag = False
        self.tempratureReadingFlag = True

    #main logic
    #----------------------------------------------------------------
    def stop(self):
        self.stopFlag = True

    def start(self, stop):
        while True:
            if stop() == True:
                self.tempratureReadingRunningFlag = True
                self.stopUpateInFile()
                break

            if self.tempratureReadingFlag == True:
                pmvValue = self.calculatePMV()
                if pmvValue > self.comfortRange[1]:
                    if self.allDevicesOff():
                        self.relativeAirVelocity = self.airVelocityFan
                        pmvValue = self.calculatePMV()
                        if self.inComfortRange(pmvValue):
                            self.turnOnFan() #turn on fan
                        else:
                            self.relativeAirVelocity = self.airVelocityAC
                            self.turnOnAC() #turn on AC
                    elif self.setOfDevices["fan"] != 0: #if fan is running
                        self.turnOffFan()    #turn off fan
                        self.relativeAirVelocity = self.airVelocityAC
                        self.turnOnAC()     #turn on AC
                elif pmvValue <= self.comfortRange[0]:
                    self.switchOffAllDevices()
                
                #read indoor temperature
                indoorTempratureThread = threading.Thread(target = self.readTemprature)
                indoorTempratureThread.setDaemon(True)
                self.tempratureReadingFlag = False
                indoorTempratureThread.start()
