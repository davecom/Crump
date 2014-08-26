/*
Sun.swift - An enemy that moves towards the player
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

class Sun: Enemy {
    
    override func move() {
        var closestP:CGPoint = dpkw.playersLocation[0]
        for var i:Int = 1; i < dpkw.playersLocation.count; i++ {
            if distance(sprite.position, dpkw.playersLocation[i]) < distance(sprite.position, closestP) {
                closestP = dpkw.playersLocation[i]
            }
        }
        
        switch(arc4random_uniform(4)) {
        case 0: wantToGo = .Up
        case 1: wantToGo = .Down
        case 2: wantToGo = .Left
        default: wantToGo = .Right
        }
        super.move()
    }
    
    override func reachedDeadEnd() {
        wantToGo = direction.opposite
        super.move()      //keep moving when we come to the end of the line
    }
    
}