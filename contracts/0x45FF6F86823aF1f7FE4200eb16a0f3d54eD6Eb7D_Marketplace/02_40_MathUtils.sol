// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

library MathUtils {
    /// Returns random number between 0 and max
    function simpleRandom(uint128 seed, uint256 max) internal view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, seed))) % max;
    }

    function calculatePart(uint256 value, uint256 percent) internal pure returns (uint256) {
        require(percent <= 100000, 'Impossible to have that part.');
        return (value * percent) / 100000;
    }
}