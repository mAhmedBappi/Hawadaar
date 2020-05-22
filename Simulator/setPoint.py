import math
import threading, time, json

class SetPoint:
    stopFlag = False
    runningFlag = False

    tempratureReadingFlag = True
    tempratureReadingRunningFlag = False
    
    setPointThread = None
    indoorTemprature = 25.0 
    outdoorTemp = 30.0
    setTemprature = 0.0
    tolerence = 0.0

    deviceStatus = {"ac" : 0, "heater" : 0}

    def __init__(self):
        self.setPointThread = threading.Thread(target = self.start, args = (lambda : self.stopFlag, ))
        self.setPointThread.setDaemon(True)

    #===========================================================
    #class api
    def manager(self, flag):
        if flag == 1:
            if self.runningFlag == False:
                print("\n******************************")
                print("SET POINT mode activated...")
                print("Current indoor temprature value:",end=' ')
                print(self.indoorTemprature)
                print("Current set temprature value:",end=' ')
                print(self.setTemprature)
                print("Current tolerence value: ",end=' ')
                print(self.tolerence) 
                print("******************************\n")
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
                print("SET POINT mode deactivated")
                print("******************************\n")
                return "300" #"SetPoint has stopped"
            else:
                return "400" #"Start Point is not started yet"

    def updateParams(self, params):
        self.outdoorTemp = params['outdoorTemp']
        self.indoorTemprature = params['indoorTemp']
        self.setTemprature = params['spValue']
        self.tolerence = params['spTol']
        self.updateDeviceStatus()

    def updateDeviceStatus(self):
        with open('devicesStatus.json', 'r') as openfile:
            d = json.load(openfile)
            self.deviceStatus["ac"] = d["ac"]
            self.deviceStatus["heater"] = d["heater"]
    #===========================================================

    #===========================================================
    #helper functions
    def updateSPValues(self):
        self.setPointThread = threading.Thread(target = self.start, args = (lambda : self.stopFlag, ))
        self.setPointThread.setDaemon(True)
        self.stopFlag = False
        self.runningFlag = False

    def updatePredictedTemprature(self, k, tempOff, timeSafe):
        tempAfterSafeTime = self.outdoorTemp + ((tempOff - self.outdoorTemp) * math.exp(-1 * k * timeSafe))
        return tempAfterSafeTime

    def updateK(self, pTemp, tempOff, timeSafe):
        k = (math.log((pTemp - self.outdoorTemp) / (tempOff - self.outdoorTemp))) / timeSafe
        return k

    def updateDeviceFile(self):
        d  = {"ac": self.deviceStatus["ac"], "fan": 0, "heater": self.deviceStatus["heater"]}
        with open("devicesStatus.json", "w") as outfile: 
            json.dump(d, outfile)


    def switchOn(self, device):
        print('\n!!!!!!!!!!!!!!!!!!!!!!!')
        print("!!!! AC TURNED ON !!!!!")
        print('!!!!!!!!!!!!!!!!!!!!!!!\n')
        self.deviceStatus[device] = 1
        self.updateDeviceFile()
        

    def switchOff(self, device):
        if self.deviceStatus[device] == 1:
            print('\n!!!!!!!!!!!!!!!!!!!!!!!')
            print("!!!! AC TURNED OFF !!!!")
            print('!!!!!!!!!!!!!!!!!!!!!!!\n')
            self.deviceStatus[device] = 0
            self.updateDeviceFile()

    def extendTolerance(self, t):
        self.tolerence += t

    def readIndoorTemprature(self):
        # print("Reading temprature thread started")
        time.sleep(6)
        if self.tempratureReadingRunningFlag == False:
            with open('weather.json', 'r') as openfile:
                d = json.load(openfile)
                self.indoorTemprature = d['indoorTemp']
                self.outdoorTemp = d['outdoorTemp']
        else:
            self.tempratureReadingRunningFlag = False

        self.tempratureReadingFlag = True
        # print("Reading temprature thread ended")
    
    def stopUpateInFile(self):
        data = None
        with open('modeParams.json', 'r') as openfile:  
            data = json.load(openfile)
        data['mode'] = "off"
        with open("modeParams.json", "w") as outfile: 
            json.dump(data, outfile)
        self.deviceStatus["ac"] = 0
        self.deviceStatus["heater"] = 0
        self.updateDeviceFile()

    #===========================================================

    #===========================================================
    #main stop and start functions
    def stop(self):
        self.stopFlag = True

    def start(self, stop):
        #initialize all required variables
        onTemprature = self.setTemprature + (self.tolerence/2)
        offTemprature = self.setTemprature - (self.tolerence/2)
        k = 0.001
        tSafe = 180.0
        tempAfterSafeTime = self.updatePredictedTemprature(k, offTemprature, tSafe)
        originalTolerence = self.tolerence
        #---------------------------------------
        while True:
            if stop() == True:
                self.tempratureReadingRunningFlag = True
                self.stopUpateInFile()
                break

            if self.tempratureReadingFlag == True:
                # print("-----------------------------------")
                # print("Indoor thermometer reading: ", end=' ')
                # print(self.indoorTemprature)
                # print("-----------------------------------")
                indoorTempratureThread = threading.Thread(target = self.readIndoorTemprature)
                indoorTempratureThread.setDaemon(True)

                if ((self.indoorTemprature > onTemprature) and (self.deviceStatus["ac"] == 0)):
                    self.switchOn("ac")
                elif(self.indoorTemprature <= offTemprature):
                    # print("indoorTemprature < offTemprature")
                    predictedTemprature = tempAfterSafeTime

                    if(predictedTemprature <= onTemprature):
                        self.switchOff("ac")
                        tempAfterSafeTime = self.updatePredictedTemprature(k, offTemprature, tSafe)
                        k = self.updateK(tempAfterSafeTime, offTemprature, tSafe)
                        self.tolerence = originalTolerence
                    else:
                        #extend extendTolerance
                        self.extendTolerance(0.5)

                self.tempratureReadingFlag = False
                indoorTempratureThread.start()
                onTemprature = self.setTemprature + (self.tolerence/2)
                offTemprature = self.setTemprature - (self.tolerence/2)
