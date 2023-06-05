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

import "@openzeppelin/contracts/token/ERC1155/extensions/IERC1155MetadataURI.sol";
import "../../../diamond/IDiamondFacet.sol";
import "./ICatalog.sol";
import "./CatalogInternal.sol";

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
contract CatalogFacet is IDiamondFacet, IERC1155MetadataURI, ICatalog {

    function getFacetName()
      external pure override returns (string memory) {
        return "catalog";
    }

    // CAUTION: Don't forget to update the version when adding new functionality
    function getFacetVersion()
      external pure override returns (string memory) {
        return "1.4.1";
    }

    function getFacetPI()
      external pure override returns (string[] memory) {
        string[] memory pi = new string[](13);
        pi[ 0] = "initializeCatalog(address,address)";
        pi[ 1] = "getRegistrar()";
        pi[ 2] = "getDeedRegistry()";
        pi[ 3] = "addDeed(uint256,address,address)";
        pi[ 4] = "submitTransfer(uint256,address,address,uint256)";
        pi[ 5] = "balanceOf(address,uint256)";
        pi[ 6] = "balanceOfBatch(address[],uint256[])";
        pi[ 7] = "setApprovalForAll(address,bool)";
        pi[ 8] = "isApprovedForAll(address,address)";
        pi[ 9] = "safeTransferFrom(address,address,uint256,uint256,bytes)";
        pi[10] = "safeBatchTransferFrom(address,address,uint256[],uint256[],bytes)";
        pi[11] = "uri(uint256)";
        pi[12] = "xMint(address,address,uint256,uint256)";
        return pi;
    }

    function getFacetProtectedPI()
      external pure override returns (string[] memory) {
        string[] memory pi = new string[](0);
        return pi;
    }

    function supportsInterface(bytes4 interfaceId)
      external pure override returns (bool) {
        return
            interfaceId == type(IDiamondFacet).interfaceId ||
            interfaceId == type(ICatalog).interfaceId ||
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId;
    }

    function initializeCatalog(
        address registrar,
        address deedRegistry
    ) external override {
        CatalogInternal._initialize(registrar, deedRegistry);

    }

    function getRegistrar() external view returns (address) {
        return CatalogInternal._getRegistrar();
    }

    function getDeedRegistry() external view returns (address) {
        return CatalogInternal._getDeedRegistry();
    }

    function addDeed(
        uint256 registereeId,
        address grantToken,
        address council
    ) external override {
        CatalogInternal._addDeed(registereeId, grantToken, council);
    }

    function submitTransfer(
        uint256 registereeId,
        address from,
        address to,
        uint256 amount
    ) external override {
        address caller = msg.sender;
        CatalogInternal._submitTransfer(
            caller, registereeId, from, to, amount);
    }

    function balanceOf(
        address account,
        uint256 registereeId
    ) external view override returns (uint256) {
        return CatalogInternal._balanceOf(account, registereeId);
    }

    function balanceOfBatch(
        address[] calldata accounts,
        uint256[] calldata registereeIds
    ) external view override returns (uint256[] memory) {
        return CatalogInternal._balanceOfBatch(accounts, registereeIds);
    }

    function setApprovalForAll(
        address operator,
        bool approved
    ) external override {
        CatalogInternal._setApprovalForAll(operator, approved);
    }

    function isApprovedForAll(
        address account,
        address operator
    ) external view override returns (bool) {
        return CatalogInternal._isApprovedForAll(account, operator);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 registereeId,
        uint256 amount,
        bytes calldata data
    ) external override {
        CatalogInternal._safeTransferFrom(
            from, to, registereeId, amount, data);
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata registereeIds,
        uint256[] calldata amounts,
        bytes calldata data
    ) external pure override {
        CatalogInternal._safeBatchTransferFrom(
            from, to, registereeIds, amounts, data);
    }

    function uri(uint256 registereeId)
    external view override returns (string memory) {
        return CatalogInternal._uri(registereeId);
    }

    function xMint(
        address to,
        address origTo,
        uint256 registereeId,
        uint256 nrOfTokens
    ) external payable {
        CatalogInternal._xMint(origTo, registereeId, nrOfTokens);
    }
}