//
//  ChannelDropdown.swift
//  WGTD Radio App
//
//  Created by Kyle Zawacki on 11/4/15.
//  Copyright © 2015 University Of Wiscosnin Parkside. All rights reserved.
//

import UIKit
import Foundation

@objc class ChannelDropdown: UIView, UIGestureRecognizerDelegate
{
    static let DROP_DOWN_CHANNEL_HEIGHT: CGFloat = 44
    
    var master: ViewController?
    
    var items:[String]?
    var title: String?
    var navColor: UIColor?
    
    var menuTable:MenuTable?
    var tableHeight: CGFloat?
    var dropDistance: CGFloat?
    var tableBackground:UIView?
    var blur: UIVisualEffectView?
    var line: UIView?
    
    var titleText:UILabel?
    var arrow: UIButton?
    var navController: UINavigationController?
    
    var menuDown = false
    
    var fullFrame:CGRect?
    var smallFrame:CGRect?
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    init(frame: CGRect, items: [String], title: String, nav: UINavigationController)
    {
        super.init(frame: CGRectMake(0, 0, frame.width, 60))
        
        self.fullFrame = frame
        self.smallFrame = self.frame
        
        self.items = items
        self.title = title
        
        self.navColor = nav.navigationBar.barTintColor
//        self.navColor = self.navColor!.colorWithAlphaComponent(0.7)
        self.navController = nav
        
        let tableHeight:CGFloat = CGFloat(self.items!.count * Int(ChannelDropdown.DROP_DOWN_CHANNEL_HEIGHT))
        
        self.menuTable = MenuTable(frame: CGRectMake(0, -tableHeight, frame.width, tableHeight))
        self.tableBackground = UIView(frame: CGRectMake(0,-tableHeight-130, frame.width, tableHeight))
        self.blur = UIVisualEffectView(effect: UIBlurEffect(style: UIBlurEffectStyle.Dark))
        blur!.frame = CGRectMake(0, 0, self.frame.size.width, self.fullFrame!.height * 2)
        blur!.alpha = 0
        
        self.menuTable!.backgroundColor = UIColor.clearColor()
        self.menuTable!.cellColor = navColor
        self.tableBackground!.backgroundColor = navColor
        self.menuTable!.items = items
        self.menuTable!.masterView = self
        
        self.addSubview(blur!)
        self.addSubview(tableBackground!)
        self.addSubview(menuTable!)
        
        titleText = UILabel(frame: CGRectMake(0, 20, 110, 40))
        titleText!.center = self.navController!.navigationBar.center
        titleText!.text = "Classical"
        titleText!.font = UIFont(descriptor: UIFontDescriptor(name: "Helvetica Neue Thin", size: 25), size: 25)
        titleText!.backgroundColor = UIColor.clearColor()
        titleText!.textAlignment = NSTextAlignment.Center
        titleText!.textColor = UIColor.whiteColor()
        self.addSubview(titleText!)
        
        let invisButton = UIButton(frame: CGRectMake(0, 0, titleText!.frame.size.width, titleText!.frame.height))
        invisButton.addTarget(self, action: "moveMenu", forControlEvents: UIControlEvents.TouchUpInside)
        invisButton.center = self.titleText!.center
        
        self.addSubview(invisButton)
        
        arrow = UIButton()
        arrow!.frame = CGRectMake(titleText!.frame.origin.x + titleText!.frame.size.width + 2, titleText!.frame.origin.y + titleText!.frame.size.height/2 - 7, 16, 16)
        arrow!.setImage(UIImage(named: "arrow"), forState: UIControlState.Normal)
//        arrow!.transform = CGAffineTransformRotate(arrow!.transform, CGFloat(M_PI * 0.5))
        self.addSubview(arrow!)
        
        arrow!.addTarget(self, action: "moveMenu", forControlEvents: UIControlEvents.TouchUpInside)
        
        self.tableHeight = tableHeight
        self.dropDistance = self.tableHeight! + ChannelDropdown.DROP_DOWN_CHANNEL_HEIGHT + 20
        
        let tapGesture = UITapGestureRecognizer(target: self, action: "moveMenu")
        blur!.addGestureRecognizer(tapGesture)
        
        let tapGesture2 = UITapGestureRecognizer(target: self, action: "moveMenu")
        tableBackground!.addGestureRecognizer(tapGesture2)
    }
    
