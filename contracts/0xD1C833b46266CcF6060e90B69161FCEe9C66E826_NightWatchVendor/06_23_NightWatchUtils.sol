// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @notice Library for simple math operations of Night Watch
/// @author @YigitDuman
library NightWatchUtils {
    /// @notice Sorts two numbers in ascending order
    function sortTokens(
        uint256 a,
        uint256 b
    ) internal pure returns (uint256, uint256) {
        return (a <= b) ? (a, b) : (b, a);
    }

    function shuffleArray(
        uint16[] memory shuffle,
        uint256 entropy
    ) internal pure {
        for (uint256 i = shuffle.length - 1; i > 0; i--) {
            uint256 swapIndex = entropy % (shuffle.length - i);

            uint16 currentIndex = shuffle[i];
            uint16 indexToSwap = shuffle[swapIndex];

            shuffle[i] = indexToSwap;
            shuffle[swapIndex] = currentIndex;
        }
    }
}