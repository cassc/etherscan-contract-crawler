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

import "../ERC20Vault.sol";
import "./AdminRoleEnabled.sol";

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
abstract contract ERC20VaultEnabled is AdminRoleEnabled, ERC20Vault {

    function ERC20Transfer(
        uint256 adminTaskId,
        address tokenContract,
        address to,
        uint256 amount
    ) external
      onlyAdmin
      taskMustExist(adminTaskId)
      taskMustBeAdministrative(adminTaskId)
      taskMustNotBeFinalized(adminTaskId)
      taskMustBeApproved(adminTaskId)
    {
        _ERC20Transfer(tokenContract, to, amount);
        _finalizeTask(adminTaskId, "");
    }

    function ERC20Approve(
        uint256 adminTaskId,
        address tokenContract,
        address spender,
        uint256 amount
    ) external
      onlyAdmin
      taskMustExist(adminTaskId)
      taskMustBeAdministrative(adminTaskId)
      taskMustNotBeFinalized(adminTaskId)
      taskMustBeApproved(adminTaskId)
    {
        _ERC20Approve(tokenContract, spender, amount);
        _finalizeTask(adminTaskId, "");
    }
}