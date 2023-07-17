// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

struct TimerData {
    /// @notice the time the contract started (seconds)
    uint256 startTime;
    /// @notice the time the contract is running from startTime (seconds)
    uint256 runningTime;
}

/// @title provides functionality to use time
library TimerLib {
    using TimerLib for Timer;
    struct Timer {
        /// @notice the time the contract started
        uint256 startTime;
        /// @notice the time the contract is running from startTime
        uint256 runningTime;
        /// @notice is the timer paused
        bool paused;
    }

    /// @notice is the timer running - marked as running and has time remaining
    function _deadline(Timer storage self) internal view returns (uint256) {
        return self.startTime + self.runningTime;
    }

    function _now() internal view returns (uint256) {
        // solhint-disable-next-line not-rely-on-time
        return block.timestamp;
    }

    /// @notice is the timer running - marked as running and has time remaining
    function _isRunning(Timer storage self) internal view returns (bool) {
        return !self.paused && (self._deadline() > _now());
    }

    /// @notice starts the timer, call again to restart
    function _start(Timer storage self, uint256 runningTime) internal {
        self.paused = false;
        self.startTime = _now();
        self.runningTime = runningTime;
    }

    /// @notice updates the running time
    function _updateRunningTime(Timer storage self, uint256 runningTime)
        internal
    {
        self.runningTime = runningTime;
    }
}