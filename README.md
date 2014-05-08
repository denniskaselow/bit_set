bit_set
=========

An implementation of a bit set, which is missing from the Dart core library. It has the following features:

- Efficient storage (uses Uint32List).
- Efficient bit mask operations (and, or, xor, not).
- Efficient counting of set bits.
- Efficient lookup for the next set bit.
- Support for change notifications and versioning.

###Usage

```dart
var bitset = new BitSet.fromString("01010");
var length = bitset.length;  // 5
bitset.insertAt(1, 2, true);  // 0111010
var bit = bitset[2];  // true
var count = bitset.countBits(true);  // 4
var xor = bitset.clone().xor(bitset);
count = bitset.countBits(true);  // 0
```    

###TODO:

- Use Uint32x4List for storage and make use of SIMD instructions.
- Serialization.
- Compression.
