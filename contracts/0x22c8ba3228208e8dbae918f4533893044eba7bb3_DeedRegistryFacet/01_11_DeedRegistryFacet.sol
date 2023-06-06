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

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "../../../diamond/IDiamondFactory.sol";
import "../../../diamond/IDiamondFacet.sol";
import "./IDeedRegistry.sol";
import "./DeedRegistryInternal.sol";

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
contract DeedRegistryFacet is IDiamondFacet, IDeedRegistry {

    function getFacetName()
      external pure override returns (string memory) {
        return "deed-registry";
    }

    // CAUTION: Don't forget to update the version when adding new functionality
    function getFacetVersion()
      external pure override returns (string memory) {
        return "1.1.0";
    }

    function getFacetPI()
      external pure override returns (string[] memory) {
        string[] memory pi = new string[](16);
        pi[ 0] = "initializeDeedRegistry(address,address,string,string)";
        pi[ 1] = "balanceOf(address)";
        pi[ 2] = "ownerOf(uint256)";
        pi[ 3] = "getRegistrar()";
        pi[ 4] = "getCatalog()";
        pi[ 5] = "getNrOfDeeds()";
        pi[ 6] = "name()";
        pi[ 7] = "setName(string)";
        pi[ 8] = "symbol()";
        pi[ 9] = "setSymbol(string)";
        pi[10] = "tokenURI(uint256)";
        pi[11] = "setDeedURI(uint256,string)";
        pi[12] = "getDeedAnnexes(uint256)";
        pi[13] = "addDeedAnnex(uint256,string)";
        pi[14] = "setDeedAnnex(uint256,uint256,string)";
        pi[15] = "mintDeed(uint256,string)";
        return pi;
    }

    function getFacetProtectedPI()
      external pure override returns (string[] memory) {
        string[] memory pi = new string[](5);
        pi[ 0] = "setName(string)";
        pi[ 1] = "setSymbol(string)";
        pi[ 2] = "setDeedURI(uint256,string)";
        pi[ 3] = "addDeedAnnex(uint256,string)";
        pi[ 4] = "setDeedAnnex(uint256,uint256,string)";
        return pi;
    }

    function supportsInterface(bytes4 interfaceId)
      external pure override returns (bool) {
        return
            interfaceId == type(IDiamondFacet).interfaceId ||
            interfaceId == type(IDeedRegistry).interfaceId ||
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId;
    }

    function initializeDeedRegistry(
        address registrar,
        address catalog,
        string memory name_,
        string memory symbol_
    ) external override {
        DeedRegistryInternal._initialize(registrar, catalog, name_, symbol_);
    }

    function balanceOf(address owner) external view returns (uint256) {
        return DeedRegistryInternal._balanceOf(owner);
    }

    function ownerOf(uint256 tokenId) external view returns (address) {
        return DeedRegistryInternal._ownerOf(tokenId);
    }

    function getRegistrar() external view returns (address) {
        return DeedRegistryInternal._getRegistrar();
    }

    function getCatalog() external view returns (address) {
        return DeedRegistryInternal._getCatalog();
    }

    function getNrOfDeeds() external view returns (uint256) {
        return DeedRegistryInternal._getNrOfDeeds();
    }

    function name() external view returns (string memory) {
        return DeedRegistryInternal._getName();
    }

    function setName(string memory name_) external {
        DeedRegistryInternal._setName(name_);
    }

    function symbol() external view returns (string memory) {
        return DeedRegistryInternal._getSymbol();
    }

    function setSymbol(string memory symbol_) external {
        DeedRegistryInternal._setSymbol(symbol_);
    }

    function tokenURI(uint256 registereeId) external view returns (string memory) {
        return DeedRegistryInternal._getDeedURI(registereeId);
    }

    function setDeedURI(uint256 registereeId, string memory deedURI) external {
        DeedRegistryInternal._setDeedURI(registereeId, deedURI);
    }

    function getDeedAnnexes(uint256 registereeId) external view returns (string[] memory) {
        return DeedRegistryInternal._getDeedAnnexes(registereeId);
    }

    function addDeedAnnex(uint256 registereeId, string memory annexURI) external {
        DeedRegistryInternal._addDeedAnnex(registereeId, annexURI);
    }

    function setDeedAnnex(
        uint256 registereeId,
        uint256 index,
        string memory annexURI
    ) external {
        DeedRegistryInternal._setDeedAnnex(registereeId, index, annexURI);
    }

    function mintDeed(
        uint256 registereeId,
        string memory deedURI
    ) external override {
        DeedRegistryInternal._mintDeed(registereeId, deedURI);
    }
}