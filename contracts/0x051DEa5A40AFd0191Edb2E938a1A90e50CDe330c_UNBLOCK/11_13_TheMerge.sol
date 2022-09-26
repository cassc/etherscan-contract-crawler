// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

contract TheMerge {
    uint72 private constant DIFFICULTY_THRESHOLD = 2**64;

    /**
     * @dev A difficulty value greater than `2**64` indicates that a transaction is
     * being executed in a PoS block. Also note that the `DIFFICULTY` opcode (0x44)
     * is renamed to `PREVRANDAO` post-merge.
     *
     * For further information, see here: https://eips.ethereum.org/EIPS/eip-4399.
     */
    function merged() public view returns (bool) {
        return block.difficulty > DIFFICULTY_THRESHOLD;
    }
}