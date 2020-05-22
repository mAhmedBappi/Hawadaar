//
//  SettingsViewController.swift
//  Hawadaar
//
//  Created by Muhammad Ahmed Bappi on 15/05/2020.
//  Copyright © 2020 Muhammad Ahmed Bappi. All rights reserved.
//

import UIKit

class SettingsViewController: UIViewController {
    let orangeColor = UIColor(red: 1.00, green: 0.36, blue: 0.00, alpha: 1.00)
    let grayColor =  UIColor(red: 0.20, green: 0.21, blue: 0.25, alpha: 1.00)
    let darkBlueColor = UIColor(red: 0.09, green: 0.10, blue: 0.14, alpha: 1.00)
    
    var settingsManager = SettingsManager()
    var picker = UIView()
    var pickerLabel = ""
    var rowSelected = 0
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var logoView: UIView!
    @IBOutlet weak var hawadaarTitle: UILabel!
    @IBOutlet weak var settingPanelTitle: UILabel!
    @IBOutlet weak var updateButton: UIButton!
    @IBOutlet weak var serverMessageLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setNavBarProperties()
        logoView.backgroundColor = orangeColor
        updateButton.backgroundColor = orangeColor
        setTableViewProperties()
        settingsManager.delegate = self
        serverMessageLabel.alpha = 0
    }
    
    @IBAction func updatePressed(_ sender: UIButton) {
        settingsManager.updateParamsRequest()
    }
    
    func setNavBarProperties(){
        self.title = "Settings"
        self.navigationController?.navigationBar.barTintColor = darkBlueColor
        self.navigationController?.navigationBar.tintColor = .white
        let textAttributes = [NSAttributedString.Key.foregroundColor:UIColor.white]
        self.navigationController?.navigationBar.titleTextAttributes = textAttributes
    }
    
    func setTableViewProperties(){
        tableView.dataSource = self
        tableView.delegate = self
        tableView.separatorColor = .white
        tableView.backgroundColor = UIColor.clear
        tableView.tableFooterView = UIView()
    }
    
    func setPickerView(){
        let heightOfView: CGFloat = 450.0
        picker.frame = CGRect(x: 15, y: (view.frame.height/2) - heightOfView/2, width: view.frame.width-30, height: heightOfView)
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
        label.text = self.pickerLabel
        return label
    }
    
    @objc func doneTapped(){
        switch rowSelected {
        case 0:
            settingsManager.tol = settingsManager.tempChangedValues[0]
        case 1:
            settingsManager.pmvCRange = settingsManager.tempChangedValues[1]
        case 2:
            settingsManager.metValue = settingsManager.stringToValue("met", str: settingsManager.tempChangedValues[2])
        case 3:
            settingsManager.cloValue = settingsManager.stringToValue("clo", str: settingsManager.tempChangedValues[3])
        default:
            print("error after done")
        }
        self.tableView.reloadData()
        picker.removeFromSuperview()
        picker = UIView()
    }
    
    @objc func cancelTapped(){
        self.tableView.reloadData()
        picker.removeFromSuperview()
        picker = UIView()
    }
    
    func tableRowPressed(title: String, rowVal: Int){
        self.pickerLabel = title
        rowSelected = rowVal
        setPickerView()
        view.addSubview(picker)
    }
    
    func showAlert(alertTitle: String, alertMessage: String, alertActionTitle: String, afterDismiss: ((UIAlertAction) -> Void)? = nil){
        let alertController = UIAlertController(title: alertTitle, message: alertMessage, preferredStyle: .alert)
        let dismissButton = UIAlertAction(title: alertActionTitle, style: .default, handler: afterDismiss)
        alertController.addAction(dismissButton)
        self.present(alertController, animated: true, completion: nil)
    }
    
    func showServerMessage(data: String){
        serverMessageLabel.text = data
        serverMessageLabel.alpha = 1
        UIView.animate(withDuration: 5, animations: { () -> Void in
            self.serverMessageLabel.alpha = 0
        })
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

extension SettingsViewController: UITableViewDataSource, UITableViewDelegate{
    func numberOfSections(in tableView: UITableView) -> Int {
        return self.settingsManager.sections.count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return self.settingsManager.sections[section]
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.settingsManager.numOfRows[section]
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "tableViewCell", for: indexPath)
        
        cell.textLabel?.text = settingsManager.sectionLabels[indexPath.section][indexPath.row]
        cell.backgroundColor = orangeColor
        cell.detailTextLabel?.text = settingsManager.sectionDetailLabels[indexPath.section][indexPath.row]
        cell.detailTextLabel?.textColor = grayColor
        cell.textLabel?.textColor = .white
        return cell
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UILabel(frame: CGRect(origin: CGPoint.zero, size: CGSize(width: self.view.frame.width, height: 61)))
        let label = UILabel(frame: CGRect(x: 10, y: headerView.frame.height-35, width: self.view.frame.width, height: 30))
        label.textColor = .lightGray
        label.text = settingsManager.sections[section]
        headerView.addSubview(label)
        return headerView

    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 61.0
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 0{
            self.tableRowPressed(title: "Select the SET POINT tolerence", rowVal: 0)
        }
        else{
            switch indexPath.row {
            case 0:
                self.tableRowPressed(title: "Select the PMV comfort range", rowVal: 1)
                
            case 1:
                self.tableRowPressed(title: "Select the metabolic activity", rowVal: 2)
            case 2:
                self.tableRowPressed(title: "Select the type of clothes", rowVal: 3)
            default:
                print("Error after selecting table row")
            }
        }
    }
    
}

extension SettingsViewController: UIPickerViewDelegate{
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        switch rowSelected {
        case 0:
            return settingsManager.tolValuesForPicker[row]
        case 1:
            return settingsManager.cRangeValuesForPicker[row]
        case 2:
            return settingsManager.metValuesForPicker[row]
        case 3:
            return settingsManager.cloValuesForPicker[row]
        default:
            return "Error"
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        switch rowSelected{
        case 0:
            settingsManager.tempChangedValues[0] = settingsManager.tolValuesForPicker[row]
        case 1:
            settingsManager.tempChangedValues[1] = settingsManager.cRangeValuesForPicker[row]
        case 2:
            settingsManager.tempChangedValues[2] = settingsManager.metValuesForPicker[row]
        case 3:
            settingsManager.tempChangedValues[3] = settingsManager.cloValuesForPicker[row]
        default:
            print("select row default case")
        }
    }
}

extension SettingsViewController: UIPickerViewDataSource{
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        switch rowSelected{
        case 0:
            return settingsManager.tolValuesForPicker.count
        case 1:
            return settingsManager.cRangeValuesForPicker.count
        case 2:
            return settingsManager.metValuesForPicker.count
        case 3:
            return settingsManager.cloValuesForPicker.count
        default:
            return 1
        }
    }
}

extension SettingsViewController: SettingsManagerDelegate{
    func didFailWithError(_ settingsManager: SettingsManager, error: Error) {
        DispatchQueue.main.async{
            self.showAlert(alertTitle: "Error", alertMessage: error.localizedDescription, alertActionTitle: "Dismiss")
        }
    }
    
    func didServerResponse(_ settingsManager: SettingsManager, data: String) {
        DispatchQueue.main.async {
            self.showServerMessage(data: data)
        }
    }
    
    
}
