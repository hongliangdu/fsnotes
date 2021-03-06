//
//  BasicViewController.swift
//  FSNotes iOS
//
//  Created by Олександр Глущенко on 21.05.2020.
//  Copyright © 2020 Oleksandr Glushchenko. All rights reserved.
//

import Foundation
import UIKit

class BasicViewController: UIViewController, SwiftyPageControllerDelegate {

    var containerController: SwiftyPageController!

    func swiftyPageController(_ controller: SwiftyPageController, willMoveToController toController: UIViewController) {
        if let nav = toController as? UINavigationController {
            if let pvc = nav.viewControllers.first as? PreviewViewController {
                UserDefaultsManagement.previewMode = true

                // load if scrolled from editor
                if !controller.selectedController.isKind(of: ViewController.self) {
                    pvc.loadPreview(force: true)
                }

                return
            }

            if nil != nav.viewControllers.first as? EditorViewController {
                UserDefaultsManagement.previewMode = false
            }
        }
    }

    func swiftyPageController(_ controller: SwiftyPageController, didMoveToController toController: UIViewController) {
        if toController.isKind(of: UINavigationController.self) {
            if let nav = toController as? UINavigationController,
                nil != nav.viewControllers.first as? PreviewViewController {
                self.disableSwipe()
                return
            }

            self.enableSwipe()

        // View controller
        } else {

            UIApplication.getEVC().userActivity?.invalidate()
            UIApplication.getPVC()?.clear()

            self.disableSwipe()
        }

        if let nav = toController as? UINavigationController {
            if let evc = nav.viewControllers.first as? EditorViewController, evc.editArea != nil {
                return
            }
        }
    }

    func swiftyPageController(_ controller: SwiftyPageController, alongSideTransitionToController toController: UIViewController) {
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let containerController = segue.destination as? SwiftyPageController {
            setupContainerController(containerController)
            restoreLastController()
        }
    }

    func setupContainerController(_ controller: SwiftyPageController) {
        containerController = controller
        containerController.delegate = self
        containerController.animator = .parallax

        let listController = UIStoryboard(name: "Main", bundle: nil)
            .instantiateViewController(withIdentifier: "listViewController")
        let editorController = UIStoryboard(name: "Main", bundle: nil)
            .instantiateViewController(withIdentifier: "editorViewController")
        let previewController = UIStoryboard(name: "Main", bundle: nil)
            .instantiateViewController(withIdentifier: "previewViewController")

        let editorNav = UINavigationController(rootViewController: editorController)
        let previewNav = UINavigationController(rootViewController: previewController)

        containerController.viewControllers = [listController, editorNav, previewNav]
        containerController.selectController(atIndex: 0, animated: false)

        // editor force loading
        DispatchQueue.main.async {
            _ = editorController.view
        }
    }

    public func disableSwipe() {
        if let pan = containerController.panGesture {
            pan.isEnabled = false
        }
    }

    public func enableSwipe() {
        if let pan = containerController.panGesture {
            pan.isEnabled = true
        }
    }

    private func restoreLastController() {
        guard !Storage.shared().isCrashedLastTime else { return }

        DispatchQueue.main.async {
            if let noteURL = UserDefaultsManagement.currentNote,
               let controller = UserDefaultsManagement.currentController,
               controller != 0
            {
                if FileManager.default.fileExists(atPath: noteURL.path),
                   let project = Storage.shared().getProjectByNote(url: noteURL)
                {
                    let note = Note(url: noteURL, with: project)

                    if !note.isEncrypted(), let bvc = UIApplication.shared.windows[0].rootViewController as? BasicViewController {
                        bvc.containerController.selectController(atIndex: controller, animated: false)

                        let evc = UIApplication.getEVC()
                        evc.fill(note: note)

                        if UserDefaultsManagement.currentEditorState == true,
                           let selectedRange = UserDefaultsManagement.currentRange
                        {
                            if selectedRange.upperBound <= note.content.length {
                                evc.editArea.selectedRange = selectedRange
                            }

                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                evc.editArea.becomeFirstResponder()
                            }
                        }
                    }
                }
            }
        }
    }
}
