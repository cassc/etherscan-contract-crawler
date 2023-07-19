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

import "@openzeppelin/contracts/interfaces/IERC20.sol";

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
abstract contract TaskManaged {

    struct Task {
        uint256 id;
        string uri;
        bool administrative;
        uint nrApprovals;
        bool finalized;
    }
    mapping (uint256 => Task) private _tasks;
    mapping (uint256 => mapping(address => bool)) private _taskApprovals;
    uint256 private _taskIdCounter;

    event TaskCreated(uint256 indexed taskId, string uri, bool administrative);
    event TaskApproved(uint256 taskId);
    event TaskApprovalWithdrawn(uint256 taskId);
    event TaskFinalized(uint256 taskId, string reason);

    modifier taskMustExist(uint256 taskId) {
        require(_taskExists(taskId), "TaskManaged: task does not exist");
        _;
    }

    modifier taskMustBeAdministrative(uint256 taskId) {
        require(_isTaskAdministrative(taskId), "TaskManaged: invalid task type");
        _;
    }

    modifier taskMustNotBeAdministrative(uint256 taskId) {
        require(!_isTaskAdministrative(taskId), "TaskManaged: invalid task type");
        _;
    }

    modifier taskMustBeApproved(uint256 taskId) {
        require(_isTaskApproved(taskId), "TaskManaged: task is not approved");
        _;
    }

    modifier taskMustNotBeFinalized(uint256 taskId) {
        require(!_isTaskFinalized(taskId), "TaskManaged: task is finalized");
        _;
    }

    constructor() {
        _taskIdCounter = 1;
    }

    function _getRequiredNrApprovals(uint256 taskId) internal view virtual returns (uint);

    function _taskExists(uint256 taskId) internal view virtual returns (bool) {
        return _tasks[taskId].id > 0;
    }

    function _isTaskAdministrative(uint256 taskId) internal view virtual returns (bool) {
        require(_taskExists(taskId), "TaskManaged: task does not exist");
        return _tasks[taskId].administrative;
    }

    function _isTaskApproved(uint256 taskId) internal view virtual returns (bool) {
        require(_taskExists(taskId), "TaskManaged: task does not exist");
        return _tasks[taskId].nrApprovals >= _getRequiredNrApprovals(taskId);
    }

    function _isTaskFinalized(uint256 taskId) internal view virtual returns (bool) {
        require(_taskExists(taskId), "TaskManaged: task does not exist");
        return _tasks[taskId].finalized;
    }

    function _getTaskURI(uint256 taskId) internal view virtual returns (string memory) {
        require(_taskExists(taskId), "TaskManaged: task does not exist");
        return _tasks[taskId].uri;
    }

    function _getTaskNrApprovals(uint256 taskId) internal view virtual returns (uint) {
        require(_taskExists(taskId), "TaskManaged: task does not exist");
        return _tasks[taskId].nrApprovals;
    }

    function _createTask(
        string memory taskURI,
        bool isAdministrative
    ) internal virtual returns (uint256) {
        uint256 taskId = _taskIdCounter;
        _taskIdCounter++;
        Task memory task = Task(taskId, taskURI, isAdministrative, 0, false);
        _tasks[taskId] = task;
        emit TaskCreated(taskId, taskURI, isAdministrative);
        return taskId;
    }

    function _approveTask(address doer, uint256 taskId) internal virtual {
        require(_taskExists(taskId), "TaskManaged: task does not exist");
        require(!_taskApprovals[taskId][doer], "TaskManaged: task is already approved");
        _taskApprovals[taskId][doer] = true;
        _tasks[taskId].nrApprovals += 1;
        emit TaskApproved(taskId);
    }

    function _withdrawTaskApproval(address doer, uint256 taskId) internal virtual {
        require(_taskExists(taskId), "TaskManaged: task does not exist");
        require(_taskApprovals[taskId][doer], "TaskManaged: task is not approved");
        _taskApprovals[taskId][doer] = false;
        _tasks[taskId].nrApprovals -= 1;
        emit TaskApprovalWithdrawn(taskId);
    }

    function _finalizeTask(uint256 taskId, string memory reason) internal virtual {
        require(_taskExists(taskId), "TaskManaged: task does not exist");
        _tasks[taskId].finalized = true;
        emit TaskFinalized(taskId, reason);
    }
}