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

import "../ETHVault.sol";
import "./AdminRoleEnabled.sol";

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
abstract contract ETHVaultEnabled is AdminRoleEnabled, ETHVault {

    function isDepositEnabled() external view onlyAdmin returns (bool) {
        return _isDepositEnabled();
    }

    function setEnableDeposit(
        uint256 adminTaskId,
        bool enableDeposit
    ) external
      onlyAdmin
      taskMustExist(adminTaskId)
      taskMustBeAdministrative(adminTaskId)
      taskMustNotBeFinalized(adminTaskId)
      taskMustBeApproved(adminTaskId)
    {
        require(_isDepositEnabled() != enableDeposit, "ETHVaultEnabled: cannot set the same value");
        _setEnableDeposit(enableDeposit);
        _finalizeTask(adminTaskId, "");
    }

    function ETHTransfer(
        uint256 adminTaskId,
        address to,
        uint256 amount
    ) external
      onlyAdmin
      taskMustExist(adminTaskId)
      taskMustBeAdministrative(adminTaskId)
      taskMustNotBeFinalized(adminTaskId)
      taskMustBeApproved(adminTaskId)
    {
        _ETHTransfer(to, amount);
        _finalizeTask(adminTaskId, "");
    }
}