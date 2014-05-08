library bit_set;

import 'dart:core';
import 'dart:math';
import 'dart:typed_data';
import 'dart:async';
import 'dart:collection';

class BitSet {
  final int SHRINK_THRESHOLD = 0x100;
  Uint32List _data;
  
  int _length;
  int _version;
  int _updateLevel;
  int _selectedCount;
  int _selectedCountVersion = -1;
  
  int get length => _length;
  int get lengthInInts => (length + 0x1f) ~/ 0x20;
  
  StreamController _changeController = new StreamController.broadcast();
  Stream get changed => _changeController.stream;
  
  void assure(bool cond, String errorMessage) {
    if (!cond) throw new ArgumentError(errorMessage);
  }

  void assureGoez(num num, String argName) {
    if (num < 0) throw new ArgumentError("$argName should be greater than zero");
  }

  void assureInRange(num value, num min, num max, String argName) {
    if ((value < min) || (value > max))
      throw new ArgumentError("Argument $argName ($value) out of range ($min, $max)");
  }
  
  void copy(Uint32List src, Uint32List dst, int count) {
    for (int i = 0; i < count; i++)
      dst[i] = src[i];
  }
  
  void setLength(int value) {
    assure(value >= 0, "should be > 0");
    
    if (value == length) return;
    int nIntsNeeded = (value + 0x1f) ~/ 0x20;
    if ((nIntsNeeded > _data.length) || ((nIntsNeeded + SHRINK_THRESHOLD) < _data.length)) {
      var newData = new Uint32List(nIntsNeeded);
      copy(_data, newData, (nIntsNeeded > _data.length) ? _data.length : nIntsNeeded);
      _data = newData;
    }
    
    if (value > length) {
      if (length % 0x20 > 0)
        _data[lengthInInts - 1] &= (1 << ((length % 0x20) & 0x1f)) - 1;
      _data.fillRange(lengthInInts, nIntsNeeded, 0);
    }
    _length = value;
    version++;
  }
  
  int get version => _version;
      set version(int value) { _version = value; if (_updateLevel == 0 && changed != null) _changeController.add(version); }

  BitSet get self => this;
  
  static final Int8List _onBitCount = new Int8List.fromList([
    0, 1, 1, 2, 1, 2, 2, 3, 1, 2, 2, 3, 2, 3, 3, 4,
    1, 2, 2, 3, 2, 3, 3, 4, 2, 3, 3, 4, 3, 4, 4, 5,
    1, 2, 2, 3, 2, 3, 3, 4, 2, 3, 3, 4, 3, 4, 4, 5,
    2, 3, 3, 4, 3, 4, 4, 5, 3, 4, 4, 5, 4, 5, 5, 6,
    1, 2, 2, 3, 2, 3, 3, 4, 2, 3, 3, 4, 3, 4, 4, 5,
    2, 3, 3, 4, 3, 4, 4, 5, 3, 4, 4, 5, 4, 5, 5, 6,
    2, 3, 3, 4, 3, 4, 4, 5, 3, 4, 4, 5, 4, 5, 5, 6,
    3, 4, 4, 5, 4, 5, 5, 6, 4, 5, 5, 6, 5, 6, 6, 7,
    1, 2, 2, 3, 2, 3, 3, 4, 2, 3, 3, 4, 3, 4, 4, 5,
    2, 3, 3, 4, 3, 4, 4, 5, 3, 4, 4, 5, 4, 5, 5, 6,
    2, 3, 3, 4, 3, 4, 4, 5, 3, 4, 4, 5, 4, 5, 5, 6,
    3, 4, 4, 5, 4, 5, 5, 6, 4, 5, 5, 6, 5, 6, 6, 7,
    2, 3, 3, 4, 3, 4, 4, 5, 3, 4, 4, 5, 4, 5, 5, 6,
    3, 4, 4, 5, 4, 5, 5, 6, 4, 5, 5, 6, 5, 6, 6, 7,
    3, 4, 4, 5, 4, 5, 5, 6, 4, 5, 5, 6, 5, 6, 6, 7,
    4, 5, 5, 6, 5, 6, 6, 7, 5, 6, 6, 7, 6, 7, 7, 8]);

