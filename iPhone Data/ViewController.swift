//
//  ViewController.swift
//  iPhone Data
//
//  Created by Rodrigo Alejandro Juarez on 4/9/16.
//  Copyright © 2016 Rodrigo Alejandro Juarez. All rights reserved.
//

import UIKit
import SlackTextViewController
import LoremIpsum
import CoreBluetooth
import ReachabilitySwift
import SystemServices

let DEBUG_CUSTOM_TYPING_INDICATOR = false

class ViewController: SLKTextViewController {
    
    var messages = [Message]()
    var commands = ["wifi", "brightness", "battery"]
    var searchResult: [AnyObject]?
    var reachability: Reachability?
    var systemServices:SystemServices = SystemServices()
    
    override func viewWillAppear(animated: Bool) {
        //declare this inside of viewWillAppear
        do {
            self.reachability = try Reachability.reachabilityForInternetConnection()
        } catch {
            print("Unable to create Reachability")
            return
        }
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector:"reachabilityChanged:",name: ReachabilityChangedNotification,object: self.reachability)
        do{
            try self.reachability?.startNotifier()
        } catch {
            print("could not start reachability notifier")
        }
        
        UIDevice.currentDevice().batteryMonitoringEnabled = true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.

        self.tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: "cell")
        
        self.bounces = true
        self.shakeToClearEnabled = true
        self.keyboardPanningEnabled = true
        self.shouldScrollToBottomAfterKeyboardShows = false
        self.inverted = true
        
        self.rightButton.setTitle(NSLocalizedString("Send", comment: ""), forState: .Normal)
        
        
        self.textInputbar.autoHideRightButton = true
        self.textInputbar.maxCharCount = 256
        self.textInputbar.counterStyle = .Split
        self.textInputbar.counterPosition = .Top
        
        self.textInputbar.editorTitle.textColor = UIColor.darkGrayColor()
        self.textInputbar.editorLeftButton.tintColor = UIColor(red: 0/255, green: 122/255, blue: 255/255, alpha: 1)
        self.textInputbar.editorRightButton.tintColor = UIColor(red: 0/255, green: 122/255, blue: 255/255, alpha: 1)
        
        if DEBUG_CUSTOM_TYPING_INDICATOR == false {
            self.typingIndicatorView!.canResignByTouch = true
        }
        
        self.autoCompletionView.registerClass(UITableViewCell.classForCoder(), forCellReuseIdentifier: "autocompleteCell")
        self.registerPrefixesForAutoCompletion(["@",  "#", ":", "+:", "/"])
        
        if let tableView = self.tableView {
            tableView.separatorStyle = .None
        }
    }
    
    override class func tableViewStyleForCoder(decoder: NSCoder) -> UITableViewStyle {
        return .Plain
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func reachabilityChanged(note: NSNotification) {
        self.reachability = note.object as? Reachability
    }

    override func didPressRightButton(sender: AnyObject!) {

        let message = Message()
        message.username = LoremIpsum.name()
        message.text = self.textView.text
        
        let indexPath = NSIndexPath(forRow: 0, inSection: 0)
        let rowAnimation: UITableViewRowAnimation = self.inverted ? .Bottom : .Top
        let scrollPosition: UITableViewScrollPosition = self.inverted ? .Bottom : .Top
        
        self.tableView!.beginUpdates()
        self.messages.insert(message, atIndex: 0)
        self.tableView!.insertRowsAtIndexPaths([indexPath], withRowAnimation: rowAnimation)
        self.tableView!.endUpdates()
        
        if(self.textView.text == "/wifi ") {
            self.executeWifiCommand()
        } else if(self.textView.text == "/battery ") {
            self.executeBatteryCommand()
        } else if(self.textView.text == "/brightness ") {
            self.executeBrightnessCommand()
        }
        
        self.tableView!.scrollToRowAtIndexPath(indexPath, atScrollPosition: scrollPosition, animated: true)
        
        // Fixes the cell from blinking (because of the transform, when using translucent cells)
        // See https://github.com/slackhq/SlackTextViewController/issues/94#issuecomment-69929927
        self.tableView!.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
        
        
        super.didPressRightButton(sender)
    }
    
    func executeWifiCommand () {
        let message = Message()
        
        if self.reachability!.isReachable() {
            if self.reachability!.isReachableViaWiFi() {
                message.text = "Reachable via WiFi"
            } else {
                message.text = "Reachable via Cellular"
            }
        } else {
            message.text = "Network not reachable"
        }
        
        message.username = LoremIpsum.name()
        
        let indexPath = NSIndexPath(forRow: 0, inSection: 0)
        let rowAnimation: UITableViewRowAnimation = self.inverted ? .Bottom : .Top
        let scrollPosition: UITableViewScrollPosition = self.inverted ? .Bottom : .Top
        
        self.tableView!.beginUpdates()
        self.messages.insert(message, atIndex: 0)
        self.tableView!.insertRowsAtIndexPaths([indexPath], withRowAnimation: rowAnimation)
        self.tableView!.endUpdates()
    }
    
    func executeBatteryCommand () {
        let message = Message()
        
        var batteryLeft = UIDevice.currentDevice().batteryLevel
        
        batteryLeft *= 100
        
        message.text = String.localizedStringWithFormat("Battery level: %.0f%%", batteryLeft)
        
        message.username = LoremIpsum.name()
        
        let indexPath = NSIndexPath(forRow: 0, inSection: 0)
        let rowAnimation: UITableViewRowAnimation = self.inverted ? .Bottom : .Top
        let scrollPosition: UITableViewScrollPosition = self.inverted ? .Bottom : .Top
        
        self.tableView!.beginUpdates()
        self.messages.insert(message, atIndex: 0)
        self.tableView!.insertRowsAtIndexPaths([indexPath], withRowAnimation: rowAnimation)
        self.tableView!.endUpdates()
    }
    
    func executeBrightnessCommand () {
        let message = Message()
        
        message.text = String.localizedStringWithFormat("Brightness percentage: %.0f%%", self.systemServices.screenBrightness)
        
        message.username = LoremIpsum.name()
        
        let indexPath = NSIndexPath(forRow: 0, inSection: 0)
        let rowAnimation: UITableViewRowAnimation = self.inverted ? .Bottom : .Top
        let scrollPosition: UITableViewScrollPosition = self.inverted ? .Bottom : .Top
        
        self.tableView!.beginUpdates()
        self.messages.insert(message, atIndex: 0)
        self.tableView!.insertRowsAtIndexPaths([indexPath], withRowAnimation: rowAnimation)
        self.tableView!.endUpdates()
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == self.tableView {
            return self.messages.count
        }
        else {
            if let searchResult = self.searchResult {
                return searchResult.count
            }
        }
        
        return 0
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        if tableView == self.tableView {
            return self.messageCellForRowAtIndexPath(indexPath)
        }
        else {
            return self.autoCompletionCellForRowAtIndexPath(indexPath)
        }
    }

    func messageCellForRowAtIndexPath(indexPath: NSIndexPath) -> UITableViewCell {

        let cell = self.tableView.dequeueReusableCellWithIdentifier("cell")! as UITableViewCell
        
        let message = self.messages[indexPath.row]
        
        cell.textLabel?.text = message.text as String
        
        // Cells must inherit the table view's transform
        // This is very important, since the main table view may be inverted
        cell.transform = self.tableView!.transform

        return cell
    }
    
    override func didChangeAutoCompletionPrefix(prefix: String, andWord word: String) {
        var array: [AnyObject]?
        
        self.searchResult = nil

        if prefix == "/" && self.foundPrefixRange.location == 0 {
            if word.characters.count > 0 {
                array = (self.commands as NSArray).filteredArrayUsingPredicate(NSPredicate(format: "self BEGINSWITH[c] %@", word))
            }
            else {
                array = self.commands
            }
        }
        
        
        var show = false
        
        if  array?.count > 0 {
            self.searchResult = (array! as NSArray).sortedArrayUsingSelector(#selector(NSString.localizedCaseInsensitiveCompare(_:)))
            show = (self.searchResult?.count > 0)
        }
        
        self.showAutoCompletionView(show)
    }

    override func heightForAutoCompletionView() -> CGFloat {
        
        guard let searchResult = self.searchResult else {
            return 0
        }
        
        let cellHeight = self.autoCompletionView.delegate?.tableView!(self.autoCompletionView, heightForRowAtIndexPath: NSIndexPath(forRow: 0, inSection: 0))
        guard let height = cellHeight else {
            return 0
        }
        return height * CGFloat(searchResult.count)
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if tableView == self.autoCompletionView {
            
            guard let searchResult = self.searchResult as? [String] else {
                return
            }
            
            var item = searchResult[indexPath.row]
            
            item += " "
            
            self.acceptAutoCompletionWithString(item, keepPrefix: true)
        }
    }

    func autoCompletionCellForRowAtIndexPath(indexPath: NSIndexPath) -> UITableViewCell {
        let cell = self.autoCompletionView.dequeueReusableCellWithIdentifier("autocompleteCell")! as UITableViewCell
        cell.selectionStyle = .Default
        
        guard let searchResult = self.searchResult as? [String] else {
            return cell
        }
        
        guard self.foundPrefix != nil else {
            return cell
        }
        
        let text = searchResult[indexPath.row]
        
        cell.textLabel?.text = text as String
        
        return cell
    }
    
    override func textViewShouldBeginEditing(textView: UITextView) -> Bool {
        return true
    }
    
    override func textViewShouldEndEditing(textView: UITextView) -> Bool {
        // Since SLKTextViewController uses UIScrollViewDelegate to update a few things, it is important that if you override this method, to call super.
        return true
    }

    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        
        if tableView == self.tableView {
            let message = self.messages[indexPath.row]
            
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineBreakMode = .ByWordWrapping
            paragraphStyle.alignment = .Left
            
            let pointSize = CGFloat(20)
            
            let attributes = [
                NSFontAttributeName : UIFont.systemFontOfSize(pointSize),
                NSParagraphStyleAttributeName : paragraphStyle
            ]
            
            var width = CGRectGetWidth(tableView.frame)
            width -= 25.0
            
            let titleBounds = (message.username as NSString).boundingRectWithSize(CGSize(width: width, height: CGFloat.max), options: .UsesLineFragmentOrigin, attributes: attributes, context: nil)
            let bodyBounds = (message.text as NSString).boundingRectWithSize(CGSize(width: width, height: CGFloat.max), options: .UsesLineFragmentOrigin, attributes: attributes, context: nil)
            
            if message.text.length == 0 {
                return 0
            }
            
            var height = CGRectGetHeight(titleBounds)
            height += CGRectGetHeight(bodyBounds)
            height += 40
            
            return height
        }
        else {
            return 20
        }
    }
    
    func shouldProcessTextForAutoCompletion(text: String) -> Bool {
        return true
    }
    
}

