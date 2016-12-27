//
//  PopMenuView.swift
//  RadiusBlurMenu
//
//  Created by Farid on 7/19/16.
//  Copyright © 2016 Farid. All rights reserved.
//

import UIKit
import EasyPeasy
import PayWandBasicElements

@objc protocol PopMenuViewDelegate: class {
    
    func popMenuView(_ popMenuView : PopMenuView, shrink index : Int)
    
    func popMenuView(_ popMenuView : PopMenuView, grow index : Int)
}

class PopMenuView : NSObject {
    
    var button : UIButton!
    var buttonLabel : UILabel!
    var buttonLabelTopConstraint : NSLayoutConstraint!
    var effectView = UIVisualEffectView(effect: UIBlurEffect(style: .light))
    var heightConstraintBlurView : NSLayoutConstraint!
    var actionView : UIView!
    
    var transitionActionView : UIView!
    var transitionEffectView = UIVisualEffectView(effect: UIBlurEffect(style: .extraLight))
    
    var middleRect : CGRect!
    var largeRect : CGRect!
    var smallRect : CGRect!
    var smallMiddleRect : CGRect!
    
    var smallMiddleRectTransition : CGRect!
    var middleRectTransition : CGRect!
    
    var hideActionViewButton : UIButton!
    
    var mainView : UIView!
    var wholeView : UIView?
    
    var buttonState : ButtonState!
    enum ButtonState {
        case small
        case middle
        case large
    }
    
    typealias OnSelect = () -> ()
    var onSelect : OnSelect?
    
    /// Elastic Animation
    var delegate : PopMenuViewDelegate!
    var index = 0
    var centerXConstraint : NSLayoutConstraint!
    
    var touchedUpInside = false
    var touchedDown = false
    
    convenience init(mainView : UIView, position : CGPoint, icon : UIImage?, title : String, buttonHight : CGFloat, wholeView : UIView? = nil, index : Int = 0, onSelect : OnSelect?){
        self.init()
        self.mainView = mainView
        self.wholeView = wholeView
        
        addElements(position, icon: icon, title : title, buttonHight: buttonHight)
        self.index = index
        self.onSelect = onSelect
    }
    
    func addSubview(_ view: UIView) {
        actionView.addSubview(view)
    }
    
