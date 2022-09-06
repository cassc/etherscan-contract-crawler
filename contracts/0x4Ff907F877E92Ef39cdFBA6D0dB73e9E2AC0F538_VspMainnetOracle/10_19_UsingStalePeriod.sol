// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "../access/Governable.sol";

/**
 * @title Stale price check feature, useful when checking if prices are fresh enough
 */
abstract contract UsingStalePeriod is Governable {
    /// @notice The stale period. It's used to determine if a price is invalid (i.e. outdated)
    uint256 public stalePeriod;

    /// @notice Emitted when stale period is updated
    event StalePeriodUpdated(uint256 oldStalePeriod, uint256 newStalePeriod);

    constructor(uint256 stalePeriod_) {
        stalePeriod = stalePeriod_;
    }

    /**
     * @notice Update stale period
     */
    function updateStalePeriod(uint256 stalePeriod_) external onlyGovernor {
        emit StalePeriodUpdated(stalePeriod, stalePeriod_);
        stalePeriod = stalePeriod_;
    }

    /**
     * @notice Check if a price timestamp is outdated
     * @dev Uses default stale period
     * @param timeOfLastUpdate_ The price timestamp
     * @return true if price is stale (outdated)
     */
    function _priceIsStale(uint256 timeOfLastUpdate_) internal view returns (bool) {
        return _priceIsStale(timeOfLastUpdate_, stalePeriod);
    }

    /**
     * @notice Check if a price timestamp is outdated
     * @param timeOfLastUpdate_ The price timestamp
     * @param stalePeriod_ The maximum acceptable outdated period
     * @return true if price is stale (outdated)
     */
    function _priceIsStale(uint256 timeOfLastUpdate_, uint256 stalePeriod_) internal view returns (bool) {
        return block.timestamp - timeOfLastUpdate_ > stalePeriod_;
    }
}