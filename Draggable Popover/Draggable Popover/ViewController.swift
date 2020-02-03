//
//  ViewController.swift
//  Draggable Popover
//
//  Created by Nasir Ahmed Momin on 03/02/20.
//  Copyright © 2020 Nasir Ahmed Momin. All rights reserved.
//

import UIKit

enum CardState {
       case collapsed
       case expanded
   }

class ViewController: UIViewController {

    var cardVisible = false
    
    var nextState: CardState {
        return cardVisible ? .collapsed : .expanded
    }
    
    var draggableViewController: DraggableViewController!
    
    var visualEffectView: UIVisualEffectView!
    
    var cardStartHeight: CGFloat = 0
    var cardEndHeight: CGFloat = 0
    
    var runningAnimations = [UIViewPropertyAnimator]()
    var animationProgressWhenInterrupted: CGFloat = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCard()
    }

    func setupCard () {
        cardStartHeight = view.frame.height * 0.1
        cardEndHeight = view.frame.height * 0.85
        
        visualEffectView = UIVisualEffectView()
        visualEffectView.frame = view.frame
        self.view.addSubview(visualEffectView)
        
        // Add CardViewController xib to the bottom of the screen, clipping bounds so that the corners can be rounded
          draggableViewController =  DraggableViewController(nibName:"DraggableViewController", bundle:nil)
          self.view.addSubview(draggableViewController.view)
          draggableViewController.view.frame = CGRect(x: 0, y: self.view.frame.height - cardStartHeight, width: self.view.bounds.width, height: cardEndHeight)
          draggableViewController.view.clipsToBounds = true
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan))
        
        draggableViewController.handleArea.addGestureRecognizer(tapGesture)
        draggableViewController.handleArea.addGestureRecognizer(panGesture)
        
    }

    @objc func handleTap(_ recognizer: UITapGestureRecognizer) {
        switch recognizer.state {
        case .ended:
            animateTransitionIfNeeded(state: nextState, duration: 0.9)
        default:
            break
        }
    }
    
    @objc func handlePan(_ recognizer: UIPanGestureRecognizer) {
        switch recognizer.state {
        case .began:
            startInteractiveTransition(state: nextState, duration: 0.9)
        case .changed:
            let translation = recognizer.translation(in: draggableViewController.handleArea)
            var fractionComplete = translation.y / cardEndHeight
            
            fractionComplete = cardVisible ? fractionComplete : -fractionComplete
            updateInteractiveTransition(fractionCompleted: fractionComplete)
            
        case .ended:
            continueInteractiveTransition()
            
        default:
            break
        }
    }
    
    func animateTransitionIfNeeded (state:CardState, duration:TimeInterval) {

        if runningAnimations.isEmpty {
            let frameAnimator = UIViewPropertyAnimator(duration: duration, dampingRatio: 1) {
                switch state {
                case .expanded:
                    self.draggableViewController.view.frame.origin.y = self.view.frame.height - self.cardEndHeight
                    self.visualEffectView.effect = UIBlurEffect(style: .dark)
                    
                case .collapsed:
                    self.draggableViewController.view.frame.origin.y = self.view.frame.height - self.cardStartHeight
                    self.visualEffectView.effect = nil
                }
            }
            
            frameAnimator.addCompletion { _ in
                self.cardVisible.toggle()
                self.runningAnimations.removeAll()
            }
            
            frameAnimator.startAnimation()
            
            runningAnimations.append(frameAnimator)
            
            let cornerRadiusAnimator = UIViewPropertyAnimator(duration: duration, dampingRatio: 1) {
                switch state {
                case .expanded:
                    self.draggableViewController.view.layer.cornerRadius = 30.0
                case .collapsed:
                    self.draggableViewController.view.layer.cornerRadius = 0
                }
            }
            
            cornerRadiusAnimator.startAnimation()
            
            runningAnimations.append(cornerRadiusAnimator)
        }
    }
    
    func startInteractiveTransition(state:CardState, duration:TimeInterval) {
        if runningAnimations.isEmpty {
            animateTransitionIfNeeded(state: state, duration: duration)
        }
        
        for animator in runningAnimations {
            animator.pauseAnimation()
            animationProgressWhenInterrupted = animator.fractionComplete
        }
    }
    
    func updateInteractiveTransition(fractionCompleted:CGFloat) {
        for animator in runningAnimations {
            animator.fractionComplete = fractionCompleted + animationProgressWhenInterrupted
        }
    }
    
    func continueInteractiveTransition (){
        for animator in runningAnimations {
            animator.continueAnimation(withTimingParameters: nil, durationFactor: 0)
        }
    }
}

