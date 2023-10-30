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

pragma solidity >=0.8.0;

import './IBaseTask.sol';

/**
 * @dev Time-locked task interface
 */
interface ITimeLockedTask is IBaseTask {
    /**
     * @dev The time lock frequency mode requested is invalid
     */
    error TaskInvalidFrequencyMode(uint8 mode);

    /**
     * @dev The time lock frequency is not valid
     */
    error TaskInvalidFrequency(uint8 mode, uint256 frequency);

    /**
     * @dev The time lock allowed date is not valid
     */
    error TaskInvalidAllowedDate(uint8 mode, uint256 date);

    /**
     * @dev The time lock allowed window is not valid
     */
    error TaskInvalidAllowedWindow(uint8 mode, uint256 window);

    /**
     * @dev The time lock is still active
     */
    error TaskTimeLockActive(uint256 currentTimestamp, uint256 expiration);

    /**
     * @dev Emitted every time a new time lock is set
     */
    event TimeLockSet(uint8 mode, uint256 frequency, uint256 allowedAt, uint256 window);

    /**
     * @dev Emitted every time a new expiration timestamp is set
     */
    event TimeLockAllowedAtSet(uint256 allowedAt);

    /**
     * @dev Tells all the time-lock related information
     */
    function getTimeLock() external view returns (uint8 mode, uint256 frequency, uint256 allowedAt, uint256 window);

    /**
     * @dev Sets the time-lock
     * @param mode Time lock mode
     * @param frequency Time lock frequency
     * @param allowedAt Future timestamp since when the task can be executed
     * @param window Period in seconds during when a time-locked task can be executed since the allowed timestamp
     */
    function setTimeLock(uint8 mode, uint256 frequency, uint256 allowedAt, uint256 window) external;
}