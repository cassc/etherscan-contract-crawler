// SPDX-License-Identifier: MIT
// Copyright 2023 PROOF Holdings Inc
pragma solidity ^0.8.15;

/**
 * @notice Module to rate limit a certain action per discrete block of time.
 * @author David Huber (@cxkoda)
 * @custom:reviewer Arran Schlosberg (@divergencearran)
 */
contract NonRollingRateLimited {
    /**
     * @notice Thrown if on attempts to exceed the rate limit.
     */
    error ExceedingRateLimit(uint256 requested, uint256 numLeft);

    /**
     * @notice The duration of a period in seconds.
     */
    uint64 private immutable _periodLength;

    /**
     * @notice The index of the last period for which an action has been performed.
     */
    uint64 private _lastPeriod;

    /**
     * @notice The maximum number of actions that can be performed in a period.
     */
    uint64 private __maxActionsPerPeriod;

    /**
     * @notice The number of actions that have been performed in the current period.
     * @dev Will automatically be reset to 0 in `rateLimited` at the start of each period.
     */
    uint64 private __performedCurrentPeriod;

    constructor(uint64 maxActionsPerPeriod, uint64 periodLength) {
        _periodLength = periodLength;
        _setMaxActionsPerPeriod(maxActionsPerPeriod);
    }

    /**
     * @notice Helper function to get the index of the current period.
     */
    function _currentPeriod() private view returns (uint64) {
        return uint64(block.timestamp / _periodLength);
    }

    /**
     * @notice Sets the maximum number of actions per period.
     */
    function _setMaxActionsPerPeriod(uint64 maxActionsPerPeriod) internal {
        __maxActionsPerPeriod = maxActionsPerPeriod;
    }

    /**
     * @notice Returns the maximum number of actions per period.
     */
    function _maxActionsPerPeriod() internal view returns (uint64) {
        return __maxActionsPerPeriod;
    }

    /**
     * @notice Keeps track of the number of performed actions.
     * @dev Reverts if the maximum number of actions per period is exceeded.
     */
    function _checkAndTrackRateLimit(uint64 requested) internal {
        uint64 performed = _performedCurrentPeriod();
        uint64 left = __maxActionsPerPeriod - performed;
        if (requested > left) {
            revert ExceedingRateLimit(requested, left);
        }
        __performedCurrentPeriod = performed + requested;
        _lastPeriod = _currentPeriod();
    }

    /**
     * @notice The number of actions performed in the current period.
     */
    function _performedCurrentPeriod() internal view returns (uint64) {
        if (_currentPeriod() > _lastPeriod) {
            return 0;
        }
        return __performedCurrentPeriod;
    }
}