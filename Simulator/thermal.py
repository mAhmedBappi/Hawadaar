import datetime, time, math, urllib.request, json, threading
# from meteocalc import Temp, heat_index

class thermalModule:
    outdoorTempLimit = [42.57, 26.2]
    indoorTempLimit = [32.57, 29.7]
    roomDimensions = [3.6576, 3.048, 3.048]
    ACGrillDimensions = [0.762, 0.0762]
    devices = {"ac": 0, "fan": 0, "heater": 0}
    readingTime = 5.0
    data = None
    thermalThread = None 

    #material thickness
    brickThickness = 0.115
    cementThickness = 0.015
    #=========================
    
    #material densities
    densityBrick = 1536.0
    densityCement = 1406.0
    densityAir = 1.225
    #========================

    #material heat capacities
    heatCapacityBrick = 523
    heatCapacityCement = 1050
    heatCapacityAir = 1005
    #========================

    #material heat coefficient
    heatCoefficientWall = 1.787
    #========================

    #cooling/heating rates
    coolingRateAC = 3504 #cooling capacity of 1 ton AC in watts
    heatingRateBulb = 27 #30 watts energy saver with efficiency of 10%
    heatingRateHuman = 97.22
    heatingRateFan = 42 #36 inch ceiling fan with efficiency of 30%
    #===========================

    #air velocities
    airVelocityFan = 1.4
    airVelocityAC = 0.5
    #========================

    def __init__(self):
        self.thermalThread = threading.Thread(target= self.start)
        self.thermalThread.setDaemon(True)

    def getHeatCoefficientWall(self, l):
        return self.getArea(l, self.roomDimensions[2]) * self.heatCoefficientWall
    
    def getHeatCapacityWall(self, l):
        volumeOfBrickLayer = self.getVolume(l, self.roomDimensions[2], self.brickThickness)
        volumeOfCementLayer = self.getVolume(l, self.roomDimensions[2], self.cementThickness)

        weightOfBrickLayer = self.getWeight(self.densityBrick, volumeOfBrickLayer)
        weightOfCementLayer = self.getWeight(self.densityCement, volumeOfCementLayer)

        hcBrickLayer = self.heatCapacityBrick*weightOfBrickLayer
        hcCementLayer = self.heatCapacityCement*weightOfCementLayer

        return hcBrickLayer + hcCementLayer + hcCementLayer


    def getHeatCoefficientAir(self):
        v = 0.0
        if self.devices["ac"] == 1:
            v = self.airVelocityAC
        elif self.devices["fan"] == 1:
            v = self.airVelocityFan
        
        htc = ((10.45-v) + (10*(v**0.5)))/0.85984
        return self.getArea(self.ACGrillDimensions[0], self.ACGrillDimensions[1]) * htc


    
    def getHeatCapacityAir(self):
        volume = self.getVolume(self.roomDimensions[0], self.roomDimensions[1], self.roomDimensions[2])
        weight = self.getWeight(self.densityAir,volume)
        return self.heatCapacityAir * weight

    def totalWallKCValue(self):
        longWallKValue = self.getHeatCoefficientWall(self.roomDimensions[0])
        wideWallKValue = self.getHeatCoefficientWall(self.roomDimensions[1])
        longWallHeatCapacity = self.getHeatCapacityWall(self.roomDimensions[0])
        wideWallHeatCapacity = self.getHeatCapacityWall(self.roomDimensions[1])

        totalHTC = (longWallKValue*2) + (wideWallKValue*2)
        totalHC = (longWallHeatCapacity*2) + (wideWallHeatCapacity*2)
        return(totalHTC, totalHC)

    def getVolume(self,l,b,h):
        return l*b*h

    def getArea(self,l,b):
        return l*b

    def getWeight(self,density, volume):
        return density*volume
    
    def updateThermalLevels(self):
        coeficient = (self.outdoorTempLimit[0]-self.outdoorTempLimit[1])/12
        gradient = (self.outdoorTempLimit[0]- self.outdoorTempLimit[1])/(self.indoorTempLimit[0]-self.indoorTempLimit[1])
        intersect = self.outdoorTempLimit[0] - (self.indoorTempLimit[0]*gradient)

        current = datetime.datetime.now()
        tempDiff = 0.0
        if current.hour>5 and current.hour<19:
            lowestT = datetime.datetime(current.year,current.month, current.day, 6, 0, 0)
            diffHours = math.floor((current-lowestT).seconds/60/60)

            outdoor = diffHours*coeficient + self.outdoorTempLimit[1]
            indoor = (outdoor-intersect)/gradient
            tempDiff = outdoor-indoor
        else:
            highestT = None
            if current.hour>23:
                highestT = datetime.datetime(current.year,current.month, current.day-1, 18,0,0)
            else:
                highestT = datetime.datetime(current.year,current.month, current.day, 18,0,0)
            
            diffHours = math.floor((current-highestT).seconds/60/60)

            outdoor = self.outdoorTempLimit[0] - (diffHours*coeficient)
            indoor = (outdoor-intersect)/gradient
            tempDiff = outdoor-indoor

        data = self.getWeather("Faisalabad")
        data['indoorMaxTemp'] = round(data['feels_like'] - tempDiff, 2)
        return data

    def getWeather(self, city):
        url = "https://api.openweathermap.org/data/2.5/weather?appid=09be1300e010df9240af2dc13c7bd745&units=metric&q="
        url += city
        try:
            with urllib.request.urlopen(url) as response:
                data = json.loads(response.read())
                main = data['main']
                weatherID = data['weather'][0]['id']
                windSpeed = data['wind']['speed']
                main['id'] = weatherID
                main['windSpeed'] = windSpeed
                main['city'] = data['name']
                return main 
        except:
            print("could not fetch weather data, check your internet connection")
            exit()

    def writeDevice(self):
        dictionary = { 
            "ac" : 0,
            "fan": 0,
            "heater": 0
        }
        with open("devicesStatus.json", "w") as outfile: 
            json.dump(dictionary, outfile)

    def updateDeviceStatus(self):
        with open('devicesStatus.json', 'r') as openfile:
            self.devices = json.load(openfile)

    def writeDataToFile(self):
        dictionary = { 
            "id" : self.data['id'],
            "city" : self.data['city'],
            "outdoorTemp" : self.data['feels_like'],
            "indoorTemp" : self.data['indoorTemp'],
            "humidity" : self.data['humidity']
        }
        with open("weather.json", "w") as outfile: 
            json.dump(dictionary, outfile)

    def updateIndoorTemp(self):
        tempInAC = 18.0
        tempACCooling = 0.0
        tempFanHeating = 0.0

        if self.devices["fan"] == 1:
            tempFanHeating = self.heatingRateFan

        if self.devices["ac"] == 1:
            tempACCooling = self.coolingRateAC

        # tempinplus = tempin + ((e*p) - (k*(tempin-tempout)))/c

        heatDesipated = (-1*0.40*tempACCooling) + (3*self.heatingRateBulb) + (2*self.heatingRateHuman) + tempFanHeating
        totalWallK, totalWallHC = self.totalWallKCValue()
        
        tempAir = ((heatDesipated - (self.getHeatCoefficientAir()*(tempInAC-self.data['indoorTemp'])))/self.getHeatCapacityAir())*self.readingTime
        tempWall = abs(((heatDesipated + (totalWallK*((self.data['indoorTemp']+tempAir)-self.data['feels_like'])))/totalWallHC)*self.readingTime)

        newTemp = round(self.data['indoorTemp'] + (tempAir + tempWall),2)
        if newTemp < self.data['indoorMaxTemp'] + 0.3 and newTemp > tempInAC - 0.3:
            if newTemp < tempInAC:
                self.data['indoorTemp'] = tempInAC
            else:
                self.data['indoorTemp'] = newTemp
        
    def start(self):
        # self.updateDeviceStatus()
        data = self.updateThermalLevels()
        data['indoorTemp'] = data['indoorMaxTemp']
        self.data = data

        while True:
            print('Indoor Thermometer Reading:',end=' ')
            print(self.data['indoorTemp'])

            self.updateDeviceStatus()
            self.updateIndoorTemp()

            time.sleep(self.readingTime)

            indoorTemp = self.data['indoorTemp']
            data = self.updateThermalLevels()
            data['indoorTemp'] = indoorTemp
            self.data = data
            self.writeDataToFile()

    def startThread(self):
        self.thermalThread.start()
        # thermalThread.join()


# o = thermalModule()
# o.writeDevice()
# o.startThread()