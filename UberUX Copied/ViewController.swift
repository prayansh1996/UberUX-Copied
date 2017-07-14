//
//  ViewController.swift
//  UberUX
//
//  Created by Pawan on 05/06/17.
//  Copyright © 2017 Pawan. All rights reserved.
//

//passphrase = 123

import UIKit

let borderThickness = CGFloat(5)
let cornerRadius = CGFloat(4.0)

extension UIView {
    
    func dropShadow(scale: Bool = true) {
        
        self.layer.masksToBounds = false
        self.layer.shadowColor = UIColor.black.cgColor
        self.layer.shadowOpacity = 0.5
        self.layer.shadowOffset = CGSize(width: 0, height: 0)
        self.layer.shadowRadius = 3.5
        let bounds = self.bounds
//        let shadowRect = CGRect(x: bounds.origin.x - borderThickness, y: bounds.origin.y - borderThickness, width: bounds.width + 2*borderThickness, height: bounds.height)
        
        let shadowRect = CGRect(x: bounds.origin.x, y: bounds.origin.y, width: bounds.width, height: bounds.height)
        let boxShadowRect = UIBezierPath(rect: shadowRect)
        //let roundedShadowRect = UIBezierPath(roundedRect: shadowRect, cornerRadius: cornerRadius)
        
        self.layer.shadowPath = boxShadowRect.cgPath//UIBezierPath(rect:shadowRect).cgPath
        self.layer.shouldRasterize = true
        self.layer.rasterizationScale = scale ? UIScreen.main.scale : 1
    }
}

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet var backView: UIView!
    @IBOutlet var timelineView: UIView!
    @IBOutlet weak var backgroundView: UIImageView! //Background Image View
    @IBOutlet weak var tableV: UITableView!
    @IBOutlet weak var burgerKingLabel: UILabel!
    @IBOutlet weak var headerButton: UIButton!
    @IBOutlet weak var headerView: UIView!
    var refreshControl: UIRefreshControl!
    var borderOverlay = UIView()
    
    var initialTimelineViewCenterY = CGFloat(0)
    var initialTimelineViewOriginX = CGFloat(0)
    var initialTimelineViewWidth = CGFloat(0)
    var initialBurgerKingCenterX = CGFloat(0)
    var initialHeaderViewWidth = CGFloat(0)
    
    var rangeForTransition = CGFloat(0)
    var paddingFromTop = CGFloat(16)
    var paddingFromLeft = CGFloat(0)
    let paddingFromViewsCenter = CGFloat(50)
    
    let primaryColor = UIColor(red: 237.0/255.0, green: 120.0/255.0, blue: 0.0, alpha: 1)
    
    //is Timeline View at top
    var isAtTop: Bool {
        get {
            return timelineViewCenterY == self.view.center.y + paddingFromTop ? true : false
        }
    }
    
    var timelineViewCenterY: CGFloat {
        get {
            return timelineView.center.y
        } set {
            timelineView.center.y = newValue
            updateFrames(withValue: newValue)
        }
    }
    
    var timelineViewTopY: CGFloat {
        get {
            return timelineView.frame.origin.y
        }
    }
    
    //Do all the animations
    func updateFrames(withValue center: CGFloat) {
        let transition = (initialTimelineViewCenterY - center) / (rangeForTransition)
        let invTransition = 1 - transition
        backView.alpha = transition
        self.navigationController?.navigationBar.alpha = invTransition
        //headerButton.alpha = transition
        
        var (red, green, blue) = (CGFloat(0), CGFloat(0), CGFloat(0))
        primaryColor.getRed(&red, green: &green, blue: &blue, alpha: nil)
        
        let primaryToWhite = UIColor(red: red+(1.0-red)*transition, green: green+(1.0-green)*transition, blue: blue+(1.0-blue)*transition, alpha: 1)
        let whiteToPrimary = UIColor(red: red+(1.0-red)*invTransition, green: green+(1.0-green)*invTransition, blue: blue+(1.0-blue)*invTransition, alpha: 1)
        
        headerView.backgroundColor = whiteToPrimary
        burgerKingLabel.textColor = primaryToWhite
        self.burgerKingLabel.center.x = initialBurgerKingCenterX + transition * (self.view.center.x - paddingFromLeft - initialBurgerKingCenterX)
        
        let newOrigin = initialTimelineViewOriginX - (paddingFromLeft * transition) - paddingFromLeft
        let newWidth = initialTimelineViewWidth + (2 * paddingFromLeft) * transition
        tableV.frame.origin.x = newOrigin
        tableV.frame.size.width = newWidth
        
        
        let transformScale = (2 * paddingFromLeft) / initialHeaderViewWidth
        headerView.transform = CGAffineTransform.identity
        headerView.transform = CGAffineTransform(scaleX: 1 + transition * transformScale, y: 1.0)
        //print("Absolute Scale: \(transformScale)\nTransition:\(transition)\nTransform Scale:\(transformScale * transition)")
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        //print("Non Updated Center: \(timelineViewCenterY)")
        timelineView.dropShadow(scale: true)
        timelineView.center.y = backgroundView.frame.origin.y + backgroundView.frame.height + timelineView.frame.height / 2
        //print("Updated Center: \(timelineViewCenterY)")
        
        initialTimelineViewCenterY = timelineViewCenterY
        initialTimelineViewOriginX = timelineView.frame.origin.x
        initialTimelineViewWidth = timelineView.frame.width
        initialBurgerKingCenterX = burgerKingLabel.center.x
        initialHeaderViewWidth = headerView.frame.width
        
        rangeForTransition = initialTimelineViewCenterY - (self.view.center.y + paddingFromTop)
        backView.backgroundColor = primaryColor
        burgerKingLabel.textColor = primaryColor
        
        headerView.backgroundColor = UIColor.white
        headerView.layer.cornerRadius = cornerRadius
//        headerView.layer.borderWidth = borderThickness
//        headerView.layer.borderColor = UIColor.black.cgColor
        headerButton.isEnabled = false
        headerButton.alpha = 0
        
//        tableV.layer.borderWidth = borderThickness
//        tableV.layer.borderColor = UIColor.black.cgColor
        
//        borderOverlay.frame = CGRect(x: tableV.frame.origin.x, y: tableV.frame.origin.y - borderThickness, width: tableV.frame.width, height: borderThickness*10)
//        borderOverlay.backgroundColor = UIColor.red
//        self.view.addSubview(borderOverlay)
        
        paddingFromLeft = (self.view.frame.width - timelineView.frame.width) / 2
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableV.dataSource = self
        refreshControl = UIRefreshControl()
        refreshControl.tintColor = UIColor.clear
        refreshControl.addTarget(self, action: #selector(ViewController.refresh), for: UIControlEvents.valueChanged)
        tableV.addSubview(refreshControl)
    }
    
    @IBAction func didTapOnTimelineHeader(_ sender: UITapGestureRecognizer) {
        if isAtTop {
            moveBack(view: timelineView)
        } else {
            moveToTop(view: timelineView)
        }
    }
    
    @IBAction func performPanGesture(_ gestureRecognizer: UIPanGestureRecognizer) {
        //print(timelineViewCenterY)
        //print("Trigger: \(timelineViewTopY - (self.view.center.y - paddingFromViewsCenter))")
        if gestureRecognizer.state == .ended {
            //print(timelineViewTopY)
            if timelineViewTopY <= self.view.center.y - paddingFromViewsCenter {
                moveToTop(view: timelineView)
            } else {
                moveBack(view: timelineView)
            }
            
        }
        
        let translation = gestureRecognizer.translation(in: self.view).y
        timelineViewCenterY += translation
        
        if timelineViewCenterY >= initialTimelineViewCenterY {
            timelineViewCenterY = initialTimelineViewCenterY
        } else if timelineViewCenterY <= self.view.center.y + paddingFromTop {
            timelineViewCenterY = self.view.center.y + paddingFromTop
        }
        gestureRecognizer.setTranslation(CGPoint(x: 0, y: 0), in: self.view)
        
    }
    
    func refresh() {
        moveBack(view: timelineView)
        tableV.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: false)
        refreshControl.endRefreshing()
    }
    
    func moveToTop(view: UIView) {
        //self.navigationController?.setNavigationBarHidden(true, animated: true)
        self.navigationController?.navigationBar.layer.zPosition = -1
        UIView.animate(withDuration: 0.3 , delay: 0.0, options: .curveEaseOut, animations: {
            view.center.y = self.view.center.y + self.paddingFromTop
            self.updateFrames(withValue: self.timelineViewCenterY)
            //self.headerButton.isEnabled = true
        })
    }
    
    func moveBack(view: UIView) {
        //self.navigationController?.setNavigationBarHidden(false, animated: true)
        self.navigationController?.navigationBar.layer.zPosition = 0
        UIView.animate(withDuration: 0.4 , delay: 0.0, options: .curveEaseOut, animations: {
            view.center.y = self.initialTimelineViewCenterY
            self.updateFrames(withValue: self.timelineViewCenterY)
            self.headerButton.isEnabled = false
        })
    }
    
    //TableView Functions
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 5
    }
    
    let namesOfItems = ["Burgers", "Wraps", "Shakes", "Drinks", "Ice Cream"]
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = namesOfItems[indexPath.row]
        return cell
    }
}



