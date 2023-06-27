// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.8.3;

import './BaseAction.sol';
import './interfaces/ITimeLockedAction.sol';

/**
 * @dev Time lock config for actions. It allows limiting the frequency of an action.
 */
abstract contract TimeLockedAction is ITimeLockedAction, BaseAction {
    // Period in seconds that must pass after an action has been executed
    uint256 private _delay;

    // Future timestamp in which the action can be executed
    uint256 private _expiresAt;

    /**
     * @dev Time lock config params. Only used in the constructor.
     * @param delay Period in seconds that must pass after an action has been executed
     * @param nextExecutionTimestamp Next time when the action can be executed
     */
    struct TimeLockConfig {
        uint256 delay;
        uint256 nextExecutionTimestamp;
    }

    /**
     * @dev Creates a new time locked action
     */
    constructor(TimeLockConfig memory config) {
        _setTimeLockDelay(config.delay);
        _setTimeLockExpiration(config.nextExecutionTimestamp);
    }

    /**
     * @dev Tells if a time-lock is expired or not
     */
    function isTimeLockExpired() public view override returns (bool) {
        return block.timestamp >= _expiresAt;
    }

    /**
     * @dev Tells the time-lock information
     */
    function getTimeLock() public view override returns (uint256 delay, uint256 expiresAt) {
        return (_delay, _expiresAt);
    }

    /**
     * @dev Sets the time-lock delay
     * @param delay New delay to be set
     */
    function setTimeLockDelay(uint256 delay) external override auth {
        _setTimeLockDelay(delay);
    }

    /**
     * @dev Sets the time-lock expiration timestamp
     * @param timestamp New expiration timestamp to be set
     */
    function setTimeLockExpiration(uint256 timestamp) external override auth {
        _setTimeLockExpiration(timestamp);
    }

    /**
     * @dev Reverts if the given time-lock is not expired
     */
    function _beforeAction(address, uint256) internal virtual override {
        require(isTimeLockExpired(), 'ACTION_TIME_LOCK_NOT_EXPIRED');
    }

    /**
     * @dev Bumps the time-lock expire date
     */
    function _afterAction(address, uint256) internal virtual override {
        if (_delay > 0) {
            uint256 expiration = (_expiresAt > 0 ? _expiresAt : block.timestamp) + _delay;
            _setTimeLockExpiration(expiration);
        }
    }

    /**
     * @dev Sets the time-lock delay
     * @param delay New delay to be set
     */
    function _setTimeLockDelay(uint256 delay) internal {
        _delay = delay;
        emit TimeLockDelaySet(delay);
    }

    /**
     * @dev Sets the time-lock expiration timestamp
     * @param timestamp New expiration timestamp to be set
     */
    function _setTimeLockExpiration(uint256 timestamp) internal {
        _expiresAt = timestamp;
        emit TimeLockExpirationSet(timestamp);
    }
}