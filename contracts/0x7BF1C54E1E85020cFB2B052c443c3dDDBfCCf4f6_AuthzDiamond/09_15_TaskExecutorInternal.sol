/*
 * This file is part of the Qomet Technologies contracts (https://github.com/qomet-tech/contracts).
 * Copyright (c) 2022 Qomet Technologies (https://qomet.tech)
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
import "./TaskExecutorStorage.sol";

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
library TaskExecutorInternal {

    event TaskManagerSet(address newTaskManager);

    function _getTaskManager() internal view returns (address) {
        return __s().taskManager;
    }

    function _setTaskManager(address newTaskManager) internal {
        require(newTaskManager != address(0), "TE:ZA");
        require(IERC165(newTaskManager).supportsInterface(type(ITaskExecutor).interfaceId),
            "TE:IC");
        __s().taskManager = newTaskManager;
        emit TaskManagerSet(__s().taskManager);
    }

    function _executeTask(uint256 taskId) internal {
        require(__s().taskManager != address(0), "TE:NTM");
        ITaskExecutor(__s().taskManager).executeTask(msg.sender, taskId);
    }

    function __s() private pure returns (TaskExecutorStorage.Layout storage) {
        return TaskExecutorStorage.layout();
    }
}