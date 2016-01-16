//
//  TVViewController.swift
//  WGTD Radio App
//
//  Created by Kyle Zawacki on 11/18/15.
//  Copyright © 2015 University Of Wiscosnin Parkside. All rights reserved.
//

import UIKit
import ChannelDropdown

class TVViewController: UIViewController {

    // MARK: Properties
    @IBOutlet weak var waveContainer: UIView!
    var waveView:WaveView?
    var audioPlayer:FSAudioStream?
    var stkPlayer:STKAudioPlayer?
    var channelIndex:Int = 0
    var playing:Bool = false
    @IBOutlet weak var background: UIView!
    @IBOutlet weak var stationImage: UIImageView!
    @IBOutlet var stationButtonCollection: [UIView]!
    var streamReady = false
    var notification:JFMinimalNotification?
    
    let stationUrls = ["http://media.gtc.edu:8000/stream",
        "http://199.255.3.11:88/broadwave.mp3?src=1&rate=1&ref=http%3A%2F%2Fwww.wgtd.org%2Fhd2.asp",
        "http://199.255.3.11:88/broadwave.mp3?src=4&rate=1&ref=http%3A%2F%2Fwww.wgtd.org%2Freading.asp",
        "http://sportsweb.gtc.edu:8000/stream"]
    let stationImageNames = ["Classical", "Jazz", "Reading","Sports"]
    
    // MARK: Initialization
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupAudioPlayers()
        
        let tapRecognizer = UITapGestureRecognizer(target: self, action: "hitPlayPause")
        tapRecognizer.allowedPressTypes = [NSNumber(integer: UIPressType.PlayPause.rawValue)];
        self.view.addGestureRecognizer(tapRecognizer)
    }
    
    override func viewWillAppear(animated: Bool) {
        self.waveView = WaveView(frame: self.waveContainer.frame)
        self.waveView!.center = self.waveContainer.center;
        self.waveView!.backgroundColor = UIColor.clearColor()
        self.waveView!.waveColor = self.view.tintColor;
        self.waveView!.idleAmplitude = 0.02;
        self.view.addSubview(self.waveView!)
        
        scheduleWaveViewUpdates()
        
        playStationAtCurrentIndex()
    }
    
    func setupAudioPlayers()
    {
        self.stkPlayer = STKAudioPlayer()
        var options = self.stkPlayer!.options
        options.enableVolumeMixer = true
        
        self.stkPlayer = STKAudioPlayer(options: options)
        self.stkPlayer!.meteringEnabled = true
        self.stkPlayer!.volume = 0.0
        
        self.audioPlayer = FSAudioStream()
        self.audioPlayer!.url = NSURL(string: stationUrls[self.channelIndex])
        
        self.audioPlayer!.onStateChange = {(state:FSAudioStreamState ) -> Void in
            if(state == kFsAudioStreamBuffering)
            {
                self.streamReady = false;
                
                if let notification = self.notification
                {
                    notification.dismiss()
                }
                
                self.notification = JFMinimalNotification(style: JFMinimalNotificationStytle.StyleWarning, title: "", subTitle: "Your stream is loading.....")
                self.notification!.presentFromTop = true
                
                self.view.addSubview(self.notification!)
                
                if let _ = self.notification!.superview
                {
                    self.notification!.show()
                }
                
            } else if(state == kFsAudioStreamPlaying)
            {
                self.streamReady = true;
                
                if let _ = self.notification
                {
                    self.notification!.dismiss()
                }
                
                self.notification = JFMinimalNotification(style: JFMinimalNotificationStytle.StyleSuccess, title: "", subTitle: "Your stream is now playing!", dismissalDelay: 1)
                self.notification!.presentFromTop = true
                
                self.view.sendSubviewToBack(self.notification!)
                
                self.view.addSubview(self.notification!)
                
                if let _ = self.notification!.superview
                {
                    self.notification!.show()
                }
                
            } else if(state == kFsAudioStreamFailed)
            {
                self.streamReady = false;
                
                if self.notification!.currentStyle != JFMinimalNotificationStytle.StyleError
                {
                    self.notification!.dismiss()
                    
                    self.notification = JFMinimalNotification(style: JFMinimalNotificationStytle.StyleError, title: "", subTitle: "There was an error!", dismissalDelay: 1)
                    self.notification!.presentFromTop = true
                    
                    self.view.addSubview(self.notification!)
                    
                    if let _ = self.notification!.superview
                    {
                        self.notification!.show()
                    }
                    
                    self.playing = false
                    self.streamReady = false
                }
            }
        }

    }
    
    //MARK: Wave View
    func scheduleWaveViewUpdates()
    {
        NSTimer.scheduledTimerWithTimeInterval(0.01, target: self, selector:"updateWaveView", userInfo: nil, repeats: true)
    }
    
    func updateWaveView()
    {
        if streamReady
        {
            if self.stkPlayer!.state == STKAudioPlayerStateError || stkPlayer!.state.rawValue == 16
            {
                waveView!.updateWithLevel(0.5)
                stkPlayer!.stop()
                stkPlayer!.play(stationUrls[channelIndex])
            } else
            {
                let level:CGFloat = CGFloat((self.stkPlayer!.averagePowerInDecibelsForChannel(1) + 60) / Float(60.0))
                
                self.waveView!.updateWithLevel(level)
            }
        } else
        {
            waveView!.updateWithLevel(0.01)
        }
    }
    
    // MARK: Main Functionality
    func playStationAtCurrentIndex()
    {
        self.audioPlayer!.url = NSURL(string: stationUrls[self.channelIndex])
        
        self.audioPlayer!.stop()
        self.stkPlayer!.stop()
        
        self.audioPlayer!.play()
        self.stkPlayer!.play(stationUrls[self.channelIndex])
        
        self.playing = true
        
        print(stationUrls[self.channelIndex])
    }
    
    func updateImageWithCurrentIndex()
    {
        stationImage.image = UIImage(named: stationImageNames[channelIndex])
    }
    
    func hitPlayPause()
    {
        if playing
        {
            self.stkPlayer!.stop()
            self.audioPlayer!.stop()
            
            if let _ = self.notification
            {
                notification!.dismiss()
            }
            
            playing = false
            streamReady = false
        } else
        {
            playStationAtCurrentIndex()
        }
    }
    
    // MARK: Focus Methods
    override func didUpdateFocusInContext(context: UIFocusUpdateContext, withAnimationCoordinator coordinator: UIFocusAnimationCoordinator)
    {
                
        if (context.previouslyFocusedView != nil) {
            animateUnfocus(context.previouslyFocusedView!)
        }
        
        if (context.nextFocusedView != nil) {
            animateFocus(context.nextFocusedView!)
        }
        
        if let _ = self.notification
        {
            notification!.dismiss()
        }
        
        playing = false
        streamReady = false
        
        channelIndex = stationButtonCollection.indexOf(context.nextFocusedView!)!
        playStationAtCurrentIndex()
        updateImageWithCurrentIndex()
    }
    
    
    func animateFocus(view:UIView)
    {
        UIView.animateWithDuration(0.12) { () -> Void in
            view.transform = CGAffineTransformMakeScale(1.3, 1.3)
        }
    }
    
    func animateUnfocus(view:UIView)
    {
        UIView.animateWithDuration(0.12) { () -> Void in
            view.transform = CGAffineTransformMakeScale(1, 1)
        }
    }
    
}
