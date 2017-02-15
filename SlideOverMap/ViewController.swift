//
//  Copyright © 2017 Fish Hook LLC. All rights reserved.
//

import UIKit

protocol Slideable: class, UIViewControllerProtocol {
    
    var overScrolling: Bool { get set }
    
    func didSnapToBottom()
    func didSnapToTop()
}

protocol SlideyBackType: class, UIViewControllerProtocol {
    
    var isUserInteractionEnabled: Bool { get set }
}

protocol UIViewControllerProtocol {
    
    var view: UIView! { get }
}

extension UIViewController: UIViewControllerProtocol { }

class SlideyController: UIViewController {
    
    func setBack(_ back: SlideyBackType)
    {
        backViewController = back
        if let viewController = back as? UIViewController {
            addChildViewController(viewController)
        }
    }
    
    func setFront(_ slidey: Slideable)
    {
        slideableViewController = slidey
        if let viewController = slidey as? UIViewController {
            addChildViewController(viewController)
        }
    }
    
    // MARK: View Life Cycle
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        minTopConstant = view.frame.height * 0.2
        maxTopConstant = view.frame.height * 0.8
        slideyTopConstraint.constant = maxTopConstant
        beginConstant = slideyTopConstraint.constant
        
        if let view = backViewController?.view {
            addBackSubview(view)
        }
        
        if let view = slideableViewController?.view {
            addBackSubview(view)
        }
        
        panGestureRecognizer = slideyView.gestureRecognizers?.first as! UIPanGestureRecognizer
        panGestureRecognizer.delegate = self
    }
    
    fileprivate var slideableViewController: Slideable?
    private var backViewController: SlideyBackType?
    
    fileprivate var panGestureRecognizingState: GestureState = .Active
    
    @IBOutlet fileprivate weak var panGestureRecognizer: UIPanGestureRecognizer!
    @IBOutlet fileprivate weak var slideyTopConstraint: NSLayoutConstraint!
    @IBOutlet fileprivate weak var slideyView: UIView!
    @IBOutlet fileprivate weak var backView: UIView!
    
    fileprivate var minTopConstant: CGFloat = 0.0
    fileprivate var maxTopConstant: CGFloat = 0.0
    fileprivate var beginConstant: CGFloat = 0.0
    
    fileprivate var slideyPosition = Position.Top {
        didSet {
            
            switch slideyPosition {
            case .Bottom:
                slideableViewController?.didSnapToBottom()
                backViewController?.isUserInteractionEnabled = true
                
            case .Top:
                panGestureRecognizingState = .Inactive
                
                slideableViewController?.didSnapToTop()
                backViewController?.isUserInteractionEnabled = false
            }
        }
    }
    
    fileprivate enum Position {
        case Bottom
        case Top
    }
    
    fileprivate enum GestureState {
        case Active
        case Inactive
    }
}

// MARK: Interface Builder Actions
extension SlideyController {
    
    @IBAction func gestureRecognized(_ sender: UIPanGestureRecognizer)
    {
        if panGestureRecognizingState == .Inactive && slideableViewController?.overScrolling == true  {
            panGestureRecognizingState = .Active
        }
        
        guard panGestureRecognizingState == .Active else { return }
        
        adjustConstraints(sender, translation: sender.translation(in: self.view))
    }
}

// MARK: Gesture Recognizer Delegate
extension SlideyController: UIGestureRecognizerDelegate {
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool
    {
        return true
    }
}

// MARK: Private Helpers
fileprivate extension SlideyController {
    
    func addBackSubview(_ view: UIView)
    {
        backView.addEquallyPinnedSubview(view)
    }
    
    func addSlideSubview(_ view: UIView)
    {
        slideyView.addEquallyPinnedSubview(view)
    }
    
    func adjustConstraints(_ recognizer: UIGestureRecognizer, translation: CGPoint)
    {
        guard let tableViewController = slideableViewController as? UITableViewController else { return }
        
        switch recognizer.state {
        case .changed:
            slideyTopConstraint.constant = beginConstant + translation.y
            tableViewController.tableView.isScrollEnabled = false
        case .ended:
            view.layoutIfNeeded()
            UIView.animate(withDuration: 0.5, animations: {
                self.slideyTopConstraint.constant = self.newTopConstant(translation.y)
                self.view.layoutIfNeeded()
            })
            tableViewController.tableView.isScrollEnabled = true
            beginConstant = slideyTopConstraint.constant
        default:
            break
        }
    }
    
    func newTopConstant(_ translationY: CGFloat) -> CGFloat
    {
        let newConstant = slideyTopConstraint.constant + translationY
        if newConstant > maxTopConstant || newConstant > view.frame.height * 0.5 {
            slideyPosition = .Bottom
            return maxTopConstant
        }
        else {
            slideyPosition = .Top
            return minTopConstant
        }
    }
}
