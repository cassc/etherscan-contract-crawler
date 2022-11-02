// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "../access/Governable.sol";

/**
 * @title Stale price check feature, useful when checking if prices are fresh enough
 */
abstract contract UsingStalePeriod is Governable {
    /// @notice The default stale period. It's used to determine if a price is invalid (i.e. outdated)
    uint256 public defaultStalePeriod;

    /// @notice Custom stale period, used for token that has different stale window (e.g. some stable coins have 24h window)
    mapping(address => uint256) customStalePeriod;

    /// @notice Emitted when custom stale period is updated
    event CustomStalePeriodUpdated(address token, uint256 oldStalePeriod, uint256 newStalePeriod);

    /// @notice Emitted when default stale period is updated
    event DefaultStalePeriodUpdated(uint256 oldStalePeriod, uint256 newStalePeriod);

    constructor(uint256 defaultStalePeriod_) {
        defaultStalePeriod = defaultStalePeriod_;
    }

    /**
     * @notice Get stale period of a token
     */
    function stalePeriodOf(address token_) public view returns (uint256 _stalePeriod) {
        _stalePeriod = customStalePeriod[token_];
        if (_stalePeriod == 0) {
            _stalePeriod = defaultStalePeriod;
        }
    }

    /**
     * @notice Check if a price timestamp is outdated
     * @dev Uses default stale period
     * @param timeOfLastUpdate_ The price timestamp
     * @return true if price is stale (outdated)
     */
    function _priceIsStale(address token_, uint256 timeOfLastUpdate_) internal view returns (bool) {
        return _priceIsStale(timeOfLastUpdate_, stalePeriodOf(token_));
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

    /**
     * @notice Update custom stale period
     * @dev Use `0` as `stalePeriod_` to remove custom stale period
     */
    function updateCustomStalePeriod(address token_, uint256 stalePeriod_) external onlyGovernor {
        require(token_ != address(0), "token-is-null");
        emit CustomStalePeriodUpdated(token_, customStalePeriod[token_], stalePeriod_);
        if (stalePeriod_ > 0) {
            customStalePeriod[token_] = stalePeriod_;
        } else {
            delete customStalePeriod[token_];
        }
    }

    /**
     * @notice Update default stale period
     */
    function updateDefaultStalePeriod(uint256 stalePeriod_) external onlyGovernor {
        emit DefaultStalePeriodUpdated(defaultStalePeriod, stalePeriod_);
        defaultStalePeriod = stalePeriod_;
    }
}