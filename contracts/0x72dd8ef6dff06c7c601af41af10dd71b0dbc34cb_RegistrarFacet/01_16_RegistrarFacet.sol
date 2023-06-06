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

import "../../../diamond/IDiamondFacet.sol";
import "./IRegistrar.sol";
import "./RegistrarInternal.sol";

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
contract RegistrarFacet is IDiamondFacet, IRegistrar {

    function getFacetName()
      external pure override returns (string memory) {
        return "registrar";
    }

    // CAUTION: Don't forget to update the version when adding new functionality
    function getFacetVersion()
      external pure override returns (string memory) {
        return "2.1.1";
    }

    function getFacetPI()
      external pure override returns (string[] memory) {
        string[] memory pi = new string[](15);
        pi[ 0] = "initializeRegistrar(address,address,string,string,address,address)";
        pi[ 1] = "getDeedRegistry()";
        pi[ 2] = "getCatalog()";
        pi[ 3] = "getRegistrarName()";
        pi[ 4] = "setRegistrarName(string)";
        pi[ 5] = "getRegistrarURI()";
        pi[ 6] = "setRegistrarURI(string)";
        pi[ 7] = "getContractKeys()";
        pi[ 8] = "getContract(string)";
        pi[ 9] = "setContract(string,address)";
        pi[10] = "getNrOfRegisterees()";
        pi[11] = "getRegistereeInfo(uint256)";
        pi[12] = "setRegistereeName(uitn256,string)";
        pi[13] = "setRegistereeTags(uitn256,string[])";
        pi[14] = "register(string,string,string,string,uint256,address,address,address[][4],uint256[4],address[3],uint256)";
        return pi;
    }

    function getFacetProtectedPI()
      external pure override returns (string[] memory) {
        string[] memory pi = new string[](6);
        pi[ 0] = "setRegistrarName(string)";
        pi[ 1] = "setRegistrarURI(string)";
        pi[ 2] = "setContract(string,address)";
        pi[ 3] = "setRegistereeName(uitn256,string)";
        pi[ 4] = "setRegistereeTags(uitn256,string[])";
        pi[ 5] = "register(string,string,string,string,uint256,address,address,address[][4],uint256[4],address[3],uint256)";
        return pi;
    }

    function supportsInterface(bytes4 interfaceId)
      external pure override returns (bool) {
        return
            interfaceId == type(IDiamondFacet).interfaceId ||
            interfaceId == type(ICatalog).interfaceId;
    }

    function initializeRegistrar(
        address deedRegistry,
        address catalog,
        string memory registrarName,
        string memory registrarURI,
        address defaultTaskManager,
        address defaultAuthzSource
    ) external override {
        RegistrarInternal._initialize(
            deedRegistry,
            catalog,
            registrarName,
            registrarURI,
            defaultTaskManager,
            defaultAuthzSource
        );
    }

    function getDeedRegistry() external view override returns (address) {
        return RegistrarInternal._getDeedRegistry();
    }

    function getCatalog() external view override returns (address) {
        return RegistrarInternal._getCatalog();
    }

    function getRegistrarName() external view returns (string memory) {
        return RegistrarInternal._getRegistrarName();
    }

    function setRegistrarName(string memory name) external {
        RegistrarInternal._setRegistrarName(name);
    }

    function getRegistrarURI() external view returns (string memory) {
        return RegistrarInternal._getRegistrarURI();
    }

    function setRegistrarURI(string memory uri) external {
        RegistrarInternal._setRegistrarURI(uri);
    }

    function getContractKeys() external view returns (string[] memory) {
        return RegistrarInternal._getContractKeys();
    }

    function getContract(string memory key) external view returns (address) {
        return RegistrarInternal._getContract(key);
    }

    function setContract(string memory key, address contractAddr) external {
        RegistrarInternal._setContract(key, contractAddr);
    }

    function getNrOfRegisterees() external view returns (uint256) {
        return RegistrarInternal._getNrOfRegisterees();
    }

    function getRegistereeInfo(
        uint256 registereeId
    ) external view returns (
        string memory, // name of the registeree
        address, // address of the GrantToken contract
        address, // address of the Council contract
        string[] memory // tags attached to this instance of registeree
    ) {
        return RegistrarInternal._getRegistereeInfo(registereeId);
    }

    function setRegistereeName(
        uint256 registereeId,
        string memory name
    ) external {
        RegistrarInternal._setRegistereeName(registereeId, name);
    }

    function setRegistereeTags(
        uint256 registereeId,
        string[] memory tags
    ) external {
        RegistrarInternal._setRegistereeTags(registereeId, tags);
    }

    function register(
        string memory name,
        string memory deedURI,
        string memory grantTokenName,
        string memory grantTokenSymbol,
        uint256 grantTokenTotalSupply,
        address feeCollectionAccount,
        address icoCollectionAccount,
        address[][4] memory councilBodies,
        uint256[4] memory pricesMicroUSD,
        address[3] memory payAddresses,
        uint256 maxNegativeSlippage
    ) external {
        RegistrarInternal._register(
            RegistrarInternal.RegisterParams(
                name,
                deedURI,
                grantTokenName,
                grantTokenSymbol,
                grantTokenTotalSupply,
                feeCollectionAccount,
                icoCollectionAccount,
                councilBodies,
                pricesMicroUSD,
                payAddresses,
                maxNegativeSlippage
            )
        );
    }
}