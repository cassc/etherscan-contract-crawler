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

import "@openzeppelin/contracts/interfaces/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
abstract contract ERC1155Vault is IERC1155Receiver {

    event ERC1155Transferred(address tokenContract, address to, uint256 tokenId, uint256 amount);
    event ERC1155ApprovedForAll(address tokenContract, address operator, bool approved);

    function supportsInterface(bytes4 interfaceId) external view virtual override returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId;
    }

    function onERC1155Received(
        address /* operator */,
        address /* from */,
        uint256 /* id */,
        uint256 /* value */,
        bytes calldata /* data */
    ) external pure override returns (bytes4) {
        return bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"));
    }

    function onERC1155BatchReceived(
        address /* operator */,
        address /* from */,
        uint256[] calldata /* ids */,
        uint256[] calldata /* values */,
        bytes calldata /* data */
    ) external pure override returns (bytes4) {
        return bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"));
    }

    function _ERC1155Transfer(
        address tokenContract,
        address to,
        uint256 tokenId,
        uint256 amount
    ) internal {
        require(tokenContract != address(0), "ERC1155Vault: zero token address");
        require(to != address(0), "ERC1155Vault: cannot transfer to zero");

        IERC1155(tokenContract).safeTransferFrom(address(this), to, tokenId, amount, "");
        emit ERC1155Transferred(tokenContract, to, tokenId, amount);
    }

    function _ERC1155SetApprovalForAll(
        address tokenContract,
        address operator,
        bool approved
    ) internal {
        require(tokenContract != address(0), "ERC1155Vault: zero token address");
        require(operator != address(0), "ERC1155Vault: zero address for operator");

        IERC1155(tokenContract).setApprovalForAll(operator, approved);
        emit ERC1155ApprovedForAll(tokenContract, operator, approved);
    }
}