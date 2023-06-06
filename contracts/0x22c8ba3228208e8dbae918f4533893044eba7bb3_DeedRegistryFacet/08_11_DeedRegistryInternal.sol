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

import "./DeedRegistryStorage.sol";

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
library DeedRegistryInternal {

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    function _initialize(
        address registrar,
        address catalog,
        string memory name,
        string memory symbol
    ) internal {
        require(!__s().initialized, "DRI:AI");
        __s().registrar = registrar;
        __s().catalog = catalog;
        __s().name = name;
        __s().symbol = symbol;
        __s().initialized = true;
    }

    function _getRegistrar() internal view returns (address) {
        return __s().registrar;
    }

    function _getCatalog() internal view returns (address) {
        return __s().catalog;
    }

    function _getNrOfDeeds() internal view returns (uint256) {
        return __s().lastRegistereeId;
    }

    function _getName() internal view returns (string memory) {
        return __s().name;
    }

    function _setName(string memory name) internal {
        __s().name = name;
    }

    function _getSymbol() internal view returns (string memory) {
        return __s().symbol;
    }

    function _setSymbol(string memory symbol) internal {
        __s().symbol = symbol;
    }

    function _balanceOf(address owner) internal view returns (uint256) {
        if (owner != __s().registrar) {
            return 0;
        }
        return __s().lastRegistereeId;
    }

    function _exists(uint256 registereeId) internal view returns (bool) {
        return registereeId > 0 && registereeId <= __s().lastRegistereeId;
    }

    function _ownerOf(uint256 registereeId) internal view returns (address) {
        require(_exists(registereeId), "DRI:TNF");
        return __s().registrar;
    }

    function _getDeedURI(uint256 registereeId) internal view returns (string memory) {
        require(_exists(registereeId), "DRI:TNF");
        return __s().deeds[registereeId].uri;
    }

    function _setDeedURI(uint256 registereeId, string memory deedURI) internal {
        require(_exists(registereeId), "DRI:TNF");
        __s().deeds[registereeId].uri = deedURI;
    }

    function _getDeedAnnexes(uint256 registereeId) internal view returns (string[] memory) {
        require(_exists(registereeId), "DRI:TNF");
        return __s().deeds[registereeId].annexes;
    }

    function _addDeedAnnex(uint256 registereeId, string memory annexURI) internal {
        require(_exists(registereeId), "DRI:TNF");
        __s().deeds[registereeId].annexes.push(annexURI);
    }

    function _setDeedAnnex(
        uint256 registereeId,
        uint256 index,
        string memory annexURI
    ) internal {
        require(_exists(registereeId), "DRI:TNF");
        require(index < __s().deeds[registereeId].annexes.length, "DRI:IINX");
        __s().deeds[registereeId].annexes[index] = annexURI;
    }

    function _mintDeed(
        uint256 registereeId,
        string memory deedURI
    ) internal {
        require(__s().initialized, "DRI:NI");
        require(msg.sender == __s().registrar, "DRI:ACCDEN");
        require(__s().deeds[registereeId].registereeId == 0, "DRI:ET");
        __s().deeds[registereeId].registereeId = registereeId;
        __s().deeds[registereeId].uri = deedURI;
        __s().lastRegistereeId = registereeId;
        emit Transfer(address(0), __s().registrar, registereeId);
    }

    function __s() private pure returns (DeedRegistryStorage.Layout storage) {
        return DeedRegistryStorage.layout();
    }
}