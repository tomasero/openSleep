function processBPM(buffer, thresh) {
  _bpm = 0;
  _prev = 0;
  lastBeat = -3;
  var i;
  for (i = 1; i < buffer.length; i++) {
    _now = buffer[i];
    _prev = buffer[i-1];
    if (_now - _prev > thresh && i - lastBeat > 4) {
      _bpm++;
      lastBeat = i;
    }
  }
  return parseInt(_bpm * (600. / buffer.length))
}
