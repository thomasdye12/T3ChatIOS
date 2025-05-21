//
//  ViewController.swift
//  T3ChatIOS
//
//  Created by Thomas Dye on 20/05/2025.
//

import UIKit
import SwiftUI

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        T3ChatUserShared.shared.MainVC = self
        let hostingController = UIHostingController(rootView: MainChatPage(userInfo: T3ChatUserShared.shared) )
        self.addChild(hostingController)
        self.view.addSubview(hostingController.view)
           
           hostingController.view.translatesAutoresizingMaskIntoConstraints = false
           NSLayoutConstraint.activate([
            hostingController.view.leadingAnchor.constraint(equalTo:  self.view.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo:  self.view.trailingAnchor),
            hostingController.view.topAnchor.constraint(equalTo:  self.view.topAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo:  self.view.bottomAnchor)
           ])
           
           hostingController.didMove(toParent: self)
    }


}

