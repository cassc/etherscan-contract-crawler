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

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "../DiamondHelper.sol";
import "../registrar/IRegistrar.sol";
import "../deed-registry/IDeedRegistry.sol";
import "../catalog/ICatalog.sol";
import "./RegistrarFactoryStorage.sol";

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
library RegistrarFactoryInternal {

    event RegistrarCreate(
        address indexed registrar
    );

    function _getContractKeys() internal view returns (string[] memory) {
        return __s().contractKeys;
    }

    function _getContract(string memory key) internal view returns (address) {
        return __getContract(key);
    }

    function _setContract(string memory key, address facet) internal {
        __addContractKey(key);
        __s().contracts[key] = facet;
    }

    function _getRegistrars() internal view returns (address[] memory) {
        return __s().registrars;
    }

    function _createRegistrar(
        address taskManager,
        address authzSource,
        string memory registrarName,
        string memory registrarURI,
        string memory deedRegistryName,
        string memory deedRegistrySymbol
    ) internal {
        // deploy the registrar contract
        address registrar = __createRegistrar(
            taskManager, authzSource, registrarName);
        // deploy the deed-registry contract
        address deedRegistry = __createDeedRegistry(
            taskManager, authzSource, registrarName);
        // deploy the catalog contract
        address catalog = __createCatalog(
            taskManager, authzSource, registrarName);
        // initialize the registrar contract
        IRegistrar(registrar).initializeRegistrar(
            deedRegistry,
            catalog,
            registrarName,
            registrarURI,
            taskManager,
            authzSource
        );
        // initialize the deed-registry contract
        IDeedRegistry(deedRegistry).initializeDeedRegistry(
            registrar, catalog, deedRegistryName, deedRegistrySymbol);
        // initialize the catalog contract
        ICatalog(catalog).initializeCatalog(
            registrar, deedRegistry);
        __s().registrars.push(registrar);
        emit RegistrarCreate(registrar);
    }

    function __addContractKey(string memory key) private {
        if (__s().contractKeysIndex[key] == 0) {
            __s().contractKeys.push(key);
            __s().contractKeysIndex[key] = __s().contractKeys.length;
        }
    }

    function __getContract(string memory key) private view returns (address) {
        address c = __s().contracts[key];
        require(c != address(0), string(abi.encodePacked("RFI:ZA-", key)));
        return c;
    }

    function __createRegistrar(
        address taskManager,
        address authzSource,
        string memory registrarName
    ) private returns (address) {
        return DiamondHelper._createDiamond(
            __getContract("diamond-factory"),
            taskManager,
            authzSource,
            string(abi.encodePacked(registrarName, "-registrar")),
            DiamondHelper._singleItemAddressArray(__getContract("registrar-facet"))
        );
    }

    function __createDeedRegistry(
        address taskManager,
        address authzSource,
        string memory registrarName
    ) private returns (address) {
        return DiamondHelper._createDiamond(
            __getContract("diamond-factory"),
            taskManager,
            authzSource,
            string(abi.encodePacked(registrarName, "-deed-registry")),
            DiamondHelper._singleItemAddressArray(__getContract("deed-registry-facet"))
        );
    }

    function __createCatalog(
        address taskManager,
        address authzSource,
        string memory registrarName
    ) private returns (address) {
        return DiamondHelper._createDiamond(
            __getContract("diamond-factory"),
            taskManager,
            authzSource,
            string(abi.encodePacked(registrarName, "-catalog")),
            DiamondHelper._singleItemAddressArray(__getContract("catalog-facet"))
        );
    }

    function __s() private pure returns (RegistrarFactoryStorage.Layout storage) {
        return RegistrarFactoryStorage.layout();
    }
}