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

import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
abstract contract ERC721Vault is IERC721Receiver {

    event ERC721Transferred(address tokenContract, address to, uint256 tokenId);
    event ERC721Approved(address tokenContract, address to, uint256 tokenId);
    event ERC721ApprovedForAll(address tokenContract, address operator, bool approved);

    function onERC721Received(
        address /* operator */,
        address /* from */,
        uint256 /* tokenId */,
        bytes calldata /* data */
    ) external pure override returns (bytes4) {
        return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    }

    function _ERC721Transfer(
        address tokenContract,
        address to,
        uint256 tokenId
    ) internal {
        require(tokenContract != address(0), "ERC721Vault: zero token address");
        require(to != address(0), "ERC721Vault: cannot transfer to zero");

        IERC721(tokenContract).safeTransferFrom(address(this), to, tokenId, "");
        emit ERC721Transferred(tokenContract, to, tokenId);
    }

    // operator can be the zero address.
    function _ERC721Approve(
        address tokenContract,
        address operator,
        uint256 tokenId
    ) internal {
        require(tokenContract != address(0), "ERC721Vault: zero token address");

        IERC721(tokenContract).approve(operator, tokenId);
        emit ERC721Approved(tokenContract, operator, tokenId);
    }

    function _ERC721SetApprovalForAll(
        address tokenContract,
        address operator,
        bool approved
    ) internal {
        require(tokenContract != address(0), "ERC721Vault: zero token address");
        require(operator != address(0), "ERC721Vault: zero address for operator");

        IERC721(tokenContract).setApprovalForAll(operator, approved);
        emit ERC721ApprovedForAll(tokenContract, operator, approved);
    }
}