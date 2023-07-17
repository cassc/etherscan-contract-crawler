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

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

import './BaseAction.sol';

/**
 * @title Time-locked action
 * @dev Action that offers a time-lock mechanism to allow executing it only once during a set period of time
 */
abstract contract TimeLockedAction is BaseAction {
    // Period in seconds
    uint256 public period;

    // Next timestamp in the future when the action can be executed again
    uint256 public nextResetTime;

    /**
     * @dev Emitted every time a time-lock is set
     */
    event TimeLockSet(uint256 period);

    /**
     * @dev Creates a new time-locked action
     */
    constructor() {
        nextResetTime = block.timestamp;
    }

    /**
     * @dev Sets a new period for the time-locked action
     * @param newPeriod New period to be set
     */
    function setTimeLock(uint256 newPeriod) external auth {
        period = newPeriod;
        emit TimeLockSet(newPeriod);
    }

    /**
     * @dev Internal function to validate the time-locked action
     */
    function _validateTimeLock() internal {
        require(block.timestamp >= nextResetTime, 'TIME_LOCK_NOT_EXPIRED');
        nextResetTime = block.timestamp + period;
    }
}