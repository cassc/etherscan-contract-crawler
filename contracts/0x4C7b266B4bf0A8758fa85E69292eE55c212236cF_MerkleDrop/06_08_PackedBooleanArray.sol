// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

/// @title PackedBooleanArray
/// @author alsco77
library PackedBooleanArray {
    using PackedBooleanArray for PackedBooleanArray.PackedArray;

    struct PackedArray {
        uint256[] array;
    }

    // Verifies that the higher level count is correct, and that the last uint256 is left packed with 0's
    function initStruct(uint256[] memory _arr, uint256 _len)
        internal
        pure
        returns (PackedArray memory)
    {
        uint256 actualLength = _arr.length;
        uint256 len0 = _len / 256;
        require(actualLength == len0 + 1, "Invalid arr length");

        uint256 len1 = _len % 256;
        uint256 leftPacked = uint256(_arr[len0] >> len1);
        require(leftPacked == 0, "Invalid uint256 packing");

        return PackedArray(_arr);
    }

    // Gets the value at _index, or returns false if the _index does not exist
    function getValue(PackedArray storage ref, uint256 _index) internal view returns (bool) {
        uint256 aid = _index / 256;
        if(aid >= ref.array.length) return false;

        uint256 iid = _index % 256;
        return (ref.array[aid] >> iid) & 1 == 1 ? true : false;
    }

    // Sets the value at a given _index, adding a new entry to the array and updating length if necessary
    function setValue(
        PackedArray storage ref,
        uint256 _index,
        bool _value
    ) internal {
        // 0. Ensure array is long enough, and extend if necessary
        uint256 aid = _index / 256;
        if(aid >= ref.array.length) {
            uint256 delta = aid - ref.array.length + 1;
            for(uint256 i = 0; i < delta; i++){
                ref.array.push(0);
            }
        }

        uint256 iid = _index % 256;

        // 1. Do an & between old value and a mask
        uint256 mask = uint256(~(uint256(1) << iid));
        uint256 masked = ref.array[aid] & mask;

        // 2. Do an |= between (1) and positioned _value
        mask = uint256(_value ? 1 : 0) << (iid);
        ref.array[aid] = masked | mask;
    }
}