  static final Int8List _firstOnBit = new Int8List.fromList([
    -1, 0, 1, 0, 2, 0, 1, 0, 3, 0, 1, 0, 2, 0, 1, 0,
    4, 0, 1, 0, 2, 0, 1, 0, 3, 0, 1, 0, 2, 0, 1, 0,
    5, 0, 1, 0, 2, 0, 1, 0, 3, 0, 1, 0, 2, 0, 1, 0,
    4, 0, 1, 0, 2, 0, 1, 0, 3, 0, 1, 0, 2, 0, 1, 0,
    6, 0, 1, 0, 2, 0, 1, 0, 3, 0, 1, 0, 2, 0, 1, 0,
    4, 0, 1, 0, 2, 0, 1, 0, 3, 0, 1, 0, 2, 0, 1, 0,
    5, 0, 1, 0, 2, 0, 1, 0, 3, 0, 1, 0, 2, 0, 1, 0,
    4, 0, 1, 0, 2, 0, 1, 0, 3, 0, 1, 0, 2, 0, 1, 0,
    7, 0, 1, 0, 2, 0, 1, 0, 3, 0, 1, 0, 2, 0, 1, 0,
    4, 0, 1, 0, 2, 0, 1, 0, 3, 0, 1, 0, 2, 0, 1, 0,
    5, 0, 1, 0, 2, 0, 1, 0, 3, 0, 1, 0, 2, 0, 1, 0,
    4, 0, 1, 0, 2, 0, 1, 0, 3, 0, 1, 0, 2, 0, 1, 0,
    6, 0, 1, 0, 2, 0, 1, 0, 3, 0, 1, 0, 2, 0, 1, 0,
    4, 0, 1, 0, 2, 0, 1, 0, 3, 0, 1, 0, 2, 0, 1, 0,
    5, 0, 1, 0, 2, 0, 1, 0, 3, 0, 1, 0, 2, 0, 1, 0,
    4, 0, 1, 0, 2, 0, 1, 0, 3, 0, 1, 0, 2, 0, 1, 0]);         

  static Int8List _lastOnBit = new Int8List.fromList([
   -1, 0, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3, 3, 3, 3, 3,
    4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4,
    5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5,
    5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5,
    6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6,
    6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6,
    6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6,
    6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6,
    7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7,
    7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7,
    7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7,
    7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7,
    7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7,
    7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7,
    7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7,
    7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7]);

  /// Creates a new bitset of a specified length
  BitSet(int length, bool defaultValue) {
     _data = new Uint32List((length + 0x1f) ~/ 0x20);
     _length = length;
     _version = 0;
     
     if (defaultValue)
       for (int i = 0; i < _data.length; i++)
          _data[i] = -1;
  }
 
  /// Clones a bitset.
  BitSet clone() {
    var bitSet = new BitSet(0, false);
    bitSet._data = new Uint32List.fromList(_data);  // effective length: (lengthInInts)
    bitSet._length = _length;
    bitSet._version = _version;
    return bitSet;
  }

  factory BitSet.fromValues(List<bool> values) {
    _data = new Uint32List((values.length + 0x1f) ~/ 0x20);
    _length = values.length;
    
    for (int i = 0; i < _length; i++)
      if (values[i])
        _data[i ~/ 0x20] |= 1 << ((i % 0x20) & 0x1f);
    
    _version = 0;
  }

  factory BitSet.fromString(String values) {
    
    var bitset = new BitSet(values.length, false);
    
    for (int i = 0; i < bitset._length; i++)
      if (values[i] == '1')
        bitset._data[i ~/ 0x20] |= 1 << ((i % 0x20) & 0x1f);
    
    bitset._version = 0;
    return bitset;
  }
  
  factory BitSet.fromBytes(ByteData bytes) {
     int len = bytes.lengthInBytes; 
     _data = new Uint32List((len + 3) ~/ 4);
     _length = len * 8;
     int num1 = 0;
     int num2 = 0;
     
     while ((len - num2) >= 4) {
        _data[num1++] = (
            ((bytes.getInt8(num2) & 0xff) | 
            ((bytes.getInt8(num2 + 1) & 0xff) << 8)) |
            ((bytes.getInt8(num2 + 2) & 0xff) << 0x10)) | 
            ((bytes.getInt8(num2 + 3) & 0xff) << 0x18);
        
        num2 += 4;
     }

     if (len - num2 == 3) 
        _data[num1] = (bytes.getInt8(num2 + 2) & 0xff) << 0x10;

     if (len - num2 == 2) 
        _data[num1] |= (bytes.getInt8(num2 + 1) & 0xff) << 8;

     if (len - num2 == 1) 
        _data[num1] |= bytes.getInt8(num2) & 0xff;

     _version = 0;
  }

  String toString() => "$_length bits, ${countBits(true)} set";
  
