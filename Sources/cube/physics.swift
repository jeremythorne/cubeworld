import Foundation

class Physics {
    var a:Double = 0
    var v:Double = 0
    var s:Double = 0
    var jumping:Bool = false

    func jump() {
        jumping = true
    }

    func step(dt:Double) {
        a = -9.8
        if jumping && s < 0.3 {
            a = 30
        } else {
            jumping = false
            if s < 0.01 {
                // on ground
                a = 0
            }
        }
        v += a * dt
        s += v * dt
        if s < 0 {
            s = -s
            v = -v * 0.2
        }
    }
}

var physics = Physics()
physics.jump()

for i in 0...100 {
    physics.step(dt:1.0 / 60)
    print(i, String(format:"%0.2f", Double(i) / 60), 
            String(format:"%0.2f", physics.a),
            String(format:"%0.2f", physics.v),
            String(format:"%0.2f", physics.s))
}

