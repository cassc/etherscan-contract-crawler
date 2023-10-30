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
 * @dev Pausable task interface
 */
interface IPausableTask is IBaseTask {
    /**
     * @dev The task is paused
     */
    error TaskPaused();

    /**
     * @dev The task is unpaused
     */
    error TaskUnpaused();

    /**
     * @dev Emitted every time a task is paused
     */
    event Paused();

    /**
     * @dev Emitted every time a task is unpaused
     */
    event Unpaused();

    /**
     * @dev Tells the task is paused or not
     */
    function isPaused() external view returns (bool);

    /**
     * @dev Pauses a task
     */
    function pause() external;

    /**
     * @dev Unpauses a task
     */
    function unpause() external;
}