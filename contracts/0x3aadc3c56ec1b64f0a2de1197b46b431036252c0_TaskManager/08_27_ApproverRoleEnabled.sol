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
abstract contract ApproverRoleEnabled is AdminRoleEnabled {

    mapping (address => bool) private _approvers;

    uint internal _nrOfApprovers;

    event ApproverAdded(address account);
    event ApproverRemoved(address account);

    modifier onlyApprover() {
        require(_isApprover(msg.sender), "ApRE: not approver");
        _;
    }

    constructor() {
        _nrOfApprovers = 0;
    }

    function isApprover(address account) external view
      onlyAdmin
      returns (bool)
    {
        return _isApprover(account);
    }

    function addApprover(uint256 adminTaskId, address account) external
      onlyAdmin
      taskMustExist(adminTaskId)
      taskMustBeAdministrative(adminTaskId)
      taskMustNotBeFinalized(adminTaskId)
      taskMustBeApproved(adminTaskId)
    {
        _addApprover(account);
        _finalizeTask(adminTaskId, "");
    }

    function removeApprover(uint256 adminTaskId, address account) external
      onlyAdmin
      taskMustExist(adminTaskId)
      taskMustBeAdministrative(adminTaskId)
      taskMustNotBeFinalized(adminTaskId)
      taskMustBeApproved(adminTaskId)
    {
        _removeApprover(account);
        _finalizeTask(adminTaskId, "");
    }

    function _isApprover(address account) internal view returns (bool) {
        return _approvers[account];
    }

    function _addApprover(address account) internal {
        require(account != address(0), "ApRE: zero account");
        require(!_approvers[account], "ApRE: is approver");
        _approvers[account] = true;
        _nrOfApprovers += 1;
        emit ApproverAdded(account);
    }

    function _removeApprover(address account) internal {
        require(account != address(0), "ApRE: zero account");
        require(_approvers[account], "ApRE: not approver");
        _approvers[account] = false;
        _nrOfApprovers -= 1;
        emit ApproverRemoved(account);
    }
}