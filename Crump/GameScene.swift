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

import SpriteKit

protocol DecisionPointKnowledgeWorker {
    func findDecisionPoint(fromLocation: CGPoint, inDirection: Direction) -> CGPoint?
}

enum Direction : String {
    case Left = "Left", Right = "Right", Up = "Up", Down = "Down", None = "None"
    var opposite: Direction {
        switch(self) {
        case (.Left): return .Right
        case (.Right): return .Left
        case (.Up): return .Down
        case (.Down): return .Up
        default: return .None
        }
    }
    var radians: CGFloat {
        switch(self) {
        case (.Left): return CGFloat(M_PI)
        case (.Right): return 0
        case (.Up): return CGFloat(M_PI / 2)
        case (.Down): return CGFloat(M_PI * (3 / 2))
        default: return 0
            }
    }
}

class GameScene: SKScene, DecisionPointKnowledgeWorker {
    var tiledMap: JSTileMap
    var level: Int
    var players: [Player] = []
    //var player: SKSpriteNode
    
    init(levelToLoad: Int, numPlayers: Int) {
        level = levelToLoad
        tiledMap = JSTileMap(named: "level\(level).tmx")
        let playerLocation = tiledMap.groupNamed("Stuff").objectNamed("Player")
        println(playerLocation)
        
        super.init(size: CGSizeMake(tiledMap.mapSize.width * tiledMap.tileSize.width, tiledMap.mapSize.height * tiledMap.tileSize.height))
        
        for i in 1 ... numPlayers {
            var playerSprite: SKSpriteNode = tiledMap.childNodeWithName("Player\(i)") as SKSpriteNode
            var p = Player(sprite: playerSprite, playerNumber: i, knowledgeWorker: self)
            players += p
        }
        
        anchorPoint = CGPointMake(0.5, 0.5)
        let mapBounds = tiledMap.calculateAccumulatedFrame()
        
        tiledMap.position = CGPointMake(-mapBounds.size.width/2.0, -mapBounds.size.height/2.0);
        //println(tiledMap.)
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
    
    //find the next place where moving in the current direction
    func findDecisionPoint(fromLocation: CGPoint, inDirection: Direction) -> CGPoint? {
        let wallLayer: TMXLayer = tiledMap.layerNamed("Walls")
        switch (inDirection) {
        case .Right:
            var tempX = round(fromLocation.x) + (tiledMap.tileSize.width - (round(fromLocation.x) % tiledMap.tileSize.width)) + (tiledMap.tileSize.width / 2)
            if (wallLayer.tileAt(CGPoint(x: tempX, y: fromLocation.y)) != nil) {
                return nil
            }
            for i in 0...tiledMap.mapSize.width {
                if (wallLayer.tileAt(CGPoint(x: tempX, y: fromLocation.y - tiledMap.tileSize.height)) == nil) {
                    return CGPoint(x: tempX, y: fromLocation.y)
                } else if (wallLayer.tileAt(CGPoint(x: tempX, y: fromLocation.y + tiledMap.tileSize.height)) == nil) {
                    return CGPoint(x: tempX, y: fromLocation.y)
                } else if (wallLayer.tileAt(CGPoint(x: tempX + tiledMap.tileSize.width, y: fromLocation.y)) != nil) {
                    return CGPoint(x: tempX, y: fromLocation.y)
                }
                tempX += tiledMap.tileSize.width
            }
            return nil
        case .Left:
            var tempX = round(fromLocation.x) - (round(fromLocation.x) % tiledMap.tileSize.width) - (tiledMap.tileSize.width / 2)
            if (tempX == fromLocation.x) {
                tempX -= tiledMap.tileSize.width
            }
            if (wallLayer.tileAt(CGPoint(x: tempX, y: fromLocation.y)) != nil) {
                return nil
            }
            for i in 0...tiledMap.mapSize.width {
                if (wallLayer.tileAt(CGPoint(x: tempX, y: fromLocation.y - tiledMap.tileSize.height)) == nil) {
                    return CGPoint(x: tempX, y: fromLocation.y)
                } else if (wallLayer.tileAt(CGPoint(x: tempX, y: fromLocation.y + tiledMap.tileSize.height)) == nil) {
                    return CGPoint(x: tempX, y: fromLocation.y)
                } else if (wallLayer.tileAt(CGPoint(x: tempX - tiledMap.tileSize.width, y: fromLocation.y)) != nil) {
                    return CGPoint(x: tempX, y: fromLocation.y)
                }
                tempX -= tiledMap.tileSize.width
            }
            return nil
        case .Up:
            var tempY = round(fromLocation.y) + (tiledMap.tileSize.height - (round(fromLocation.y) % tiledMap.tileSize.height)) + (tiledMap.tileSize.height / 2)
            if (wallLayer.tileAt(CGPoint(x: fromLocation.x, y: tempY)) != nil) {
                return nil
            }
            for i in 0...tiledMap.mapSize.height {
                if (wallLayer.tileAt(CGPoint(x: fromLocation.x - tiledMap.tileSize.width, y: tempY)) == nil) {
                    return CGPoint(x: fromLocation.x, y: tempY)
                } else if (wallLayer.tileAt(CGPoint(x: fromLocation.x + tiledMap.tileSize.width, y: tempY )) == nil) {
                    return CGPoint(x: fromLocation.x, y: tempY)
                } else if (wallLayer.tileAt(CGPoint(x: fromLocation.y, y: tempY + tiledMap.tileSize.height)) != nil) {
                    return CGPoint(x: fromLocation.x, y: tempY)
                }
                tempY += tiledMap.tileSize.height
            }
            return nil
        case .Down:
            var tempY = round(fromLocation.y) - (round(fromLocation.y) % tiledMap.tileSize.height) - (tiledMap.tileSize.height / 2)
            if (tempY == fromLocation.y) {
                tempY -= tiledMap.tileSize.height
            }
            if (wallLayer.tileAt(CGPoint(x: fromLocation.x, y: tempY)) != nil) {
                return nil
            }
            for i in 0...tiledMap.mapSize.height {
                if (wallLayer.tileAt(CGPoint(x: fromLocation.x - tiledMap.tileSize.width, y: tempY)) == nil) {
                    return CGPoint(x: fromLocation.x, y: tempY)
                } else if (wallLayer.tileAt(CGPoint(x: fromLocation.x + tiledMap.tileSize.width, y: tempY )) == nil) {
                    return CGPoint(x: fromLocation.x, y: tempY)
                } else if (wallLayer.tileAt(CGPoint(x: fromLocation.y, y: tempY - tiledMap.tileSize.height)) != nil) {
                    return CGPoint(x: fromLocation.x, y: tempY)
                }
                tempY -= tiledMap.tileSize.height
            }
            return nil
        default:  //if .None
            return nil
        }
    }
    
    override func mouseDown(theEvent: NSEvent) {
        /* Called when a mouse click occurs */
        pause()
    }
    
    override func keyDown(theEvent: NSEvent) {
        let temp: String = theEvent.characters
        for letter in temp {
            switch (letter) {
            case "p":
                pause()
            default:
                for player in players {
                    if let tempDirection = player.keyBindings["\(letter)"] {
                        player.wantToGo = tempDirection
                        if (player.direction == .None || player.wantToGo == player.direction.opposite) {  //if player's not moving, move him
                            player.move()
                        }
                    }
                }
            }
        }
        
        //check if None currently then move
        
        //check if trying to go opposite direction, then do so immediately
    }
    
    override func update(currentTime: CFTimeInterval) {
        /* Called before each frame is rendered */
    }
}
