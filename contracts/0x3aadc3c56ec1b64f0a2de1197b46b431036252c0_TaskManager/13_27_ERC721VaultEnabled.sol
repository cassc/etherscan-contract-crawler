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

import "../ERC721Vault.sol";
import "./AdminRoleEnabled.sol";

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
abstract contract ERC721VaultEnabled is AdminRoleEnabled, ERC721Vault {

    /* solhint-disable func-name-mixedcase */
    function ERC721Transfer(
        uint256 adminTaskId,
        address tokenContract,
        address to,
        uint256 tokenId
    ) external
      onlyAdmin
      taskMustExist(adminTaskId)
      taskMustBeAdministrative(adminTaskId)
      taskMustNotBeFinalized(adminTaskId)
      taskMustBeApproved(adminTaskId)
    {
        _ERC721Transfer(tokenContract, to, tokenId);
        _finalizeTask(adminTaskId, "");
    }

    function ERC721Approve(
        uint256 adminTaskId,
        address tokenContract,
        address operator,
        uint256 tokenId
    ) external
      onlyAdmin
      taskMustExist(adminTaskId)
      taskMustBeAdministrative(adminTaskId)
      taskMustNotBeFinalized(adminTaskId)
      taskMustBeApproved(adminTaskId)
    {
        _ERC721Approve(tokenContract, operator, tokenId);
        _finalizeTask(adminTaskId, "");
    }

    function ERC721SetApprovalForAll(
        uint256 adminTaskId,
        address tokenContract,
        address operator,
        bool approved
    ) external
      onlyAdmin
      taskMustExist(adminTaskId)
      taskMustBeAdministrative(adminTaskId)
      taskMustNotBeFinalized(adminTaskId)
      taskMustBeApproved(adminTaskId)
    {
        _ERC721SetApprovalForAll(tokenContract, operator, approved);
        _finalizeTask(adminTaskId, "");
    }
}