  String toBinaryString() {
    var one = '1'.runes.first;
    var zero = '0'.runes.first;
    return new String.fromCharCodes(new Iterable.generate(_length, (i) => this[i] ? one : zero));
  }

  bool equals(BitSet other) {
    if (this == other) return true;
    if (other == null) return false;
    if (_length != other._length) return false;
    if (_length == 0) return true;

    int i = 0;
    for (; i < _data.length - 1; i++)
      if (_data[i] != other._data[i]) return false;

    for (int i = (_data.length - 1) * 8; i < _length; i++)
      if (this[i] != other[i])
        return false;
     
    return true;
  }

  void invert() {
    for (int i = 0; i < _data.length; i++)
      _data[i] ^= -1;

    _version++;
  }

  void setAll(bool value) {
    int flags = value ? -1 : 0;
    int len = lengthInInts;
    for (int i= 0; i < len; i++)
      _data[i] = flags;

    version++;
  }

  void setRange(int from, int to, bool value) {
    assureInRange(from, 0, length - 1, "from");
    assureInRange(to, 0, length - 1, "to");
    
    int start = min(from, to);
    int end = max(from, to);

    for (int i = start; i <= end; i++)
      this[i] = value;

    version++;
  }

  /// Sets n randomly chosen bits to value, remaining bits to !value.
  void setRandom(int n, bool value) {
    assure(n > 0 && n <= _length, "n must be >= 0 && <= Count");

    if (n == _length) {
      setAll(value);
      return;
    }
    
    if (n > _length / 2) {
      value = !value;
      n = _length - n;
    }
    
    setAll(!value);
    
    var rnd = new Random();
    for (int k = 0; k < n; ) {
      int i = rnd.nextInt(_length);
      if (this[i] == value) continue;
      this[i] = value;
      k++;
    }
  }

  /// Modifies current bitset by performing the bitwise AND operation against the 
  /// corresponding elements in the specified bitset.
  BitSet and(BitSet value) {
    assure(_length == value._length, "Array lengths differ.");
    
    for (int i = 0, len = lengthInInts; i < len; i++)
      _data[i] &= value._data[i];

    version++;
    return this;
  }

  /// Performs the bitwise AND NOT operation on the elements in the current bitset 
  /// against the corresponding elements in the specified bitset.
  BitSet andNot(BitSet value) {
    assure(_length == value._length, "Array lengths differ.");

    int len = lengthInInts;
    for (int num2 = 0; num2 < len; num2++)
      _data[num2] &= ~value._data[num2];
     
    version++;
    return this;
  }

  /// Performs the bitwise NOT AND operation on the elements in the current bitset 
  /// against the corresponding elements in the specified bitset.
  BitSet notAnd(BitSet value) {
    assure(_length == value._length, "Array lengths differ.");

    for (int i = 0, len = lengthInInts; i < len; i++)
      _data[i] = (~_data[i]) & value._data[i];

    version++;
    return this;
  }

  /// Inverts all bit values in the current bitset
  BitSet not() {
     for (int i = 0, len = lengthInInts; i < len; i++)
        _data[i] = ~_data[i];
    
     version++;
     return this;
  }

  /// Performs the bitwise OR operation on the elements in the current bitset 
  /// against the corresponding elements in the specified bitset.
  BitSet or(BitSet value) {
    assure(_length == value._length, "Array lengths differ.");
    
    for (int i = 0, len = lengthInInts; i < len; i++)
      _data[i] |= value._data[i];
    
    version++;
    return this;
  }

  /// Performs the bitwise exclusive OR operation on the elements in the current bitset 
  /// against the corresponding elements in the specified bitset.
  BitSet xor(BitSet value) {
    assure(_length == value._length, "Array lengths differ.");
    
    for (int i = 0, len = lengthInInts; i < len; i++)
      _data[i] ^= value._data[i];
    
    version++;
    return this;
  }

  operator & (BitSet second) => clone().and(second);
  operator % (BitSet second) => clone().andNot(second);
  operator | (BitSet second) => clone().or(second);
  operator ^ (BitSet second) => clone().xor(second);

  /// Inserts n 0-bits at position pos, resizing self and shifting bits appropriately.
  void insertAt(int pos, int n, [bool flag=false])
  {
    assureInRange(pos, 0, length, "pos");
     
    if (n == 0) return;

    //TODO: optimize
    //the most primitive implementation, optimize it later!
    int oldlength = length;
    setLength(length + n);
    if (!contains(true)) return; // nothing to do
    for (int i = oldlength - 1; i >= pos; i--) {
       this[i + n] = this[i];
       if (i < pos + n) 
          this[i] = flag;
    }
  }

