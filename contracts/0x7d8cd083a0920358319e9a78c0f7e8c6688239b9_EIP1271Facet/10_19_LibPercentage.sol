//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

/// @author Amit Molek
/// @dev Percentages helper
library LibPercentage {
    uint256 public constant PERCENTAGE_DIVIDER = 100; // 1 percent precision

    /// @dev Returns the ceil value of `percentage` out of `value`.
    function _calculateCeil(uint256 value, uint256 percentage)
        internal
        pure
        returns (uint256)
    {
        return Math.ceilDiv(value * percentage, PERCENTAGE_DIVIDER);
    }
}