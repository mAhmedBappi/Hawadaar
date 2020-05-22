//
//  ViewController.swift
//  Hawadaar
//
//  Created by Muhammad Ahmed Bappi on 21/04/2020.
//  Copyright © 2020 Muhammad Ahmed Bappi. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    var powerFlag = false
    var currentModerunning = "p"
    var modeFlag = false
    var changeSPPressed = false
    
    var hawadaarManager = HawadaarManager()
    var mode = "pmv"
    
   let orangeColor = UIColor(red: 1.00, green: 0.36, blue: 0.00, alpha: 1.00)
   let grayColor =  UIColor(red: 0.20, green: 0.21, blue: 0.25, alpha: 1.00)
    
    var spValFromPicker = 18.0
    
    let picker = UIView()
    
    var pickerData = [18.0, 19.0, 20.0, 21.0, 22.0, 23.0, 24.0, 25.0, 26.0]
    
    var timer: Timer?
    
    @IBOutlet weak var temperatureLabel: UILabel!
    @IBOutlet weak var conditionImageView: UIImageView!
    @IBOutlet weak var humidityLabel: UILabel!
    @IBOutlet weak var cityLabel: UILabel!
    @IBOutlet weak var setPointButton: UIButton!
    @IBOutlet weak var pmvButton: UIButton!
    @IBOutlet weak var powerButton: UIButton!
    @IBOutlet weak var currentModeLabel: UILabel!
    @IBOutlet weak var serverMsgLabel: UILabel!
    @IBOutlet weak var setPointParamsView: UIStackView!
    @IBOutlet weak var setPointValueLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        hawadaarManager.delegate = self
        serverMsgLabel.alpha = 0
        setPointParamsView.isHidden = true
        setPickerView()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        self.navigationController?.setNavigationBarHidden(false, animated: animated)
        super.viewWillDisappear(animated)
        timer?.invalidate()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: animated)
        hawadaarManager.connectToServer()
        getUpdateInBacksground()
    }
    
    @IBAction func powerPressed(_ sender: UIButton) {
        if powerFlag == false{
            hawadaarManager.requestToStart(type: mode)
        }
        else{
            hawadaarManager.requestToStop()
        }
    }
    @IBAction func setPointPressed(_ sender: UIButton) {
        if currentModerunning == "p"{
            self.view.addSubview(picker)
        }
    }
    @IBAction func pmvPressed(_ sender: UIButton) {
        if currentModerunning == "s"{
            if powerFlag == false{
                self.setMode("pmv")
            }
            else{
                modeFlag = false
                hawadaarManager.requestToChangeMode(type: "pmv")
            }
        }
    }
    
    
    @IBAction func setPointChangePressed(_ sender: UIButton) {
        if powerFlag{
            changeSPPressed = true
            self.view.addSubview(picker)
        }
        else{
            self.view.addSubview(picker)
        }
    }
    
    @IBAction func settingsPressed(_ sender: UIButton) {
        performSegue(withIdentifier: "settingsSeague", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        if segue.identifier == "settingsSeague"{
            if let controller = segue.destination as? SettingsViewController {
                controller.settingsManager.tol = "\(hawadaarManager.params!.spTol)"
                controller.settingsManager.pmvCRange = "\(hawadaarManager.params!.pmvCRange)"
                controller.settingsManager.cloValue = hawadaarManager.params!.clo
                controller.settingsManager.metValue = hawadaarManager.params!.met
            }
        }
    }
    
    func getUpdateInBacksground(){
        timer = Timer.scheduledTimer(timeInterval: 18, target: self, selector: #selector(runTimedCode), userInfo: nil, repeats: true)
    }
    
    @objc func runTimedCode(){
        DispatchQueue.global(qos: .background).async{
            self.hawadaarManager.connectToServer()
        }
    }
    
    func setPickerView(){
        let heightOfView: CGFloat = 450.0
        picker.frame = CGRect(x: 15, y: (view.frame.height/2) - 110, width: view.frame.width-30, height: heightOfView)
        picker.backgroundColor = self.grayColor
        
        picker.layer.borderWidth = 1
        picker.layer.borderColor = UIColor.white.cgColor
        
        picker.alpha = 0.97

        let toolbar = getToolBar()
        let title = getPickerTitle(heightOfView)

        let valuePicker = UIPickerView(frame: CGRect(x: 0.0, y: heightOfView-300, width: picker.frame.width, height: 300))
        valuePicker.delegate = self
        valuePicker.dataSource = self
        
        valuePicker.setValue(self.orangeColor, forKeyPath: "textColor")
        
        picker.addSubview(toolbar)
        picker.addSubview(title)
        picker.addSubview(valuePicker)
    }
    
    func getToolBar() -> UIToolbar{
        let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(self.doneTapped))
        let spaceButton = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let cancelButton = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(self.cancelTapped))

        let toolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: picker.frame.width, height: 50))
        toolbar.barStyle = .default
        toolbar.barTintColor = self.orangeColor
        toolbar.tintColor = .white
        toolbar.isTranslucent = false
        toolbar.items = [cancelButton, spaceButton, doneButton]
        return toolbar
    }
    func getPickerTitle(_ heightOfView: CGFloat) -> UILabel{
        let label = UILabel(frame: CGRect(x: 0, y: heightOfView-350, width: picker.frame.width, height: 50))
        label.textAlignment = .center
        label.textColor = .white
        label.text = "Please select the SET POINT value"
        return label
    }
    
    func setMode(_ currentMode: String){
        if currentMode == "sp"{
            setPointButton.backgroundColor = self.orangeColor
            pmvButton.backgroundColor = self.grayColor
            mode = "sp"
            currentModerunning = "s"
            currentModeLabel.text = "The current mode is SET POINT"
            setPointValueLabel.text = "\(String(format: "%.0f", self.hawadaarManager.params!.spValue)) °C"
            setPointParamsView.isHidden = false
        }
        else{
            pmvButton.backgroundColor = self.orangeColor
            setPointButton.backgroundColor = self.grayColor
            mode = "pmv"
            currentModerunning = "p"
            currentModeLabel.text = "The current mode is PMV"
            setPointParamsView.isHidden = true
        }
    }
    
    @objc func doneTapped(){
        hawadaarManager.params!.spValue = self.spValFromPicker
        if changeSPPressed{
            hawadaarManager.requestToStop()
            self.setMode("sp")
        }
        else{
            if powerFlag{
                self.modeFlag = true
                hawadaarManager.requestToChangeMode(type: "sp")
            }
            else{
                self.setMode("sp")
            }
        }
        picker.removeFromSuperview()
    }
    @objc func cancelTapped(){
        picker.removeFromSuperview()
    }
    
    func showAlert(alertTitle: String, alertMessage: String, alertActionTitle: String, afterDismiss: ((UIAlertAction) -> Void)? = nil){
        let alertController = UIAlertController(title: alertTitle, message: alertMessage, preferredStyle: .alert)
        let dismissButton = UIAlertAction(title: alertActionTitle, style: .default, handler: afterDismiss)
        alertController.addAction(dismissButton)
        self.present(alertController, animated: true, completion: nil)
    }
    
    func showServerMessage(data: String){
        serverMsgLabel.text = data
        serverMsgLabel.alpha = 1
        UIView.animate(withDuration: 5, animations: { () -> Void in
            self.serverMsgLabel.alpha = 0
        })
    }
}

