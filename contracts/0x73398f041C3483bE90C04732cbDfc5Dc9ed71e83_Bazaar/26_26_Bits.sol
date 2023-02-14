// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;


/**
 * @dev Library for managing uint to bool mapping in a compact and efficient way, providing the keys are sequential.
 * based on https://docs.openzeppelin.com/contracts/4.x/api/utils#BitMaps
 */
library Bits {

    struct Bitmap {
        mapping(uint => uint) data;
    }

    uint constant internal ONES = ~uint(0);

    function get(Bitmap storage self, uint index) internal view returns (bool) {
        uint bucket = index >> 8;
        uint mask = 1 << (index & 0xff);
        return self.data[bucket] & mask != 0;
    }

    function set(Bitmap storage self, uint index) internal {
        uint bucket = index >> 8;
        uint mask = 1 << (index & 0xff);
        self.data[bucket] |= mask;
    }

    function setAll(Bitmap storage self, uint size) internal {
        uint fullBuckets = size >> 8;
        if (fullBuckets > 0) for (uint i = 0; i < fullBuckets; i++) self.data[i] = ONES;
        uint remaining = size & 0xff;
        if(remaining == 0 ) return ;
        self.data[fullBuckets] = ONES >> (256 - remaining);
    }

    function unset(Bitmap storage self, uint index) internal {
        uint bucket = index >> 8;
        uint mask = 1 << (index & 0xff);
        self.data[bucket] &= ~mask;
    }

    function toggle(Bitmap storage self, uint index) internal {
        setTo(self, index, !get(self, index));
    }

    function setTo(Bitmap storage self, uint index, bool value) private {
        value ? set(self, index) : unset(self, index);
    }

    /// @dev for tracing
    function toArray(Bitmap storage self, uint size) internal view returns (uint[] memory result) {
        result = new uint[]((size >> 8) + ((size & 0xff) > 0 ? 1 : 0));
        for (uint i = 0; i < result.length; i++) result[i] = self.data[i];
    }
}