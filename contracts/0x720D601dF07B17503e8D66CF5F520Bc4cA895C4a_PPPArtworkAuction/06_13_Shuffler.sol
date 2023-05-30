// SPDX-License-Identifier: MIT
// Copyright (c) 2023 Fellowship

pragma solidity ^0.8.7;

/// @notice A contract that draws (without replacement) pseudorandom shuffled values
/// @dev Uses prevrandao and Fisher-Yates shuffle to return values one at a time
contract Shuffler {
    uint256 internal remainingValueCount;
    /// @notice Mapping that lets `drawNext` find values that are still available
    /// @dev This is effectively the Fisher-Yates in-place array. Zero values stand in for their key to avoid costly
    ///  initialization. All other values are off-by-one so that zero can be represented. Keys from remainingValueCount
    ///  onward have their values set back to zero since they aren't needed once they've been drawn.
    mapping(uint256 => uint256) private shuffleValues;

    constructor(uint256 shuffleSize) {
        // CHECKS
        require(shuffleSize <= type(uint16).max, "Shuffle size is too large");

        // EFFECTS
        remainingValueCount = shuffleSize;
    }

    function drawNext() internal returns (uint256) {
        // CHECKS
        require(remainingValueCount > 0, "Shuffled values have been exhausted");

        // EFFECTS
        uint256 swapValue;
        unchecked {
            // Unchecked arithmetic: remainingValueCount is nonzero
            swapValue = shuffleValues[remainingValueCount - 1];
        }
        if (swapValue == 0) {
            swapValue = remainingValueCount;
        } else {
            shuffleValues[remainingValueCount - 1] = 0;
        }

        if (remainingValueCount == 1) {
            // swapValue is the last value left; just return it
            remainingValueCount = 0;
            unchecked {
                return swapValue - 1;
            }
        }

        uint256 randomIndex = uint256(keccak256(abi.encodePacked(remainingValueCount, block.difficulty))) %
            remainingValueCount;
        unchecked {
            // Unchecked arithmetic: remainingValueCount is nonzero
            remainingValueCount--;
            // Check if swapValue was drawn
            // Unchecked arithmetic: swapValue is nonzero
            if (randomIndex == remainingValueCount) return swapValue - 1;
        }

        // Draw the value at randomIndex and put swapValue in its place
        uint256 drawnValue = shuffleValues[randomIndex];
        shuffleValues[randomIndex] = swapValue;

        unchecked {
            // Unchecked arithmetic: only subtract if drawnValue is nonzero
            return drawnValue > 0 ? drawnValue - 1 : randomIndex;
        }
    }
}