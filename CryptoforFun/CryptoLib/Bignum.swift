
@_transparent
func carryAdd(_ lhs: UInt8, _ rhs: UInt8, flag: UInt8) -> (UInt8, UInt8) {
    let tmp = UInt16(lhs) + UInt16(rhs) + UInt16(flag)
    return (UInt8(tmp & 0x00FF), UInt8((tmp & 0xFF00) >> 8))
}

struct Bignum {
    var d = Array<UInt8>()
    var dmax: Int {
        return d.count
    }
    var neg: Bool = false
}

extension Bignum {
    public init(hex: String) {
        var buffer: UInt8? = (hex.count % 2 == 0) ? nil : 0
        var skip = hex.hasPrefix("0x") ? 2 : 0
        for char in hex.unicodeScalars.lazy {
            guard skip == 0 else { skip -= 1; continue }
            guard char.value >= 48 && char.value <= 102 else { d.removeAll(); return }
            
            let v: UInt8
            let c: UInt8 = UInt8(char.value)
            switch c {
            case let c where c <= 57:
                v = c - 48
            case let c where c >= 65 && c <= 70:
                v = c - 55
            case let c where c >= 97:
                v = c - 87
            default:
                d.removeAll()
                return
            }
            if let b = buffer {
                d.append(b << 4 | v)
                buffer = nil
            } else {
                buffer = v
            }
        }
        d = d.reversed()
    }
    
    public func toHexString() -> String {
        return "0x" + d.reversed().reduce("") {
            return $0 + String(format: "%02X", $1)
        }
    }
    
    private static func positiveAdd(_ lhs: Bignum, _ rhs: Bignum) -> Bignum {
        var flag: UInt8 = 0, tmp: UInt8
        var result = Bignum()
        var dl = lhs.d, dr = rhs.d
        let count = max(dl.count, dr.count)
        
        if dl.count > dr.count { dr += Array<UInt8>.init(repeating: 0, count: count - dr.count) }
        else { dl += Array<UInt8>.init(repeating: 0, count: count - dl.count) }
        
        for idx in 0..<count{
            (tmp, flag) = carryAdd(dl[idx], dr[idx], flag: flag)
            result.d.append(tmp)
        }
        
        if flag != 0 { result.d.append(flag) }
        return result
    }
    
    private static func positiveSub(_ lhs: Bignum, _ rhs: Bignum) -> Bignum {
        return lhs
    }
    
    public static func + (_ lhs: Bignum, _ rhs: Bignum) -> Bignum {
        if lhs.neg && rhs.neg {
            var result = positiveAdd(lhs, rhs)
            result.neg = true
            return result
        } else if lhs.neg && !rhs.neg {
            var result = positiveSub(lhs, rhs)
            result.neg = !result.neg
            return result
        } else if !lhs.neg && rhs.neg {
            return positiveSub(lhs, rhs)
        } else {
            return positiveAdd(lhs, rhs)
        }
    }
    
    public static func - (_ lhs: Bignum, _ rhs: Bignum) -> Bignum {
        return lhs
    }
}
