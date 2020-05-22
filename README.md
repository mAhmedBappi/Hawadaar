# Hawadaar
This repo contains the iOS application and simulator for HAWADAAR - Inverting HVAC for Energy Efficient Thermal Comfort in
Populous Emerging Countries.

SPROJ 2019-20 | Lahore University Of Management Sciences

Muhammad Ahmed Bappi, 19100256

Running instructions

1) Simulator

  Language: python3
  
  FrameWorks used: Flask, pythermalcomfort
  
  virtual environment (Virtualenv) is used to contain the frameworks.
  
  Make sure you have Python3 installed on your system
  
  Install virtual environment using pip3
  
  open the terminal and write the following two commands:
  
  1) $ python3 -m pip install --upgrade pip
  2) $ pip3 install virtualenv
  
 After the virtual environment is installed, open terminal and change directory to the "Simulator" folder.
  
 Type the following command in the terminal to activate the virtual environment in the simulator folder:
 
 $ source venv/bin/activate
 
 once the virtual environment is activated run the simulator.py file to start the simulator.
 
 $ python3 simulator.py
 
 Alternately you can download only the ".py" files from the simulator folder and install the frameworks globally.
 
 
 2) iOS application.
 
 Made in Swift 5.1, Xcode 11.4, iOS version greater than 13.0 
 
 Make sure you have XCode installed and updated to the latest iOS version on your mac book. Open the iOS application folder and double click on the "Hawadaar.xcodeproj" to start the run the project in XCode. Once in Xcode, click on the run button to run the app on a simulator. 
 
 The app requires the simulator to be running before it can be launched. Make sure the simulator is running before you run the app or else it will give error message at the launch.
 
