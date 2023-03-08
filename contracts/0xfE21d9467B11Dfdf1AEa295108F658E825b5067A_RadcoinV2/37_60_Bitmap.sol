// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0;

library Bitmaps {
    struct Bitmap {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function.
        // bitmaps length should be maxSupply / 256.
        uint256[] _bitmaps;
    }

    function makeBitmap(uint256 _size) internal pure returns (Bitmap memory) {
        Bitmap memory bitmap;
        bitmap._bitmaps = new uint256[](_size / 256 + 1);
        return bitmap;
    }

    using Bits for uint256;

    function set(Bitmap storage _bitmap, uint256 _index, bool _value) internal {
        uint256 _bitmapIndex = _index / 256;
        uint256 _bitIndex = _index % 256;
        if (_value) {
            _bitmap._bitmaps[_bitmapIndex] = _bitmap._bitmaps[_bitmapIndex].setBit(_bitIndex);
        } else {
            _bitmap._bitmaps[_bitmapIndex] = _bitmap._bitmaps[_bitmapIndex].clearBit(_bitIndex);
        }
    }

    function get(Bitmap storage _bitmap, uint256 _index) internal view returns (bool) {
        uint256 _bitmapIndex = _index / 256;
        uint256 _bitIndex = _index % 256;
        return _bitmap._bitmaps[_bitmapIndex].bitSet(_bitIndex);
    }
}

library Bits {
    uint256 internal constant ONE = uint256(1);

    // Sets the bit at the given 'index' in 'self' to '1'.
    // Returns the modified value.
    function setBit(uint256 self, uint256 index) internal pure returns (uint256) {
        return self | (ONE << index);
    }

    // Sets the bit at the given 'index' in 'self' to '0'.
    // Returns the modified value.
    function clearBit(uint256 self, uint256 index) internal pure returns (uint256) {
        return self & ~(ONE << index);
    }

    // Sets the bit at the given 'index' in 'self' to:
    //  '1' - if the bit is '0'
    //  '0' - if the bit is '1'
    // Returns the modified value.
    function toggleBit(uint256 self, uint256 index) internal pure returns (uint256) {
        return self ^ (ONE << index);
    }

    // Get the value of the bit at the given 'index' in 'self'.
    function bit(uint256 self, uint256 index) internal pure returns (uint256) {
        return uint256((self >> index) & 1);
    }

    // Check if the bit at the given 'index' in 'self' is set.
    // Returns:
    //  'true' - if the value of the bit is '1'
    //  'false' - if the value of the bit is '0'
    function bitSet(uint256 self, uint256 index) internal pure returns (bool) {
        return (self >> index) & 1 == 1;
    }

    // Checks if the bit at the given 'index' in 'self' is equal to the corresponding
    // bit in 'other'.
    // Returns:
    //  'true' - if both bits are '0' or both bits are '1'
    //  'false' - otherwise
    function bitEqual(uint256 self, uint256 other, uint256 index) internal pure returns (bool) {
        return ((self ^ other) >> index) & 1 == 0;
    }

    // Get the bitwise NOT of the bit at the given 'index' in 'self'.
    function bitNot(uint256 self, uint256 index) internal pure returns (uint256) {
        return uint256(1 - ((self >> index) & 1));
    }

    // Computes the bitwise AND of the bit at the given 'index' in 'self', and the
    // corresponding bit in 'other', and returns the value.
    function bitAnd(uint256 self, uint256 other, uint256 index) internal pure returns (uint256) {
        return uint256(((self & other) >> index) & 1);
    }

    // Computes the bitwise OR of the bit at the given 'index' in 'self', and the
    // corresponding bit in 'other', and returns the value.
    function bitOr(uint256 self, uint256 other, uint256 index) internal pure returns (uint256) {
        return uint256(((self | other) >> index) & 1);
    }

    // Computes the bitwise XOR of the bit at the given 'index' in 'self', and the
    // corresponding bit in 'other', and returns the value.
    function bitXor(uint256 self, uint256 other, uint256 index) internal pure returns (uint256) {
        return uint256(((self ^ other) >> index) & 1);
    }

    // Computes the index of the highest bit set in 'self'.
    // Returns the highest bit set as an 'uint256'.
    // Requires that 'self != 0'.
    function highestBitSet(uint256 self) internal pure returns (uint256 highest) {
        require(self != 0);
        uint256 val = self;
        for (uint256 i = 128; i >= 1; i >>= 1) {
            if (val & (((ONE << i) - 1) << i) != 0) {
                highest += i;
                val >>= i;
            }
        }
    }

    // Computes the index of the lowest bit set in 'self'.
    // Returns the lowest bit set as an 'uint256'.
    // Requires that 'self != 0'.
    function lowestBitSet(uint256 self) internal pure returns (uint256 lowest) {
        require(self != 0);
        uint256 val = self;
        for (uint256 i = 128; i >= 1; i >>= 1) {
            if (val & ((ONE << i) - 1) == 0) {
                lowest += i;
                val >>= i;
            }
        }
    }
}