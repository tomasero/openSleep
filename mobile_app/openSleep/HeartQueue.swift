/*
 Fixed size queue for heart data
 
 
 */
public struct HeartQueue {
  fileprivate var array = [Int]()
  
  var windowTime: Int
  var frequency: Int
  
  init(windowTime: Int? = 15, 
    frequency: Int? = 10) {
    
    self.windowTime = windowTime!
    self.frequency = frequency!
  }
  
  private var maxSize: Int {
    return windowTime * frequency
  }
  
  public mutating func put(hr: UInt32) {
    array.append(Int(hr))
    if (array.count > maxSize) {
      array.removeFirst()
    }
  }
  
  public func bpm() -> Int {
    if (array.count < 100) {
      return 0
    }
    
    var peakIndices = [Int]()
    let thresh = 50
    var i = 0
    while (i < (array.count - 1)) {
      if (array[i + 1] - array[i] > thresh) {
        peakIndices.append(i)
        i += 4
      }
      i += 1
    }
    
    if (peakIndices.count < 2) {
      return 0
    }
    
    var rrDiffs = [Int]()
    for i in 0..<(peakIndices.count - 1) {
      rrDiffs.append(peakIndices[i + 1] - peakIndices[i])
    }
    return Int(60 / (Float(rrDiffs.reduce(0, +)) / Float(rrDiffs.count * frequency)))
  }
}
