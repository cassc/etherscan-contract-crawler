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
import "./RegistrarFactoryInternal.sol";

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
contract RegistrarFactoryFacet is IDiamondFacet {

    function getFacetName()
      external pure override returns (string memory) {
        return "registrar-factory";
    }

    // CAUTION: Don't forget to update the version when adding new functionality
    function getFacetVersion()
      external pure override returns (string memory) {
        return "2.0.0";
    }

    function getFacetPI()
      external pure override returns (string[] memory) {
        string[] memory pi = new string[](5);
        pi[ 0] = "getContractKeys()";
        pi[ 1] = "getContract(string)";
        pi[ 2] = "setContract(string,address)";
        pi[ 3] = "getRegistrars()";
        pi[ 4] = "createRegistrar(address,address,string,string,string,string)";
        return pi;
    }

    function getFacetProtectedPI()
      external pure override returns (string[] memory) {
        string[] memory pi = new string[](2);
        pi[ 0] = "setContract(string,address)";
        pi[ 1] = "createRegistrar(address,address,string,string,string,string)";
        return pi;
    }

    function supportsInterface(bytes4 interfaceId)
      external pure override returns (bool) {
        return interfaceId == type(IDiamondFacet).interfaceId;
    }

    function getContractKeys() external view returns (string[] memory) {
        return RegistrarFactoryInternal._getContractKeys();
    }

    function getContract(string memory key) external view returns (address) {
        return RegistrarFactoryInternal._getContract(key);
    }

    function setContract(string memory key, address contractAddr) external {
        RegistrarFactoryInternal._setContract(key, contractAddr);
    }

    function getRegistrars() external view returns (address[] memory) {
        return RegistrarFactoryInternal._getRegistrars();
    }

    function createRegistrar(
        address taskManager,
        address authzSource,
        string memory registrarName,
        string memory registrarURI,
        string memory deedRegistryName,
        string memory deedRegistrySymbol
    ) external {
        RegistrarFactoryInternal._createRegistrar(
            taskManager,
            authzSource,
            registrarName,
            registrarURI,
            deedRegistryName,
            deedRegistrySymbol
        );
    }
}