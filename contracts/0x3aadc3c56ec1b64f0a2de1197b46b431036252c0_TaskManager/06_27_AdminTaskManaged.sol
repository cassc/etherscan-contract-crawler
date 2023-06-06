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

import "./AdminRoleEnabled.sol";

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
abstract contract AdminTaskManaged is AdminRoleEnabled {

    function createAdminTask(string memory taskURI) external
      onlyAdmin
    {
        _createTask(taskURI, true);
    }

    function approveAdminTask(uint256 adminTaskId) external
      onlyAdmin
      taskMustExist(adminTaskId)
      taskMustBeAdministrative(adminTaskId)
      taskMustNotBeFinalized(adminTaskId)
    {
        _approveTask(msg.sender, adminTaskId);
    }

    function withdrawAdminTaskApproval(uint256 adminTaskId) external
      onlyAdmin
      taskMustExist(adminTaskId)
      taskMustBeAdministrative(adminTaskId)
      taskMustNotBeFinalized(adminTaskId)
    {
        _withdrawTaskApproval(msg.sender, adminTaskId);
    }

    function finalizeAdminTask(uint256 adminTaskId, string memory reason) external
      onlyAdmin
      taskMustExist(adminTaskId)
      taskMustBeAdministrative(adminTaskId)
      taskMustNotBeFinalized(adminTaskId)
    {
        _finalizeTask(adminTaskId, reason);
    }

    function _getRequiredNrApprovals(uint256 taskId)
      internal view virtual override (TaskManaged) returns (uint) {
        require(_taskExists(taskId), "ATM: non-exsiting task");
        return (1 + _nrOfAdmins / 2);
    }
}