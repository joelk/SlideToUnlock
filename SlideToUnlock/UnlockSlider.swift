//
//  UnlockSlider.swift
//  SlideToUnlock
//
//  Created by Joel Kin on 9/3/19.
//  Copyright © 2019 Kin. All rights reserved.
//
// 1. Set up the build-in styling options to look like what we want
// 2. Set up the built-in behavior to do what we want
// 3. Add the non-built-in UI
// 4. Accessibility & internationalization

import UIKit

/// A "slide to unlock" control.
///
/// To customize, edit the `tintColor`, `backgroundColor`, `title`, and so on. To act on completion, add a target for the `UIControl.Event.primaryActionTriggered` event.
///
/// This class knows about internationalization and is fully accessible.
@IBDesignable public class UnlockSlider: UISlider {
	
	@IBInspectable public var title: String = "" {
		didSet {
			label.text = title
			accessibilityLabel = title
		}
	}
	
	private let rightToLeft: Bool = {
		return UnlockSlider.userInterfaceLayoutDirection(for: .unspecified) == .rightToLeft
	}()
	
	private lazy var shine: CALayer = {
		let shine = CALayer()
		shine.backgroundColor = tintColor.cgColor
		let highlight = CAGradientLayer()
		highlight.frame = CGRect(x: -70, y: 0, width: 70, height: intrinsicContentSize.height)
		highlight.colors = [UIColor.clear.cgColor, UIColor.white.cgColor, UIColor.white.cgColor, UIColor.clear.cgColor]
		highlight.locations = [0.0, 0.3, 0.7, 1.0]
		highlight.startPoint = CGPoint(x: 0, y: 0)
		highlight.endPoint = CGPoint(x: 1, y: 0)
		let shineAnimation = CABasicAnimation(keyPath: "position.x")
		shineAnimation.repeatCount = .infinity
		shineAnimation.duration = 2.75
		shineAnimation.beginTime = CACurrentMediaTime() + 2.0
		shineAnimation.fromValue = -highlight.bounds.width
		shineAnimation.toValue = bounds.width + highlight.bounds.width
		shineAnimation.speed = rightToLeft ? -1 : 1
		highlight.add(shineAnimation, forKey: "shine")
		shine.addSublayer(highlight)
		shine.mask = label.layer
		return shine
	}()
	
	private lazy var label: UILabel = {
		let label = UILabel()
		label.textAlignment = .center
		return label
	}()
	
	private func setup() {
		minimumTrackTintColor = .clear
		maximumTrackTintColor = .clear
		setThumbImage(UIImage(named: "thumb"), for: .normal)
		backgroundColor = UIColor(white: 0.1, alpha: 0.25)
		layer.masksToBounds = true
		layer.cornerRadius = intrinsicContentSize.height / 2
		layer.addSublayer(shine)
		
		addTarget(self, action: #selector(touchUp), for: [.touchUpInside, .touchUpOutside])
	}
	
	public override func layoutSubviews() {
		super.layoutSubviews()
		let track = trackRect(forBounds: bounds)
		shine.frame = track
		if rightToLeft {
			let thumb = thumbRect(forBounds: bounds, trackRect: track, value: value)
			label.frame = track.inset(by: UIEdgeInsets(top: 0, left: intrinsicContentSize.height / 3, bottom: 0, right: intrinsicContentSize.height))
			label.layer.contentsRect = CGRect(x: 0, y: 0, width: thumb.minX / (track.width - thumb.width - 10), height: 1)
		} else {
			let inset: CGFloat = thumbRect(forBounds: bounds, trackRect: track, value: value).minX - 10
			label.frame = track.inset(by: UIEdgeInsets(top: 0, left: intrinsicContentSize.height, bottom: 0, right: intrinsicContentSize.height / 3))
			.offsetBy(dx: inset, dy: 0)
			label.layer.contentsRect = CGRect(x: inset / label.bounds.width, y: 0, width: 1 - inset / label.bounds.width, height: 1)
		}
	}
	
	override public func prepareForInterfaceBuilder() {
		super.prepareForInterfaceBuilder()
		value = 0.1
		shine.beginTime = -4.5
		setup()
	}
	
	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		setup()
	}

	override init(frame: CGRect) {
		super.init(frame: frame)
		setup()
	}
}

// MARK: Styling overrides
public extension UnlockSlider {
	override var tintColor: UIColor! {
		didSet {
			shine.backgroundColor = tintColor.cgColor
		}
	}
	
	override var intrinsicContentSize: CGSize {
		return CGSize(width: UIView.noIntrinsicMetric, height: 64.0)
	}
	
	override func trackRect(forBounds bounds: CGRect) -> CGRect {
		var bounds = bounds
		bounds.origin.y = (bounds.height - intrinsicContentSize.height) / 2
		bounds.size.height = intrinsicContentSize.height
		return bounds
	}
	
	override func thumbRect(forBounds bounds: CGRect, trackRect rect: CGRect, value: Float) -> CGRect {
		let value = rightToLeft ? 1 - value : value
		guard let thumbWidth = currentThumbImage?.size.width else { return super.thumbRect(forBounds: bounds, trackRect: rect, value: value) }
		let thumbInset = (rect.height - thumbWidth)
		return CGRect(x: thumbInset / 2 + (rect.width - thumbInset - thumbWidth) * CGFloat(value),
					  y: thumbInset / 2 + rect.origin.y,
					  width: rect.height - thumbInset,
					  height: rect.height - thumbInset)
	}
}

// MARK: Behavior
extension UnlockSlider {
	override public func setValue(_ value: Float, animated: Bool) {
		super.setValue(value, animated: animated)
		if value >= 1 {
			print("Hooray!")
			sendActions(for: .primaryActionTriggered)
		}
	}
	
	@objc private func touchUp() {
		let targetValue: Float = value > 0.75 ? 1.0 : 0.0
		UIView.animate(withDuration: Double(abs(value - targetValue) * 0.3),
					   delay: 0,
					   usingSpringWithDamping: 10,
					   initialSpringVelocity: 0,
					   options: [],
					   animations: {
						self.setValue(targetValue, animated: true)
						self.layoutIfNeeded()
		},
					   completion: nil)
	}
}