    func addElements(_ position : CGPoint, icon : UIImage?, title : String, buttonHight : CGFloat) {
        button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        mainView.addSubview(button)
        button <- [
            //CenterX(position.x - mainView.center.x),
            CenterY(position.y - mainView.center.y),
            Width(buttonHight),
            Height().like(button, .width)
        ]
        centerXConstraint = button.centerXAnchor.constraint(equalTo: mainView.centerXAnchor, constant: position.x - mainView.center.x)
        centerXConstraint.isActive = true
        
        button.layer.cornerRadius = buttonHight/2
        button.layer.masksToBounds = true
        button.backgroundColor = UIColor.TtroColors.darkBlue.color.withAlphaComponent(0.6)
        mainView.layoutIfNeeded()
        button.layoutIfNeeded()
        button.setImage(icon?.imageWithSize(button.frame.size.scale(0.6)), for: UIControlState())
//        button.setBackgroundImage(icon?.imageWithSize(button.frame.size.scale(0.5)), forState: .Normal)
//        button.setTitle("->", forState: .Normal)
        button.addTarget(self, action: #selector(self.onMenu(_:)), for: .touchUpInside)
        button.addTarget(self, action: #selector(self.onMenuTouch(_:)), for: .touchDown)
        button.addTarget(self, action: #selector(self.onMenuTouchUpOutside(_:)), for: .touchUpOutside)
        button.setTitleColor(UIColor.white, for: UIControlState())
        buttonState = ButtonState.small
        button.adjustsImageWhenHighlighted = false
        
        
        mainView.layoutIfNeeded()
        
        effectView.translatesAutoresizingMaskIntoConstraints = false
        mainView.insertSubview(effectView, belowSubview: button)
//        effectView <- [
//            CenterX().to(button),
//            CenterY().to(button),
//            Height().like(effectView, .Width),
//            Width(middleRect.width)
//        ]
        effectView <- Edges()
        
        effectView.isHidden = true
        
        actionView = UIView()
        actionView.translatesAutoresizingMaskIntoConstraints = false
        mainView.insertSubview(actionView, belowSubview: button)
//        actionView <- [
//            CenterX().to(button),
//            CenterY().to(button),
//            Height().like(actionView, .Width),
//            Width(smallMiddleRect.width)
//        ]
        
        actionView <- Edges()
        actionView.isHidden = true
        actionView.backgroundColor = UIColor.TtroColors.darkBlue.color
        
        buttonLabel = UILabel()
        buttonLabel.text = title
        buttonLabel.translatesAutoresizingMaskIntoConstraints = false
        buttonLabel.textColor = UIColor.TtroColors.white.color
        buttonLabel.alpha = 0
        buttonLabel.font = UIFont.TtroPayWandFonts.light3.font
        mainView.addSubview(buttonLabel)
        buttonLabel <- [
            CenterX().to(button),
            //Top(10).to(button, .bottom)
            Bottom(10).to(button, .top)
        ]

        // Transtion views
        transitionActionView = UIView()
        
        transitionActionView.translatesAutoresizingMaskIntoConstraints = false
        transitionActionView.backgroundColor = UIColor.TtroColors.darkBlue.color
        
        
        transitionEffectView.translatesAutoresizingMaskIntoConstraints = false
        
        //setMasks(buttonHight)
    }
    
    func setMasks(_ buttonHeight : CGFloat){
        
        
        smallRect = CGRect(origin: button.center, size: CGSize(width: 0,height: 0)).insetBy(dx: -buttonHeight/2, dy: -buttonHeight/2)
        smallMiddleRect = CGRect(origin: button.center, size: CGSize(width: 0,height: 0)).insetBy(dx: -(buttonHeight*1.1)/2, dy: -(buttonHeight*1.1)/2)
        middleRect = CGRect(origin: button.center, size: CGSize(width: 0,height: 0)).insetBy(dx: -(buttonHeight*1.3)/2, dy: -(buttonHeight*1.3)/2)

        setViewMask(effectView, rect: middleRect)
        setViewMask(actionView, rect: smallRect)
        
        let globalPoint = button.superview!.convert(button.center, to: wholeView)
        let maxDist = CGFloat(calcMaxDistance(globalPoint, view: wholeView!));
        largeRect = CGRect(origin: globalPoint, size: CGSize(width: 0,height: 0)).insetBy(dx: -maxDist, dy: -maxDist)

        smallMiddleRectTransition = CGRect(origin: globalPoint, size: CGSize(width: 0,height: 0)).insetBy(dx: -(buttonHeight*1.1)/2, dy: -(buttonHeight*1.1)/2)
        middleRectTransition = CGRect(origin: globalPoint, size: CGSize(width: 0,height: 0)).insetBy(dx: -(buttonHeight*1.3)/2, dy: -(buttonHeight*1.3)/2)
        setViewMask(transitionActionView, rect: smallMiddleRectTransition)
        setViewMask(transitionEffectView, rect: middleRectTransition)
        
        //print(smallRect, middleRect, largeRect)
    }
    
    func setViewMask(_ view : UIView, rect : CGRect){
        let smallCirclePath = UIBezierPath(ovalIn: rect).cgPath
        let mask = CAShapeLayer()
        mask.path = smallCirclePath
        mask.backgroundColor = UIColor.black.cgColor
        view.layer.mask = mask
    }
    
    func onMenuTouch(_ sender : UIButton){
        //effectView.hidden = false
        touchedDownGrowMask()
    }
    
    
    func onMenu(_ sender : UIButton){
        touchedUpInside = true
        if (!touchedDown){
            if (self.onSelect != nil){
                self.onSelect!()
            } else {
                self.shrinkMask()
            }
        }
    }
    
    func onMenuTouchUpOutside(_ sender : UIButton){
        if (buttonState == ButtonState.middle){
            shrinkMask()
        }
    }
    
    func getPopTransitionAnime(_ duration : TimeInterval) -> CABasicAnimation {
        let largeCirclePath = UIBezierPath(ovalIn: largeRect).cgPath
        let anime = CABasicAnimation(keyPath: "path")
        anime.toValue = largeCirclePath
        anime.fillMode = kCAFillModeForwards
        anime.isRemovedOnCompletion = false
        anime.duration = duration
        //anim.repeatCount = Float.infinity
        //anim.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
        anime.autoreverses = false
        //anim.delegate = self
        return anime
    }
    
    func getDismissTransitionAnime(_ duration : TimeInterval) -> CABasicAnimation {
        let smallCirclePath = UIBezierPath(ovalIn: smallMiddleRectTransition).cgPath
        let anime = CABasicAnimation(keyPath: "path")
        anime.toValue = smallCirclePath
        anime.fillMode = kCAFillModeForwards
        anime.isRemovedOnCompletion = false
        anime.duration = duration
        anime.autoreverses = false
        return anime
    }
    
    func setMaskAfterAnimation(_ dissmissed : Bool){
        if (dissmissed){
            setViewMask(transitionEffectView, rect: smallMiddleRectTransition)
            setViewMask(transitionActionView, rect: smallMiddleRectTransition)
        } else {
            setViewMask(transitionEffectView, rect: largeRect)
            setViewMask(transitionActionView, rect: largeRect)
            shrinkMask()
            touchedUpInside = false
        }
    }

    func shrinkMask() {
        effectView.isHidden = true
        actionView.isHidden = true
        
        if (buttonState == ButtonState.small){
            return
        }
        
        let smallCirclePath = UIBezierPath(ovalIn: smallRect).cgPath
        let anim = CABasicAnimation(keyPath: "path")
        anim.toValue = smallCirclePath
        anim.fillMode = kCAFillModeForwards
        anim.isRemovedOnCompletion = false
        anim.duration = 0.5
        //anim.repeatCount = Float.infinity
        anim.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
        anim.autoreverses = false
        //anim.delegate = self
        effectView.layer.mask!.add(anim, forKey: "path")
        
        actionView.layer.mask?.add(anim, forKey: "")
        actionView.layer.mask!.addAnimation(anim, forKey: "path"){finished in
            self.setViewMask(self.effectView, rect: self.smallRect)
            self.setViewMask(self.actionView, rect: self.smallRect)
            self.buttonState = ButtonState.small
            
        }
        
        self.buttonLabel.font = UIFont.TtroPayWandFonts.light3.font
        UIView.animate(withDuration: 0.2, animations: {
            self.button.backgroundColor = UIColor.TtroColors.darkBlue.color.withAlphaComponent(0.6)
            
            self.buttonLabel.alpha = 0.0
            self.buttonLabel.constraintsAffectingLayout(for: .vertical)[0].constant -= 15
            }, completion: { _ in
                
        })
        delegate.popMenuView(self, shrink: index)
    }
    
    func touchedDownGrowMask() {
        effectView.isHidden = false
        actionView.isHidden = false
        if (buttonState != ButtonState.small || touchedDown){
            return
        }
        
        let middleCirclePath = UIBezierPath(ovalIn: middleRect).cgPath
        let anim = CABasicAnimation(keyPath: "path")
        anim.fillMode = kCAFillModeForwards
        anim.isRemovedOnCompletion = false
        anim.duration = 0.2
        anim.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
        touchedDown = true
        
        let small2CirclePath = UIBezierPath(ovalIn: smallMiddleRect).cgPath
        anim.toValue = small2CirclePath
        
        actionView.layer.mask!.add(anim, forKey: "path")
        anim.toValue = middleCirclePath
        effectView.layer.mask!.addAnimation(anim, forKey: "path"){finished in
            self.buttonState = ButtonState.middle
            self.setViewMask(self.effectView, rect: self.middleRect)
            self.setViewMask(self.actionView, rect: self.smallMiddleRect)
            
            if (self.touchedUpInside){
                if (self.onSelect != nil){
                    self.onSelect!()
                } else {
                    self.shrinkMask()
                }
            }
            
            self.touchedDown = false
        }
        self.buttonLabel.font = UIFont.TtroPayWandFonts.regular2.font
        
        UIView.animate(withDuration: 0.2, animations: {
            self.button.backgroundColor = UIColor.TtroColors.darkBlue.color
            self.buttonLabel.constraintsAffectingLayout(for: .vertical)[0].constant += 15
            
            self.buttonLabel.alpha = 1
        }) 
        delegate.popMenuView(self, grow: index)
    }
    
    func calcMaxDistance(_ centerPoint : CGPoint, view : UIView) -> Double{
        var points : [CGPoint] = []
        points.append(CGPoint(x: view.frame.maxX, y: view.frame.maxY))
        points.append(CGPoint(x: view.frame.minX, y: view.frame.maxY))
        points.append(CGPoint(x: view.frame.maxX, y: view.frame.minY))
        points.append(CGPoint(x: view.frame.minX, y: view.frame.minY))
        
        var maxDist : Double = 0
        for point in points {
            maxDist = max(maxDist, dist(centerPoint, point2: point))
        }
        
        return maxDist
    }
    
    func dist(_ point1 : CGPoint, point2 : CGPoint ) -> Double{
        return sqrt(pow(Double(point1.x-point2.x), 2) + pow(Double(point1.y-point2.y), 2))
    }
}

// MARK : Elastic Move
extension PopMenuView {
    func elasticMove(_ d : CGFloat){
//        UIView.animate(withDuration: 0.2, animations: { 
//            
//        }) 
        UIView.animate(withDuration: 0.2, delay: 0, options: UIViewAnimationOptions.curveEaseOut, animations: {
            self.centerXConstraint.constant += d
            self.mainView.layoutIfNeeded()
            }, completion: nil)
    }
}
