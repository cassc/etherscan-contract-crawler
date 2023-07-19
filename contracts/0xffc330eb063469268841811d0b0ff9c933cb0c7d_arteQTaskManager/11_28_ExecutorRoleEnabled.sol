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

import "./AdminRoleEnabled.sol";

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
abstract contract ExecutorRoleEnabled is AdminRoleEnabled {

    mapping (address => bool) private _executors;

    uint internal _nrOfExecutors;

    event ExecutorAdded(address account);
    event ExecutorRemoved(address account);

    modifier onlyExecutor() {
        require(_isExecutor(msg.sender), "ExecutorRoleEnabled: not an executor account");
        _;
    }

    modifier mustBeExecutor(address account) {
        require(_isExecutor(account), "ExecutorRoleEnabled: not an executor account");
        _;
    }

    constructor() {
        _nrOfExecutors = 0;
    }

    function isExecutor(address account) external view
      onlyAdmin
      returns (bool)
    {
        return _isExecutor(account);
    }

    function addExecutor(uint256 adminTaskId, address account) external
      onlyAdmin
      taskMustExist(adminTaskId)
      taskMustBeAdministrative(adminTaskId)
      taskMustNotBeFinalized(adminTaskId)
      taskMustBeApproved(adminTaskId)
    {
        _addExecutor(account);
        _finalizeTask(adminTaskId, "");
    }

    function removeExecutor(uint256 adminTaskId, address account) external
      onlyAdmin
      taskMustExist(adminTaskId)
      taskMustBeAdministrative(adminTaskId)
      taskMustNotBeFinalized(adminTaskId)
      taskMustBeApproved(adminTaskId)
    {
        _removeExecutor(account);
        _finalizeTask(adminTaskId, "");
    }

    function _isExecutor(address account) internal view returns (bool) {
        return _executors[account];
    }

    function _addExecutor(address account) internal {
        require(account != address(0), "ExecutorRoleEnabled: zero account cannot be used");
        require(!_executors[account], "ExecutorRoleEnabled: already an executor account");
        _executors[account] = true;
        _nrOfExecutors += 1;
        emit ExecutorAdded(account);
    }

    function _removeExecutor(address account) internal {
        require(account != address(0), "ExecutorRoleEnabled: zero account cannot be used");
        require(_executors[account], "ExecutorRoleEnabled: not an executor account");
        _executors[account] = false;
        _nrOfExecutors -= 1;
        emit ExecutorRemoved(account);
    }
}