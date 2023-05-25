/*
 * This file is part of the artèQ Technologies contracts (https://github.com/arteq-tech/contracts).
 * Copyright (c) 2022 artèQ Technologies (https://arteq.tech)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

import "@openzeppelin/contracts/interfaces/IERC165.sol";
import "../../interfaces/ITaskExecutor.sol";

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
abstract contract TaskExecutor {

    address private _taskManager;

    event TaskManagerChanged(address newTaskManager);

    modifier tryExecuteTaskAfterwards(uint256 taskId) {
        require(_taskManager != address(0), "TaskExecutor: task manager is not set");
        _;
        ITaskExecutor(_taskManager).executeTask(msg.sender, taskId);
    }

    function getTaskManager() external view returns (address) {
        return _getTaskManager();
    }

    function setTaskManager(
        uint256 adminTaskId,
        address newTaskManager
    ) external {
        address oldTaskManager = _taskManager;
        _setTaskManager(newTaskManager);
        if (oldTaskManager != address(0)) {
            ITaskExecutor(oldTaskManager).executeAdminTask(msg.sender, adminTaskId);
        }
    }

    function _getTaskManager() internal view returns (address) {
        return _taskManager;
    }

    function _setTaskManager(address newTaskManager) internal {
        require(newTaskManager != address(0), "TaskExecutor: zero address cannot be set");
        require(IERC165(newTaskManager).supportsInterface(type(ITaskExecutor).interfaceId),
            "TaskExecutor: invalid contract");
        _taskManager = newTaskManager;
        emit TaskManagerChanged(_taskManager);
    }
}