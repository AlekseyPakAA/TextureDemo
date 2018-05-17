//
//  ViewController.swift
//  TextureDemo
//
//  Created by Alexey Pak on 16/05/2018.
//  Copyright © 2018 Alexey Pak. All rights reserved.
//

import UIKit
import AsyncDisplayKit

class ViewController: ASViewController<ViewController.ContentNode> {

	let contentNode: ContentNode
	class ContentNode: ASDisplayNode {

		let tableNode: ASTableNode = ASTableNode(style: .plain)

		override init() {
			super.init()

			automaticallyManagesSubnodes = true
		}

		override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
			return ASWrapperLayoutSpec(layoutElement: tableNode)
		}
	}

	var items: [String] = []

	//using to continue scrolling ater adding new elements
	var targetContentOffset: CGPoint = .zero

	init() {
		contentNode = ContentNode()
		super.init(node: contentNode)

		contentNode.tableNode.view.separatorStyle = .none
		contentNode.tableNode.inverted = true

		contentNode.tableNode.dataSource = self
		contentNode.tableNode.delegate = self
	}

	override func viewDidLoad() {
		let addButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(didTouchAddButton))
		navigationItem.rightBarButtonItem = addButton
	}

	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()

		contentNode.tableNode.view.contentInsetAdjustmentBehavior = .never

		let inset = (navigationController?.navigationBar.frame.height ?? 0.0) + UIApplication.shared.statusBarFrame.height
		contentNode.tableNode.contentInset = UIEdgeInsets(top: 0.0, left: 0.0, bottom: inset, right: 0.0)
		contentNode.tableNode.view.scrollIndicatorInsets = UIEdgeInsets(top: 0.0, left: 0.0, bottom: inset, right: 0.0)
	}

	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	@objc func didTouchAddButton() {
		items.append("")

		let indexPath = IndexPath(row: 0, section: 0)
		let indexPathsOfVisibleRows = contentNode.tableNode.indexPathsForVisibleRows()

		if indexPathsOfVisibleRows.isEmpty || indexPathsOfVisibleRows.contains(indexPath) {
			contentNode.tableNode.performBatchUpdates({
				self.contentNode.tableNode.insertRows(at: [indexPath], with: .top)
			}, completion: {_ in
				let contentOffset: CGPoint = {
					let x: CGFloat = self.contentNode.tableNode.contentOffset.x
					let y: CGFloat = 0.0

					return CGPoint(x: x, y: y)
				}()

				self.contentNode.tableNode.setContentOffset(contentOffset, animated: true)
			})
		} else {
			UIView.performWithoutAnimation {
				let oldContentSize = contentNode.tableNode.view.contentSize
				self.contentNode.tableNode.insertRows(at: [indexPath], with: .top)
				let newContentSize = contentNode.tableNode.view.contentSize

				guard !contentNode.tableNode.view.isDecelerating else { return }

				let contentOffset: CGPoint = {
					let heightDiff = newContentSize.height - oldContentSize.height

					let x = contentNode.tableNode.contentOffset.x
					let y = contentNode.tableNode.contentOffset.y + heightDiff

					return CGPoint(x: x, y: y)
				}()

				contentNode.tableNode.contentOffset = contentOffset
			}
		}
	}

}


extension ViewController: ASTableDelegate {

	func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
		self.targetContentOffset = targetContentOffset.pointee
	}

	func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
		//self.targetContentOffset = .zero
	}
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



class CellNode: ASCellNode {

	var titleTextNode: ASTextNode
	var descriptionTextNode: ASTextNode

	override init() {
		titleTextNode = ASTextNode()
		descriptionTextNode = ASTextNode()

		super.init()

		let attributes: [NSAttributedStringKey : Any] = [NSAttributedStringKey.font: UIFont.preferredFont(forTextStyle: .headline)]
		titleTextNode.attributedText = NSAttributedString(string: "Use Nodes in Node Containers", attributes: attributes)
		titleTextNode.maximumNumberOfLines = 1

		descriptionTextNode.attributedText =  NSAttributedString(string: "It is highly recommended that you use Texture’s nodes within a node container. Texture offers the following node containers.")

		addSubnode(descriptionTextNode)
		addSubnode(titleTextNode)
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
