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

import "./TaskManaged.sol";

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
abstract contract AdminRoleEnabled is TaskManaged {

    uint public constant MAX_NR_OF_ADMINS = 10;
    uint public constant MIN_NR_OF_ADMINS = 4;

    mapping (address => bool) private _admins;
    uint internal _nrOfAdmins;

    event AdminAdded(address account);
    event AdminRemoved(address account);

    modifier onlyAdmin() {
        require(_isAdmin(msg.sender), "AdminRoleEnabled: not an admin account");
        _;
    }

    constructor() {
        _nrOfAdmins = 0;
    }

    function isAdmin(address account) external view
      onlyAdmin
      returns (bool)
    {
        return _isAdmin(account);
    }

    function getNrAdmins() external view
      onlyAdmin
      returns (uint)
    {
        return _nrOfAdmins;
    }

    function addAdmin(uint256 adminTaskId, address toBeAdded) external
      onlyAdmin
      taskMustExist(adminTaskId)
      taskMustBeAdministrative(adminTaskId)
      taskMustNotBeFinalized(adminTaskId)
      taskMustBeApproved(adminTaskId)
    {
        _addAdmin(toBeAdded);
        _finalizeTask(adminTaskId, "");
    }

    function replaceAdmin(uint256 adminTaskId, address toBeRemoved, address toBeReplaced) external
      onlyAdmin
      taskMustExist(adminTaskId)
      taskMustBeAdministrative(adminTaskId)
      taskMustNotBeFinalized(adminTaskId)
      taskMustBeApproved(adminTaskId)
    {
        if (_nrOfAdmins == MAX_NR_OF_ADMINS) {
            _removeAdmin(toBeRemoved);
            _addAdmin(toBeReplaced);
        } else {
            _addAdmin(toBeReplaced);
            _removeAdmin(toBeRemoved);
        }
        _finalizeTask(adminTaskId, "");
    }

    function removeAdmin(uint256 adminTaskId, address toBeRemoved) external
      onlyAdmin
      taskMustExist(adminTaskId)
      taskMustBeAdministrative(adminTaskId)
      taskMustNotBeFinalized(adminTaskId)
      taskMustBeApproved(adminTaskId)
    {
        _removeAdmin(toBeRemoved);
        _finalizeTask(adminTaskId, "");
    }

    function _isAdmin(address account) internal view returns (bool) {
        return _admins[account];
    }

    function _addAdmin(address account) internal {
        require(account != address(0), "AdminRoleEnabled: zero account cannot be used");
        require(!_admins[account], "AdminRoleEnabled: already an admin account");
        require((_nrOfAdmins + 1) <= MAX_NR_OF_ADMINS, "AdminRoleEnabled: exceeds maximum number of admin accounts");
        _admins[account] = true;
        _nrOfAdmins += 1;
        emit AdminAdded(account);
    }

    function _removeAdmin(address account) internal {
        require(account != address(0), "AdminRoleEnabled: zero account cannot be used");
        require(_admins[account], "AdminRoleEnabled: not an admin account");
        require((_nrOfAdmins - 1) >= MIN_NR_OF_ADMINS,
                "AdminRoleEnabled: goes below minimum number of admin accounts");
        _admins[account] = false;
        _nrOfAdmins -= 1;
        emit AdminRemoved(account);
    }
}