//
//  ViewController.swift
//  TextureDemo
//
//  Created by Alexey Pak on 16/05/2018.
//  Copyright © 2018 Alexey Pak. All rights reserved.
//

import UIKit
import AsyncDisplayKit

class ViewController: ASViewController<ContentNode> {

	let contentNode: ContentNode


	var items: [String] = []

	init() {
		contentNode = ContentNode()
		super.init(node: contentNode)

		contentNode.tableNode.view.separatorStyle = .none
		contentNode.tableNode.inverted = true

		contentNode.tableNode.dataSource = self
		contentNode.tableNode.delegate = self
        
        contentNode.tableNode.view.contentInsetAdjustmentBehavior = .never
	}
    
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

	override func viewDidLoad() {
		let addButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(didTouchAddButton))
		navigationItem.rightBarButtonItem = addButton
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(notification:)), name: .UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(notification:)), name: .UIKeyboardWillHide, object: nil)
	}
    
    
    @objc func keyboardWillShow(notification: Notification) {
        guard let frame = notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? CGRect else {
            return
        }
        
        guard let duartion = notification.userInfo?[UIKeyboardAnimationDurationUserInfoKey] as? Double else {
            return
        }
        
        contentNode.keyboardFrame = frame
        UIView.animate(withDuration: duartion, animations: {
            self.contentNode.transitionLayout(withAnimation: true, shouldMeasureAsync: true)
        })
    }
    
    @objc func keyboardWillHide(notification: Notification) {
        guard let frame = notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? CGRect else {
            return
        }
        
        guard let duartion = notification.userInfo?[UIKeyboardAnimationDurationUserInfoKey] as? Double else {
            return
        }
        
        contentNode.keyboardFrame = .zero
        UIView.animate(withDuration: duartion, animations: {
            self.contentNode.transitionLayout(withAnimation: true, shouldMeasureAsync: true)
        })

    }

	override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        let bottomInset = (navigationController?.navigationBar.frame.height ?? 0.0) + UIApplication.shared.statusBarFrame.height
        let topInset = contentNode.chatInputControlNode.bounds.height
        
        contentNode.tableNode.contentInset = UIEdgeInsets(top: topInset, left: 0.0, bottom: bottomInset, right: 0.0)
        contentNode.tableNode.view.scrollIndicatorInsets = UIEdgeInsets(top: topInset, left: 0.0, bottom: bottomInset, right: 0.0)
	}

	@objc func didTouchAddButton() {
		items.append("")

		let indexPath = IndexPath(row: 0, section: 0)
		let indexPathsOfVisibleRows = contentNode.tableNode.indexPathsForVisibleRows()

		if indexPathsOfVisibleRows.isEmpty || indexPathsOfVisibleRows.contains(indexPath) {
			contentNode.tableNode.performBatchUpdates({
				self.contentNode.tableNode.insertRows(at: [indexPath], with: .top)
			}, completion: {_ in
                let offset: CGPoint = {
                    let x = self.contentNode.tableNode.contentOffset.x
                    let y = -self.contentNode.tableNode.contentInset.top
                    
                    return CGPoint(x: x, y: y)
                }()
				self.contentNode.tableNode.setContentOffset(offset, animated: true)
			})
		} else {
			UIView.performWithoutAnimation {
				let oldContentSize = contentNode.tableNode.view.contentSize
				self.contentNode.tableNode.insertRows(at: [indexPath], with: .top)
				let newContentSize = contentNode.tableNode.view.contentSize

				guard !contentNode.tableNode.view.isDecelerating else { return }

				let offset: CGPoint = {
					let heightDiff = newContentSize.height - oldContentSize.height

					let x = contentNode.tableNode.contentOffset.x
					let y = contentNode.tableNode.contentOffset.y + heightDiff

					return CGPoint(x: x, y: y)
				}()

				contentNode.tableNode.contentOffset = offset
			}
		}
	}

}


extension ViewController: ASTableDelegate {

}

extension ViewController: ASTableDataSource {

	func tableNode(_ tableNode: ASTableNode, numberOfRowsInSection section: Int) -> Int {
		return items.count
	}

	func tableNode(_ tableNode: ASTableNode, nodeBlockForRowAt indexPath: IndexPath) -> ASCellNodeBlock {
		let cellNodeBlock = { () -> ASCellNode in
			let cellNode = CellNode()
			return cellNode
		}

		return cellNodeBlock
	}

}

class ContentNode: ASDisplayNode {
    
    var keyboardFrame: CGRect = .zero
    
    let tableNode: ASTableNode = ASTableNode(style: .plain)
    let chatInputControlNode:ASEditableTextNode = {
        let node = ASEditableTextNode()
        
        node.backgroundColor = .red
        node.scrollEnabled = false
        return node
    } ()
    
    override init() {
        super.init()
        
        automaticallyManagesSubnodes = true
    }
    
    override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        let relativeLayout = ASRelativeLayoutSpec(horizontalPosition: .none,
                                                  verticalPosition: .end,
                                                  sizingOption: [],
                                                  child: chatInputControlNode)
        
        let insets = UIEdgeInsets(top: 0.0, left: 0.0, bottom: keyboardFrame.height, right: 0.0)
        let insetLayout = ASInsetLayoutSpec(insets: insets, child: relativeLayout)
        
        return ASBackgroundLayoutSpec(child: insetLayout, background: tableNode)
    }
}

class ChatInputControlNode: ASDisplayNode {
    
    let ediatbleTextNode: ASEditableTextNode = {
        let node = ASEditableTextNode()
        
        node.backgroundColor = .white
        node.maximumLinesToDisplay = 5
        node.scrollEnabled = false
        return node
    } ()
    let sendButtonNode: ASButtonNode = ASButtonNode()
    
    override init() {
        super.init()
        
        automaticallyManagesSubnodes = true
    }
    
    override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        let insets = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        
        return ASInsetLayoutSpec(insets: insets, child: ediatbleTextNode)
    }
    
}

class CellNode: ASCellNode {

	var titleTextNode: ASTextNode  = ASTextNode()
	var descriptionTextNode: ASTextNode  = ASTextNode()

	override init() {
		super.init()

        automaticallyManagesSubnodes = true
        selectionStyle = .none
        
		let attributes: [NSAttributedStringKey : Any] = [NSAttributedStringKey.font: UIFont.preferredFont(forTextStyle: .headline)]
		titleTextNode.attributedText = NSAttributedString(string: "Use Nodes in Node Containers", attributes: attributes)
		titleTextNode.maximumNumberOfLines = 1

		descriptionTextNode.attributedText =  NSAttributedString(string: "It is highly recommended that you use Texture’s nodes within a node container. Texture offers the following node containers.")
	}

	override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
		let spec = ASStackLayoutSpec()

		spec.direction = .vertical
		spec.alignItems = .start
		spec.spacing = 8.0

		spec.children = [titleTextNode, descriptionTextNode]

		let insets = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)

		return ASInsetLayoutSpec(insets: insets, child: spec)
	}

}
