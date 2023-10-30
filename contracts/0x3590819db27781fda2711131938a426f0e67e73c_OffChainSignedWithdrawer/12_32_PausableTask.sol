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

pragma solidity ^0.8.17;

import '@mimic-fi/v3-authorizer/contracts/Authorized.sol';
import '@mimic-fi/v3-helpers/contracts/math/FixedPoint.sol';

import '../interfaces/base/IPausableTask.sol';

/**
 * @dev Pausable config for tasks
 */
abstract contract PausableTask is IPausableTask, Authorized {
    using FixedPoint for uint256;

    // Whether the task is paused or not
    bool public override isPaused;

    /**
     * @dev Initializes the pausable task. It does call upper contracts initializers.
     */
    function __PausableTask_init() internal onlyInitializing {
        __PausableTask_init_unchained();
    }

    /**
     * @dev Initializes the pausable task. It does not call upper contracts initializers.
     */
    function __PausableTask_init_unchained() internal onlyInitializing {
        // solhint-disable-previous-line no-empty-blocks
    }

    /**
     * @dev Pauses a task
     */
    function pause() external override auth {
        if (isPaused) revert TaskPaused();
        isPaused = true;
        emit Paused();
    }

    /**
     * @dev Unpauses a task
     */
    function unpause() external override auth {
        if (!isPaused) revert TaskUnpaused();
        isPaused = false;
        emit Unpaused();
    }

    /**
     * @dev Before pausable task hook
     */
    function _beforePausableTask(address, uint256) internal virtual {
        if (isPaused) revert TaskPaused();
    }

    /**
     * @dev After pausable task hook
     */
    function _afterPausableTask(address, uint256) internal virtual {
        // solhint-disable-previous-line no-empty-blocks
    }
}