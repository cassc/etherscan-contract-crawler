//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library Integer {
    /**
     * @dev Gets the bit at the given position in the given integer.
     *      255 is the leftmost bit, 0 is the rightmost bit.
     *
     *      For example: bitAt(2, 0) == 0, because the rightmost bit of 10 is 0
     *                   bitAt(2, 1) == 1, because the second to last bit of 10 is 1
     */
    function bitAt(uint integer, uint pos) internal pure returns (uint) {
        require(pos <= 255, "pos > 255");

        return (integer & (1 << pos)) >> pos;
    }

    function setBitAt(uint integer, uint pos) internal pure returns (uint) {
        return integer | (1 << pos);
    }

    /**
     * @dev Gets the value of the bits between left and right, both inclusive, in the given integer.
     *      255 is the leftmost bit, 0 is the rightmost bit.
     *      
     *      For example: bitsFrom(10, 3, 1) == 7 (101 in binary), because 10 is *101*0 in binary
     *                   bitsFrom(10, 2, 0) == 2 (010 in binary), because 10 is 1*010* in binary
     */
    function bitsFrom(uint integer, uint left, uint right) internal pure returns (uint) {
        require(left >= right, "left > right");
        require(left <= 255, "left > 255");

        uint delta = left - right + 1;

        return (integer & (((1 << delta) - 1) << right)) >> right;
    }
}