// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "../access/Governable.sol";

/**
 * @title Deviation check feature, useful when checking prices from different providers for the same asset
 */
abstract contract UsingMaxDeviation is Governable {
    /**
     * @notice The max acceptable deviation
     * @dev 18-decimals scale (e.g 1e17 = 10%)
     */
    uint256 public maxDeviation;

    /// @notice Emitted when max deviation is updated
    event MaxDeviationUpdated(uint256 oldMaxDeviation, uint256 newMaxDeviation);

    constructor(uint256 maxDeviation_) {
        maxDeviation = maxDeviation_;
    }

    /**
     * @notice Update max deviation
     */
    function updateMaxDeviation(uint256 maxDeviation_) external onlyGovernor {
        emit MaxDeviationUpdated(maxDeviation, maxDeviation_);
        maxDeviation = maxDeviation_;
    }

    /**
     * @notice Check if two numbers deviation is acceptable
     */
    function _isDeviationOK(uint256 a_, uint256 b_) internal view returns (bool) {
        uint256 _deviation = a_ > b_ ? ((a_ - b_) * 1e18) / a_ : ((b_ - a_) * 1e18) / b_;
        return _deviation <= maxDeviation;
    }
}