    func moveMenu()
    {
        if !menuDown
        {
           showMenu()
        } else {
            tappedChannel((self.titleText?.text)!)
        }
    }
    
    func showMenu()
    {
        frame = fullFrame!
        
        line = UIView(frame: CGRectMake(0, self.navController!.navigationBar.frame.height + 20,self.frame.width, 1))
        line!.backgroundColor = UIColor.whiteColor().colorWithAlphaComponent(0.3)
        self.addSubview(line!)
        
        UIView.animateWithDuration(0.4, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.6 , options: [], animations: { () -> Void in
            self.menuTable!.frame.origin.y = self.menuTable!.frame.origin.y + self.dropDistance!
            self.tableBackground!.frame.origin.y = self.tableBackground!.frame.origin.y + self.dropDistance!
            }, completion: nil)
        
        UIView.animateWithDuration(0.2, delay: 0, options: [], animations: { () -> Void in
            self.arrow!.transform = CGAffineTransformRotate(self.arrow!.transform, CGFloat(M_PI * 1))
            }, completion: nil)
        
        UIView.animateWithDuration(0.1, delay: 0, options: [], animations: { () -> Void in
            self.blur!.alpha = 1.0    }, completion: nil)
        
        menuDown = true
    }
    
    func tappedChannel(channel:String)
    {
        UIView.animateKeyframesWithDuration(0.1, delay: 0, options: [], animations: { () -> Void in
            self.menuTable!.frame.origin.y = self.menuTable!.frame.origin.y + 15
            self.tableBackground!.frame.origin.y = self.tableBackground!.frame.origin.y + 15
            }) { (Bool) -> Void in
                UIView.animateWithDuration(0.25, animations: { () -> Void in
                    self.menuTable!.frame.origin.y = self.menuTable!.frame.origin.y + -(self.dropDistance!) + -15
                    self.tableBackground!.frame.origin.y = self.tableBackground!.frame.origin.y + -(self.dropDistance!) + -15
                })
        }
        
        UIView.animateWithDuration(0.2, delay: 0, options: [], animations: { () -> Void in
            self.arrow!.transform = CGAffineTransformRotate(self.arrow!.transform, CGFloat(M_PI * 1))
            }, completion: nil)
        
        UIView.animateWithDuration(0.1, delay: 0, options: [], animations: { () -> Void in
            self.blur!.alpha = 0
            }, completion: {(Bool) -> Void in
                self.line!.removeFromSuperview()
                self.menuTable!.reloadData()
                self.titleText!.text = channel
                self.frame = self.smallFrame!
        })
        
        master!.dropDownChosenWithChannel(channel)
        
        menuDown = false
    }
    
    class MenuTable:UITableView, UITableViewDataSource, UITableViewDelegate
    {
        var items:[String]?
        var cellColor:UIColor?
        var masterView: ChannelDropdown?
        
        override init(frame: CGRect, style: UITableViewStyle) {
            super.init(frame: frame, style: style)
            self.dataSource = self
            self.delegate = self
            self.separatorColor = UIColor.clearColor()
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
            let cell = UITableViewCell(frame: CGRectMake(0, 0, super.frame.width, ChannelDropdown.DROP_DOWN_CHANNEL_HEIGHT))
            cell.backgroundColor = self.cellColor
            let text = UILabel()
            text.text = items![indexPath.row]
            text.font = UIFont(descriptor: UIFontDescriptor(name: "Helvetica Neue Thin", size: 20), size: 25)
            text.textColor = UIColor.whiteColor()
            text.frame = CGRectMake(0, 0, self.frame.width, cell.frame.height)
            text.backgroundColor = UIColor.clearColor()
            text.textAlignment = NSTextAlignment.Center
            cell.addSubview(text)
            
            if indexPath.row != 0
            {
                let line = UIView(frame: CGRectMake(0, 0, self.frame.width, 1))
                line.backgroundColor = UIColor.whiteColor().colorWithAlphaComponent(0.3)
                cell.addSubview(line)
            }
            
            return cell
        }
        
        func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
            self.masterView!.tappedChannel(self.items![indexPath.row])
        }
        
        func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            return self.items!.count
        }
        
        func numberOfSectionsInTableView(tableView: UITableView) -> Int {
            return 1
        }
    }
}
