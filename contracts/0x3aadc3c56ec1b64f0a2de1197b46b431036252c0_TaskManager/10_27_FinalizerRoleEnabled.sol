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
abstract contract FinalizerRoleEnabled is AdminRoleEnabled {

    mapping (address => bool) private _finalizers;

    uint internal _nrOfFinalizers;

    event FinalizerAdded(address account);
    event FinalizerRemoved(address account);

    modifier onlyFinalizer() {
        require(_isFinalizer(msg.sender), "FinalizerRoleEnabled: not a finalizer account");
        _;
    }

    constructor() {
        _nrOfFinalizers = 0;
    }

    function isFinalizer(address account) external view
      onlyAdmin
      returns (bool)
    {
        return _isFinalizer(account);
    }

    function addFinalizer(uint256 adminTaskId, address account) external
      onlyAdmin
      taskMustExist(adminTaskId)
      taskMustBeAdministrative(adminTaskId)
      taskMustNotBeFinalized(adminTaskId)
      taskMustBeApproved(adminTaskId)
    {
        _addFinalizer(account);
        _finalizeTask(adminTaskId, "");
    }

    function removeFinalizer(uint256 adminTaskId, address account) external
      onlyAdmin
      taskMustExist(adminTaskId)
      taskMustBeAdministrative(adminTaskId)
      taskMustNotBeFinalized(adminTaskId)
      taskMustBeApproved(adminTaskId)
    {
        _removeFinalizer(account);
        _finalizeTask(adminTaskId, "");
    }

    function _isFinalizer(address account) internal view returns (bool) {
        return _finalizers[account];
    }

    function _addFinalizer(address account) internal {
        require(account != address(0), "FRE: zero account");
        require(!_finalizers[account], "FRE: is finalizer");
        _finalizers[account] = true;
        _nrOfFinalizers += 1;
        emit FinalizerAdded(account);
    }

    function _removeFinalizer(address account) internal {
        require(account != address(0), "FRE: zero account");
        require(_finalizers[account], "FRE: not finalizer");
        _finalizers[account] = false;
        _nrOfFinalizers -= 1;
        emit FinalizerRemoved(account);
    }
}