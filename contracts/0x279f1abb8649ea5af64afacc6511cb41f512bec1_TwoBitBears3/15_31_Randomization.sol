// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./RandomizationErrors.sol";

/// @title Randomization library
/// @dev Lightweight library used for basic randomization capabilities for ERC-721 tokens when an Oracle is not available
library Randomization {

    /// Returns a value based on the spread of a random uint8 seed and provided percentages
    /// @dev The last percentage is assumed if the sum of all elements do not add up to 100, in which case the length of the array is returned
    /// @param random A uint8 random value
    /// @param percentages An array of percentages
    /// @return The index in which the random seed falls, which can be the length of the input array if the values do not add up to 100
    function randomIndex(uint8 random, uint8[] memory percentages) internal pure returns (uint256) {
        uint256 spread = (3921 * uint256(random) / 10000) % 100; // 0-255 needs to be balanced to evenly spread with % 100
        uint256 remainingPercent = 100;
        for (uint256 i = 0; i < percentages.length; i++) {
            uint256 nextPercentage = percentages[i];
            if (remainingPercent < nextPercentage) revert PercentagesGreaterThan100();
            remainingPercent -= nextPercentage;
            if (spread >= remainingPercent) {
                return i;
            }
        }
        return percentages.length;
    }

    /// Returns a random seed suitable for ERC-721 attribute generation when an Oracle such as Chainlink VRF is not available to a contract
    /// @dev Not suitable for mission-critical code. Always be sure to perform an analysis of your randomization before deploying to production
    /// @param initialSeed A uint256 that seeds the randomization function
    /// @return A seed that can be used for attribute generation, which may also be used as the `initialSeed` for a future call
    function randomSeed(uint256 initialSeed) internal view returns (uint256) {
        // Unit tests should confirm that this provides a more-or-less even spread of randomness
        return uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), msg.sender, initialSeed >> 1)));
    }
}