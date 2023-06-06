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
import "../hasher/HasherLib.sol";
import "./ITaskExecutor.sol";
import "./TaskExecutorStorage.sol";

library TaskExecutorInternal {

    event TaskManagerSet (
        string key,
        address taskManager
    );

    function _initialize(
        address newTaskManager
    ) internal {
        require(!__s().initialized, "TFI:AI");
        __setTaskManager("DEFAULT", newTaskManager);
        __s().initialized = true;
    }

    function _getTaskManagerKeys() internal view returns (string[] memory) {
        return __s().keys;
    }

    function _getTaskManager(string memory key) internal view returns (address) {
        bytes32 keyHash = HasherLib._hashStr(key);
        require(__s().keysIndex[keyHash] > 0, "TFI:KNF");
        return __s().taskManagers[keyHash];
    }

    function _setTaskManager(
        uint256 adminTaskId,
        string memory key,
        address newTaskManager
    ) internal {
        require(__s().initialized, "TFI:NI");
        bytes32 keyHash = HasherLib._hashStr(key);
        address oldTaskManager = __s().taskManagers[keyHash];
        __setTaskManager(key, newTaskManager);
        if (oldTaskManager != address(0)) {
            ITaskExecutor(oldTaskManager).executeAdminTask(msg.sender, adminTaskId);
        } else {
            address defaultTaskManager = _getTaskManager("DEFAULT");
            require(defaultTaskManager != address(0), "TFI:ZDTM");
            ITaskExecutor(defaultTaskManager).executeAdminTask(msg.sender, adminTaskId);
        }
    }

    function _executeTask(
        string memory key,
        uint256 taskId
    ) internal {
        require(__s().initialized, "TFI:NI");
        address taskManager = _getTaskManager(key);
        require(taskManager != address(0), "TFI:ZTM");
        ITaskExecutor(taskManager).executeTask(msg.sender, taskId);
    }

    function _executeAdminTask(
        string memory key,
        uint256 adminTaskId
    ) internal {
        require(__s().initialized, "TFI:NI");
        address taskManager = _getTaskManager(key);
        require(taskManager != address(0), "TFI:ZTM");
        ITaskExecutor(taskManager).executeAdminTask(msg.sender, adminTaskId);
    }

    function __setTaskManager(
        string memory key,
        address newTaskManager
    ) internal {
        require(newTaskManager != address(0), "TFI:ZA");
        require(IERC165(newTaskManager).supportsInterface(type(ITaskExecutor).interfaceId),
            "TFI:IC");
        bytes32 keyHash = HasherLib._hashStr(key);
        if (__s().keysIndex[keyHash] == 0) {
            __s().keys.push(key);
            __s().keysIndex[keyHash] = __s().keys.length;
        }
        __s().taskManagers[keyHash] = newTaskManager;
        emit TaskManagerSet(key, newTaskManager);
    }

    function __s() private pure returns (TaskExecutorStorage.Layout storage) {
        return TaskExecutorStorage.layout();
    }
}