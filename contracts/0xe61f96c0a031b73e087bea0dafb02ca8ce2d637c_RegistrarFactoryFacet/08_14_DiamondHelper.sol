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

import "../../diamond/IDiamondFactory.sol";
import "../../diamond/IDiamondInitializer.sol";

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
library DiamondHelper {

    function _singleItemAddressArray(address addr) internal pure returns (address[] memory) {
        address[] memory arr = new address[](1);
        arr[0] = addr;
        return arr;
    }

    function _twoItemsAddressArray(
        address addr1,
        address addr2
    ) internal pure returns (address[] memory) {
        address[] memory arr = new address[](2);
        arr[0] = addr1;
        arr[1] = addr2;
        return arr;
    }

    function _threeItemsAddressArray(
        address addr1,
        address addr2,
        address addr3
    ) internal pure returns (address[] memory) {
        address[] memory arr = new address[](3);
        arr[0] = addr1;
        arr[1] = addr2;
        arr[2] = addr3;
        return arr;
    }

    function _fourItemsAddressArray(
        address addr1,
        address addr2,
        address addr3,
        address addr4
    ) internal pure returns (address[] memory) {
        address[] memory arr = new address[](4);
        arr[0] = addr1;
        arr[1] = addr2;
        arr[2] = addr3;
        arr[3] = addr4;
        return arr;
    }

    function _fiveItemsAddressArray(
        address addr1,
        address addr2,
        address addr3,
        address addr4,
        address addr5
    ) internal pure returns (address[] memory) {
        address[] memory arr = new address[](5);
        arr[0] = addr1;
        arr[1] = addr2;
        arr[2] = addr3;
        arr[3] = addr4;
        arr[4] = addr5;
        return arr;
    }

    function _createDiamond(
        address diamondFactory,
        address taskManager,
        address authzSource,
        string memory name,
        address[] memory defaultFacets
    ) internal returns (address) {
        address diamond = IDiamondFactory(diamondFactory).createDiamond(
            __emptySupporintgInterfaceIds(),
            address(this)
        );
        // intialize the diamond
        IDiamondInitializer(diamond).initialize(
            name,
            taskManager,
            address(0), // app-registry
            authzSource,
            "diamonds",
            __emptyApps(),
            defaultFacets,
            __emptyFuncSigsToProtectOrUnprotect(),
            __emptyFacetsToFreeze(),
            __noLockNoFreeze()
        );
        return diamond;
    }

    function __emptySupporintgInterfaceIds() private pure returns (bytes4[] memory) {
        return new bytes4[](0);
    }

    function __emptyApps() private pure returns (string[][2] memory) {
        string[][2] memory apps;
        apps[0] = new string[](0);
        apps[1] = new string[](0);
        return apps;
    }

    function __emptyFuncSigsToProtectOrUnprotect() private pure returns (string[][2] memory) {
        string[][2] memory funcSigsToProtectOrUnprotect;
        funcSigsToProtectOrUnprotect[0] = new string[](0);
        funcSigsToProtectOrUnprotect[1] = new string[](0);
        return funcSigsToProtectOrUnprotect;
    }

    function __emptyFacetsToFreeze() private pure returns (address[] memory) {
        return new address[](0);
    }

    function __noLockNoFreeze() private pure returns (bool[3] memory) {
        return [ false, false, false ];
    }
}