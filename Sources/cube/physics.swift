import Foundation

var a:Double = 0
var v:Double = 0
var s:Double = 0
var jumping:Bool = true

func step(dt:Double) {
    a = -9.8
    if jumping && s < 0.2 {
        a = 10
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
        v = -v * 0.5
    }
}

for i in 0...100 {
    step(dt:1.0 / 60)
    print(i, String(format:"%0.2f", Double(i) / 60), 
            String(format:"%0.2f", a),
            String(format:"%0.2f", v),
            String(format:"%0.2f", s))
}