  /// Deletes n bits beginning at position pos, resizing self and shifting remaining 
  /// bits appropriately.
  void removeAt(int pos, int n) {
    // the most primitive implementation, optimize it later!
    assure(n >= 0, "n cannot be negative");
    assureInRange(pos, 0, length - n, "pos");
    
    if (contains(true))
      for (int i = pos; i < length - n; i++)
        this[i] = this[i + n];

    setLength(length - n);
  }

  // no bounds checking for performance reasons
  bool operator[](int pos) => ((_data[pos ~/ 0x20] & (1 << (pos & 0x1f))) != 0);  
  
  // no bounds checking for performance reasons
  void operator[]=(int pos, bool value) { 
        if (value)
           _data[pos ~/ 0x20] |= 1 << (pos & 0x1f);
        else
           _data[pos ~/ 0x20] &= ~(1 << (pos & 0x1f));
        version++;
  }

  /// Counts bits of the specified value.
  int countBits(bool value) {
     if (_length == 0) return 0;
     
     if (_selectedCountVersion != version) {
       _selectedCount = 0;
       int len = lengthInInts;
       int i = 0;
       for (; i < len - 1; i++) 
          for (var k = _data[i]; k != 0; k >>= 8)  //todo: cast data[i] to uint
            _selectedCount += _onBitCount[k & 0xff];
  
       // The last int. 
       {
          var k = _data[i];
          int remainingBits = length & 0x1f;
          if (remainingBits != 0) // if remainingBits == 0, the last int is fully used and ALL bits should be left as is.
             k &= ~((4294967295) << remainingBits);
          for (; k != 0; k >>= 8)
            _selectedCount += _onBitCount[k & 0xff];
       }
     }
     
     return (value ? _selectedCount : length - _selectedCount);
  }

  void clear() => setLength(0);

  bool contains(bool value) => findNext(-1, value) >= 0;

  /// Returns the position of the next bit of the specified value, starting from the specified position.
  /// Returns -1, if there are no such bits.
  int findNext(int index, bool value) {
    assureInRange(index, -1, length, "index");
    
    if (index >= length - 1) return -1;
    index = index < 0 ? 0 : index + 1; // skip start
    int unusedBits = index & 0x1f;
    int numInts = lengthInInts;
     
    for (int i = index ~/ 32; i < numInts; i++)
    {
      var k = (value ? _data[i] : ~_data[i]);  // uint cast
      if (unusedBits != 0) {
        k &= 4294967295 << unusedBits;
        unusedBits = 0;
      }

      for (int j = 0; k != 0; j += 8, k >>= 8) {
        int p = _firstOnBit[k & 0xff];
        if (p >= 0) {
          index = p + (i * 32) + j;
          if (index >= length) return -1;
          return index;
        }
      }
    }
    return -1;
  }

  /// Finds previous bit of the specified value in the bitset.
  int findPrev(int index, bool value) {
    if (index == 0) return -1;
    assureInRange(index, -1, length, "index");

    index = index < 0 ? length - 1 : index - 1; // skip start

    int lastIntIdx = index ~/ 0x20;
    int remainingBits = (index + 1) & 0x1f;

    for (int i = lastIntIdx; i >= 0; i--) {
      var k = (value ? _data[i] : ~_data[i]);  // cast
      if (remainingBits != 0) {
        k &= ~((~4294967295) << remainingBits);
        remainingBits = 0;
      }
      for (int j = 24; k != 0; j -= 8, k <<= 8) {
        int p = _lastOnBit[k >> 0x18];
        if (p >= 0)
          return p + (i * 32) + j;
      }
    }
    return -1;
  }

  Iterable<int> indices([bool flag = true, int startAfter = -1]) => new _BitSetIterable(this, flag);

  int beginUpdate() => _updateLevel++;

  void endUpdate()
  {
     if (--_updateLevel == 0 && changed != null)
        _changeController.add(-77);
  }
}

class _BitSetIterable extends Object with IterableMixin<int>{
  int _index = -1;
  bool _flag;
  BitSet _bitset;

  _BitSetIterable(this._bitset, this._flag);
  
  Iterator<int> get iterator => new _BitSetIndexIterator(_bitset, _flag);
}

class _BitSetIndexIterator implements Iterator<int> {
  int _index = -1;
  bool _flag;
  BitSet _bitset;

  _BitSetIndexIterator(this._bitset, this._flag);

  bool moveNext() => (_index = _bitset.findNext(_index, _flag)) != -1;

  int get current => _index;
}