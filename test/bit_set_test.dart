import 'package:unittest/unittest.dart';
import 'package:bit_set/bit_set.dart';

BitSet bs(String s) => new BitSet.fromString(s);
BitSet get oooo => bs("0000");
BitSet get oioi => bs("0101");
BitSet get ioio => bs("1010");
BitSet get iiii => bs("1111");

void main() {
  
  test("constructor", () {
    expect(new BitSet(4, true).toBinaryString(), "1111");
    expect(new BitSet(4, false).toBinaryString(), "0000");
  }); 

  test("index", () {
    expect(oioi[0], false);
    expect(oioi[1], true);
    expect(oioi[2], false);
    expect(oioi[3], true);
    //expect(() { oioi[4]; }, throwsArgumentError);    
  }); 
  
  test("setLength", () {
    expect((oioi..setLength(3)).toBinaryString(), "010");
    expect((oioi..setLength(4)).toBinaryString(), "0101");
    expect((oioi..setLength(5)).toBinaryString(), "01010");
    expect(() { oioi.setLength(-4); }, throwsArgumentError);    
  }); 
  
  test("findNext", () {
    expect(oioi.findNext(-1, true), 1);
    expect(oioi.findNext(0, true), 1);
    expect(oioi.findNext(1, true), 3);
    expect(oioi.findNext(2, true), 3);
    expect(oioi.findNext(3, true), -1);
    expect(oioi.findNext(-1, false), 0);
    expect(oioi.findNext(0, false), 2);
    expect(oioi.findNext(1, false), 2);
    expect(oioi.findNext(2, false), -1);
    expect(oioi.findNext(3, false), -1);
    expect((new BitSet(35, false)..[33]=true).findNext(3, true), 33);
  });
  
  test("fromString", () {
    expect(bs("0101").toBinaryString(), "0101");
    expect(bs("0101").toBinaryString(), "0101");
  });
  
  test("countBits", () {
    expect(bs("0111").countBits(true), 3);
    expect(bs("0111").countBits(false), 1);
    expect(bs("00000000").countBits(true), 0);
    expect(bs("00000000").countBits(false), 8);
    expect(bs("11111111").countBits(true), 8);
    expect(bs("11111111").countBits(false), 0);
    expect(new BitSet(32, true).countBits(true), 32);
    expect(new BitSet(33, true).countBits(true), 33);
  });
  
  test("and", () {
    expect((oooo..and(oooo)).equals(oooo), true);    
    expect((oioi..and(iiii)).equals(oioi), true);
    expect((oioi..and(oioi)).equals(oioi), true);
    expect((oioi..and(ioio)).equals(oooo), true);
    expect((iiii..and(oooo)).equals(oooo), true);    
  });
  
  test("or", () {
    expect((oooo..or(oooo)).equals(oooo), true);    
    expect((oioi..or(iiii)).equals(iiii), true);
    expect((ioio..or(iiii)).equals(iiii), true);    
    expect((ioio..or(ioio)).equals(ioio), true);    
    expect((ioio..or(oooo)).equals(ioio), true);    
    expect((ioio..or(oioi)).equals(iiii), true);    
  });
  
  test("version", () {
    var b = bs("1111"); 
    expect(b.version == 0, true);
    b[1] = false;
    expect(b.version == 1, true);
  });
  
  test("usage", () {
    var bitset = new BitSet.fromString("01010");
    var length = bitset.length;  // 5
    bitset.insertAt(1, 2, true);  // 0111010
    var bit = bitset[2];  // true
    var count = bitset.countBits(true);  // 4
    var xor = bitset.clone().xor(bitset);
    count = bitset.countBits(true);  // 0
  });
  
}