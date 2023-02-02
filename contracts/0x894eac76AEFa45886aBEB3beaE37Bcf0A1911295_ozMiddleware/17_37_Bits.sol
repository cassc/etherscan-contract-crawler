// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.14;


import './AppStorage.sol';


/**
 * @notice Access control methods implemented on bitmaps
 */
abstract contract Bits {

    AppStorage s;

    /**
     * @dev Queries if bit at index_ in bitmap_ is higher than 0
     */
    function _getBit(uint bitmap_, uint index_) internal view returns(bool) {
        uint bit = s.bitLocks[bitmap_] & (1 << index_);
        return bit > 0;
    }

    /**
     * @dev Flips bit at index_ from bitmap_
     */
    function _toggleBit(uint bitmap_, uint index_) internal {
        s.bitLocks[bitmap_] ^= (1 << index_);
    }
}