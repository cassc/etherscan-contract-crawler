// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

library Random {
    /// @notice Generates a random number from the specified range.
    /// @param nonce Value used to increase randomness.
    /// @param min Minimum value of the range.
    /// @param max Maximum value of the range.
    /// @param sender Address used to increase randomness.
    /// @return Returns the random number.
    function number(uint256 nonce, uint256 min, uint256 max, address sender) internal view returns (uint256) {
        uint256 value = uint256(keccak256(abi.encodePacked(block.difficulty, block.gaslimit, sender, block.number, nonce)));

        return (value % max) + min;
    }
}