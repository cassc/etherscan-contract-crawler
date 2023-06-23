// SPDX-License-Identifier: MIT
// https://github.com/ethereum/solidity-examples/blob/master/docs/bits/Bits.md
pragma solidity ^0.8.7;

library Bits {
    uint constant internal ONE = uint(1);

    function setBit(uint self, uint8 index) internal pure returns (uint) {
        return self | ONE << index;
    }

    function clearBit(uint self, uint8 index) internal pure returns (uint) {
        return self & ~(ONE << index);
    }

    function isBitSet(uint self, uint8 index) internal pure returns (bool) {
        return self >> index & 1 == 1;
    }
}