//MARK: - Hawadaar manager delegate
extension ViewController: HawadaarManagerDelegate{
    func didServerResponse(_ hawadaarManager: HawadaarManager, data: String) {
        if self.powerFlag == false{
            DispatchQueue.main.async {
                self.powerButton.setImage(#imageLiteral(resourceName: "PowerOn"), for: .normal)
                if self.changeSPPressed == false{
                    self.showServerMessage(data: data)
                }
                self.powerFlag = true
            }
        }
        else{
            DispatchQueue.main.async {
                self.powerButton.setImage(#imageLiteral(resourceName: "powerOff"), for: .normal)
                if self.changeSPPressed == false{
                    self.showServerMessage(data: data)
                }
                self.powerFlag = false
                
                if self.changeSPPressed{
                    self.hawadaarManager.requestToStart(type: self.mode)
                    self.changeSPPressed = false
                }
            }
        }
        print(data)
    }
    func didFailWithError(_ hawadaarManager: HawadaarManager, error: Error) {
        DispatchQueue.main.async {
            self.showAlert(alertTitle: "Error", alertMessage: "\(error.localizedDescription)", alertActionTitle: "Dismiss")
            self.powerButton.setImage(#imageLiteral(resourceName: "powerOff"), for: .normal)
            self.powerFlag = false
        }
    }
    func didServerInitialResponse(_ hawadaarManager: HawadaarManager, data: ParamsModel){
        DispatchQueue.main.async {
            self.hawadaarManager.params = data
            self.conditionImageView.image = UIImage(systemName: data.conditionName)
            self.cityLabel.text = data.cityName
            self.temperatureLabel.text = data.tempratureString
            self.humidityLabel.text = "Humidity: \(data.humidityString)%"
            print(data.mode)
            if data.mode == "off"{
                self.powerButton.setImage(#imageLiteral(resourceName: "powerOff"), for: .normal)
                self.powerFlag = false
                self.setMode("pmv")
            }
            else{
                self.powerButton.setImage(#imageLiteral(resourceName: "PowerOn"), for: .normal)
                self.powerFlag = true
                self.setMode(data.mode)
            }
        }
    }
    func didFailServerInitialResponse(_ hawadaarManager: HawadaarManager, error: Error){
        DispatchQueue.main.async {
            self.showAlert(alertTitle: "Fail to connect", alertMessage: "\(error.localizedDescription)...\nPress Reconnect", alertActionTitle: "Reconnect"){UIAlertAction in
                self.hawadaarManager.connectToServer()
            }
        }
    }
    
    func didModeChanged(_ hawadaarManager: HawadaarManager, data: String){
        if modeFlag{
            DispatchQueue.main.async {
                self.setMode("sp")
                self.showServerMessage(data: data)
            }
        }
        else{
            DispatchQueue.main.async {
                self.setMode("pmv")
                self.showServerMessage(data: data)
            }
        }
    }
    func didModeChangeFail(_ hawadaarManager: HawadaarManager, error: Error){
        DispatchQueue.main.async {
            self.showAlert(alertTitle: "Error", alertMessage: "\(error.localizedDescription)", alertActionTitle: "Dismiss")
            self.powerButton.setImage(#imageLiteral(resourceName: "powerOff"), for: .normal)
            self.powerFlag = false
        }
    }
}

//MARK: - UIPickerView Delegate and Data source
extension ViewController: UIPickerViewDelegate{
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return String(format: "%.0f", pickerData[row])
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        self.spValFromPicker = pickerData[row]
        print(self.spValFromPicker)
    }
}

extension ViewController: UIPickerViewDataSource{
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return pickerData.count
    }
}
