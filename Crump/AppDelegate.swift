/*
AppDelegate.swift
Crump
Copyright (C) 2014  David Kopec

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License along
with this program; if not, write to the Free Software Foundation, Inc.,
51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
*/

import Cocoa
import SpriteKit


@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    @IBOutlet var window: NSWindow!
    @IBOutlet var skView: SKView!
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        /* Pick a size for the scene */
            /* Set the scale mode to scale to fit the window */
        let scene = GameScene(level: 1, numPlayers: 1)
        scene.scaleMode = .fill
            
        self.skView!.presentScene(scene)
            
            /* Sprite Kit applies additional optimizations to improve rendering performance */
        self.skView!.ignoresSiblingOrder = true
            
        self.skView!.showsFPS = true
        self.skView!.showsNodeCount = true
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true;
    }
}
