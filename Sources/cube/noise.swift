func noise8_2d(seed:Int, _ x:Int, _ y:Int) -> UInt8 {
    let h = seed
    var n:UInt8 = 0
    for i in 1...4 {
        let li = x >> i
        let ti = y >> i
        let ht = hash(h + ti)
        let hb = hash(h + ti + 1)
        let e = Int(randseq8(seed:ht, seq: i, li))
        let f = Int(randseq8(seed:ht, seq: i, li + 1))
        let g = Int(randseq8(seed:hb, seq: i, li))
        let h = Int(randseq8(seed:hb, seq: i, li + 1))
        let l = li << i
        let t = ti << i
        let dt = ((x - l) * (f - e)) >> i
        let db = ((x - l) * (h - g)) >> i
        let vt = e + dt
        let vb = g + db
        let d = ((y - t) * (vb - vt)) >> i
        n += UInt8((vt + d) >> (5 - i))
    }
    return n
}

func noise8(seed:Int, _ x:Int) -> UInt8 {
    let h = seed
    var n:UInt8 = 0
    for i in 1...4 {
        let li = x >> i
        let a = Int(randseq8(seed:h, seq: i, li))
        let b = Int(randseq8(seed:h, seq: i, li + 1))
        let l = li << i
        let d = ((x - l) * (b - a)) >> i
        n += UInt8((a + d) >> (5 - i))
    }
    return n
}

func randseq8(seed:Int, seq:Int, _ n:Int) -> UInt8 {
    let h = hash(seed + seq)
    return UInt8(hash(h + n) & 0xff)
}

func hash(_ s:Int) -> Int {
    return Int(xorshift32(seed: UInt32(s & Int(UInt32.max))))
}

func xorshift32 (seed: UInt32) -> UInt32 {
    assert(seed != 0)
    var x:UInt32 = seed
    x ^= x << 13
    x ^= x >> 17
    x ^= x << 5
    return x
}

