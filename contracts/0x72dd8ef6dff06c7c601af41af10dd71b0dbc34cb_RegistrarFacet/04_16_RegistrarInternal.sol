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

import "../DiamondHelper.sol";
import "../deed-registry/IDeedRegistry.sol";
import "../catalog/ICatalog.sol";
import "../grant-token/IGrantTokenInitializer.sol";
import "../council/ICouncil.sol";
import "../board/IBoard.sol";
import "../fiat-handler/IFiatHandler.sol";
import "./RegistrarStorage.sol";

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
library RegistrarInternal {

    // TODO(kam): deploy treasury and trader

    event Registration(
        uint256 indexed registereeId
    );
    event RegistereeUpdate(
        uint256 indexed registereeId
    );
    event RegistrarUpdate();

    function _initialize(
        address deedRegistry,
        address catalog,
        string memory registrarName,
        string memory registrarURI,
        address defaultTaskManager,
        address defaultAuthzSource
    ) internal {
        require(!__s().initialized, "RI:AI");
        __s().deedRegistry = deedRegistry;
        __s().catalog = catalog;
        __s().registrarName = registrarName;
        __s().registrarURI = registrarURI;
        _setContract("task-manager", defaultTaskManager);
        _setContract("authz-source", defaultAuthzSource);
        __s().initialized = true;
        emit RegistrarUpdate();
    }

    function _getDeedRegistry() internal view returns (address) {
        return __s().deedRegistry;
    }

    function _getCatalog() internal view returns (address) {
        return __s().catalog;
    }

    function _getRegistrarName() internal view returns (string memory) {
        return __s().registrarName;
    }

    function _setRegistrarName(string memory name) internal {
        __s().registrarName = name;
        emit RegistrarUpdate();
    }

    function _getRegistrarURI() internal view returns (string memory) {
        return __s().registrarURI;
    }

    function _setRegistrarURI(string memory uri) internal {
        __s().registrarURI = uri;
        emit RegistrarUpdate();
    }

    function _getContractKeys() internal view returns (string[] memory) {
        return __s().contractKeys;
    }

    function _getContract(string memory key) internal view returns (address) {
        return __getContract(key);
    }

    function _setContract(string memory key, address contractAddr) internal {
        __addContractKey(key);
        __s().contracts[key] = contractAddr;
    }

    function _getNrOfRegisterees() internal view returns (uint256) {
        return __s().registereeIdCounter;
    }

    function _getRegistereeInfo(
        uint256 registereeId
    ) internal view returns (
        string memory, // name of the registeree
        address, // address of the GrantToken contract
        address, // address of the Council contract
        string[] memory // tags attached to this instance of registeree
    ) {
        require(registereeId > 0 && registereeId <= __s().registereeIdCounter, "RI:RNF");
        RegistrarStorage.Registeree storage registeree = __s().registerees[registereeId];
        return (
            registeree.name,
            registeree.grantToken,
            registeree.council,
            registeree.tags
        );
    }

    function _setRegistereeName(
        uint256 registereeId,
        string memory name
    ) internal {
        require(registereeId > 0 && registereeId <= __s().registereeIdCounter, "RI:RNF");
        RegistrarStorage.Registeree storage registeree = __s().registerees[registereeId];
        registeree.name = name;
        emit RegistereeUpdate(registereeId);
    }

    function _setRegistereeTags(
        uint256 registereeId,
        string[] memory tags
    ) internal {
        require(registereeId > 0 && registereeId <= __s().registereeIdCounter, "RI:RNF");
        RegistrarStorage.Registeree storage registeree = __s().registerees[registereeId];
        registeree.tags = tags;
        emit RegistereeUpdate(registereeId);
    }

    struct RegisterParams {
        string name;
        string deedURI;
        string grantTokenName;
        string grantTokenSymbol;
        uint256 nrOfGrantTokens;
        address feeCollectionAccount;
        address icoCollectionAccount;
        address[][4] councilBodies;
        uint256[4] pricesMicroUSD;
        address[3] payAddresses;
        uint256 maxNegativeSlippage;
    }
    function _register(
        RegisterParams memory params
    ) internal {
        require(__s().initialized, "RI:NI");
        require(params.councilBodies[0].length >= 3, "RI:NEA");
        require(params.councilBodies[1].length >= 1, "RI:NEC");
        require(params.councilBodies[2].length >= 1, "RI:NEE");
        uint256 registereeId = __s().registereeIdCounter + 1;
        __s().registereeIdCounter += 1;
        RegistrarStorage.Registeree storage registeree = __s().registerees[registereeId];
        registeree.name = params.name;
        // deploy the contracts
        registeree.grantToken = __createGrantToken(params.name);
        registeree.council = __createCouncil(params.name);
        // initialize the grant token contract
        IGrantTokenInitializer(registeree.grantToken).initializeGrantToken(
            registereeId,
            registeree.council,
            params.feeCollectionAccount,
            params.grantTokenName,
            params.grantTokenSymbol,
            params.nrOfGrantTokens
        );
        // initialize the council contract
        IBoard(registeree.council).initializeBoard(
            params.councilBodies[0], // admins
            params.councilBodies[1], // creators
            params.councilBodies[2], // executors
            params.councilBodies[3]  // finalizers
        );
        ICouncil(registeree.council).initializeCouncil(
            registereeId,
            registeree.grantToken,
            params.feeCollectionAccount,
            params.icoCollectionAccount,
            params.pricesMicroUSD[0], // proposal creation fee
            params.pricesMicroUSD[1], // admin proposal creation fee
            params.pricesMicroUSD[2], // ico price
            params.pricesMicroUSD[3]  // ico fee
        );
        IFiatHandler(registeree.grantToken).initializeFiatHandler(
            params.payAddresses[0],
            params.payAddresses[1],
            params.payAddresses[2],
            params.maxNegativeSlippage
        );
        IFiatHandler(registeree.council).initializeFiatHandler(
            params.payAddresses[0], // uniswap-v2 factory contract
            params.payAddresses[1], // WETH ERC-20 contract
            params.payAddresses[2], // microUSD (USDT for example) ERC-20 contract
            params.maxNegativeSlippage
        );
        // mint the Deed NFT
        IDeedRegistry(__s().deedRegistry).mintDeed(registereeId, params.deedURI);
        // add new entry in catalog
        ICatalog(__s().catalog).addDeed(
            registereeId, registeree.grantToken, registeree.council);
        emit Registration(registereeId);
        emit RegistereeUpdate(registereeId);
    }

    function __addContractKey(string memory key) private {
        if (__s().contractKeysIndex[key] == 0) {
            __s().contractKeys.push(key);
            __s().contractKeysIndex[key] = __s().contractKeys.length;
        }
    }

    function __getContract(string memory key) private view returns (address) {
        address c = __s().contracts[key];
        require(c != address(0), string(abi.encodePacked("RII:ZA-", key)));
        return c;
    }

    function __createGrantToken(
        string memory name
    ) private returns (address) {
        return DiamondHelper._createDiamond(
            __getContract("diamond-factory"),
            __getContract("task-manager"),
            __getContract("authz-source"),
            string(abi.encodePacked(name, "-grant-token")),
            DiamondHelper._threeItemsAddressArray(
                __getContract("grant-token-facet"),
                __getContract("fiat-handler-facet"),
                __getContract("rbac-facet")
            )
        );
    }

    function __createCouncil(
        string memory name
    ) private returns (address) {
        return DiamondHelper._createDiamond(
            __getContract("diamond-factory"),
            __getContract("task-manager"),
            __getContract("authz-source"),
            string(abi.encodePacked(name, "-council")),
            DiamondHelper._fiveItemsAddressArray(
                __getContract("board-facet"),
                __getContract("council-facet"),
                __getContract("council-pm-facet"),
                __getContract("fiat-handler-facet"),
                __getContract("rbac-facet")
            )
        );
    }

    function __s() private pure returns (RegistrarStorage.Layout storage) {
        return RegistrarStorage.layout();
    }
}