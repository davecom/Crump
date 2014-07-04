/*
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

//
//  GameScene.swift
//  Crump
//
//  Created by David Kopec on 6/29/14.
//  Copyright (c) 2014 Oak Snow Consulting. All rights reserved.
//

import SpriteKit

class GameScene: SKScene {
    var tiledMap: JSTileMap
    var level: Int
    //var player: SKSpriteNode
    
    init(size: CGSize, levelToLoad:Int) {
        level = levelToLoad
        tiledMap = JSTileMap(named: "level\(level).tmx")
        let playerLocation = tiledMap.groupNamed("Stuff").objectNamed("Player")
        println(playerLocation)
        //player =
        
        super.init(size: size)
        anchorPoint = CGPointMake(0.5, 0.5)
        let mapBounds = tiledMap.calculateAccumulatedFrame()
        tiledMap.position = CGPointMake(-mapBounds.size.width/2.0, -mapBounds.size.height/2.0);
        addChild(tiledMap)
        
    }
    
    
    override func didMoveToView(view: SKView) {
        /* Setup your scene here */
        /*let myLabel = SKLabelNode(fontNamed:"Chalkduster")
        myLabel.text = "Hello, World!";
        myLabel.fontSize = 65;
        myLabel.position = CGPoint(x:CGRectGetMidX(self.frame), y:CGRectGetMidY(self.frame));
        
        self.addChild(myLabel)*/
    }
    
    func pause() {
        if (!paused) {
            let myLabel = SKLabelNode(fontNamed:"Chalkduster")
            myLabel.text = "Paused"
            myLabel.name = "Paused"
            myLabel.fontSize = 65
            myLabel.position = CGPoint(x:CGRectGetMidX(self.frame), y:CGRectGetMidY(self.frame))
            addChild(myLabel)
        } else {
            let myLabel = childNodeWithName("Paused")
            myLabel.removeFromParent()
        }
        paused = !paused
    }
    
    override func mouseDown(theEvent: NSEvent) {
        /* Called when a mouse click occurs */
        pause()
       /* let location = theEvent.locationInNode(self)
        
        let sprite = SKSpriteNode(imageNamed:"Spaceship")
        sprite.position = location;
        sprite.setScale(0.5)
        
        let action = SKAction.rotateByAngle(M_PI, duration:1)
        sprite.runAction(SKAction.repeatActionForever(action))
        
        self.addChild(sprite)*/
    }
    
    override func update(currentTime: CFTimeInterval) {
        /* Called before each frame is rendered */
    }
}