//+ 8.0 * transition
//timelineViewWidth.constant = self.view.frame.width - 32 * (timelineViewCenterY - self.view.center.y) / (rangeForTransition)
//burgerKingLabel.center.x = 8 + burgerKingLabel.frame.width / 2

/*
 let newOrigin = initialTimelineViewOriginX - 8 * transition
 let newWidth = initialTimelineViewWidth + 16 * transition
 
 var frameForTimelineView = self.timelineView.frame
 var frameForHeaderView = self.timelineView.viewWithTag(101)?.frame
 var frameForTableView = self.timelineView.viewWithTag(102)?.frame
 
 frameForTimelineView.size.width = newWidth
 frameForTimelineView.origin.x = newOrigin
 self.timelineView.frame = frameForTimelineView
 
 frameForHeaderView?.size.width = newWidth
 frameForHeaderView?.origin.x = newOrigin
 self.timelineView.viewWithTag(101)?.frame = frameForHeaderView!
 
 frameForTableView?.size.width = newWidth
 frameForTableView?.origin.x = newOrigin
 self.timelineView.viewWithTag(102)?.frame = frameForTableView!
 */



//    enum TranslateDirections {
//        case up
//        case down
//        case none
//    }
//
//    var translateDirection = TranslateDirections.none

//        let heightConstraint = NSLayoutConstraint(item: timelineView, attribute: NSLayoutAttribute.height, relatedBy: NSLayoutRelation.equal, toItem: nil, attribute: NSLayoutAttribute.notAnAttribute, multiplier: 1, constant: self.view.frame.height)
//        view.addConstraints([heightConstraint])



//
//        if gestureRecognizer.state == UIGestureRecognizerState.began || gestureRecognizer.state == UIGestureRecognizerState.changed {
//
//            let translation = gestureRecognizer.translation(in: self.view)
//
//            if(gestureRecognizer.view!.center.y < 555) {
//                timelineView.center = CGPoint(x: gestureRecognizer.view!.center.x, y: gestureRecognizer.view!.center.y + translation.y)
//            }else {
//                timelineView.center = CGPoint(x: gestureRecognizer.view!.center.x, y: 554)
//            }
//
//            gestureRecognizer.setTranslation(CGPoint(x: 0, y: 0),  in: self.view)
//
//        }
//

//      let location = gestureRecognizer.location(in: self.view)
//        backView.alpha = 1.0 - ((location.y - 100) / 520)
//        print(timelineView.center.y - location.y)
//        timelineView.transform = CGAffineTransform(translationX: 0, y: -(timelineView.center.y - location.y))

//        backView.alpha = 1.0 - ((timelineViewOriginY - 100) / 520)
//        print(timelineView.center)
//        print(gestureRecognizer.translation(in: self.view).y)

