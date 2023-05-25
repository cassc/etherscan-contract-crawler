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

import "../ERC721Vault.sol";
import "./TaskExecutor.sol";

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
abstract contract TaskManagedERC721VaultEnabled is TaskExecutor, ERC721Vault {

    function ERC721Transfer(
        uint256 taskId,
        address tokenContract,
        address to,
        uint256 tokenId
    ) external
      tryExecuteTaskAfterwards(taskId)
    {
        _ERC721Transfer(tokenContract, to, tokenId);
    }

    function ERC721Approve(
        uint256 taskId,
        address tokenContract,
        address operator,
        uint256 tokenId
    ) external
      tryExecuteTaskAfterwards(taskId)
    {
        _ERC721Approve(tokenContract, operator, tokenId);
    }

    function ERC721SetApprovalForAll(
        uint256 taskId,
        address tokenContract,
        address operator,
        bool approved
    ) external
      tryExecuteTaskAfterwards(taskId)
    {
        _ERC721SetApprovalForAll(tokenContract, operator, approved);
    }
}