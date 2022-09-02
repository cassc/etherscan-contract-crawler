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

import "./AppRegistryStorage.sol";

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
library AppRegistryInternal {

    function _appExists(string memory name, string memory version) internal view returns (bool) {
        bytes32 nvh = __getNameVersionHash(name, version);
        return __getStrLen(__s().apps[nvh].name) > 0 &&
               __getStrLen(__s().apps[nvh].version) > 0;
    }

    function _getAllApps() internal view returns (string[] memory) {
        string[] memory apps = new string[](__s().appsArray.length);
        uint256 index = 0;
        for (uint256 i = 0; i < __s().appsArray.length; i++) {
            (string memory name, string memory version) = __deconAppArrayEntry(i);
            bytes32 nvh = __getNameVersionHash(name, version);
            if (__s().apps[nvh].enabled) {
                apps[index] = string(abi.encode("E:", name, ":", version));
            } else {
                apps[index] = string(abi.encode("D:", name, ":", version));
            }
            index += 1;
        }
        return apps;
    }

    function _getEnabledApps() internal view returns (string[] memory) {
        uint256 count = 0;
        {
            for (uint256 i = 0; i < __s().appsArray.length; i++) {
                (string memory name, string memory version) = __deconAppArrayEntry(i);
                bytes32 nvh = __getNameVersionHash(name, version);
                if (__s().apps[nvh].enabled) {
                    count += 1;
                }
            }
        }
        string[] memory apps = new string[](count);
        {
            uint256 index = 0;
            for (uint256 i = 0; i < __s().appsArray.length; i++) {
                (string memory name, string memory version) = __deconAppArrayEntry(i);
                bytes32 nvh = __getNameVersionHash(name, version);
                if (__s().apps[nvh].enabled) {
                    apps[index] = string(abi.encode(name, ":", version));
                    index += 1;
                }
            }
        }
        return apps;
    }

    function _isAppEnabled(
        string memory name,
        string memory version
    ) internal view returns (bool) {
        require(_appExists(name, version), "AREG:ANF");
        bytes32 nvh = __getNameVersionHash(name, version);
        return (__s().apps[nvh].enabled);
    }

    function _addApp(
        string memory name,
        string memory version,
        address[] memory facets,
        bool enabled
    ) internal {
        require(facets.length > 0, "AREG:ZLEN");
        require(!_appExists(name, version), "AREG:AEX");

        __validateString(name);
        __validateString(version);

        // update apps entry
        bytes32 nvh = __getNameVersionHash(name, version);
        __s().apps[nvh].name = name;
        __s().apps[nvh].version = version;
        __s().apps[nvh].enabled = enabled;
        for (uint256 i = 0; i < facets.length; i++) {
            address facet = facets[i];
            __s().apps[nvh].facets.push(facet);
        }

        // update apps array
        bytes memory toAdd = abi.encode([name], [version]);
        __s().appsArray.push(toAdd);
    }

    // NOTE: This is the only mutator for the app entries
    function _enableApp(string memory name, string memory version, bool enabled) internal {
        require(_appExists(name, version), "AREG:ANF");
        bytes32 nvh = __getNameVersionHash(name, version);
        __s().apps[nvh].enabled = enabled;
    }

    function _getAppFacets(
        string memory appName,
        string memory appVersion
    ) internal view returns (address[] memory) {
        require(_appExists(appName, appVersion), "AREG:ANF");
        bytes32 nvh = __getNameVersionHash(appName, appVersion);
        return __s().apps[nvh].facets;
    }

    function __validateString(string memory str) private pure {
        bytes memory strBytes = bytes(str);
        for (uint256 i = 0; i < strBytes.length; i++) {
            bytes1 b = strBytes[i];
            if (
                !(b >= 0x30 && b <= 0x39) && // [0-9]
                !(b >= 0x41 && b <= 0x5a) && // [A-Z]
                !(b >= 0x61 && b <= 0x7a) && // [a-z]
                 b != 0x21 && // !
                 b != 0x23 && // #
                 b != 0x24 && // $
                 b != 0x25 && // %
                 b != 0x26 && // &
                 b != 0x28 && // (
                 b != 0x29 && // )
                 b != 0x2a && // *
                 b != 0x2b && // +
                 b != 0x2c && // ,
                 b != 0x2d && // -
                 b != 0x2e && // .
                 b != 0x3a && // =
                 b != 0x3d && // =
                 b != 0x3f && // ?
                 b != 0x3b && // ;
                 b != 0x40 && // @
                 b != 0x5e && // ^
                 b != 0x5f && // _
                 b != 0x5b && // [
                 b != 0x5d && // ]
                 b != 0x7b && // {
                 b != 0x7d && // }
                 b != 0x7e    // ~
            ) {
                revert("AREG:ISTR");
            }
        }
    }

    function __getStrLen(string memory str) private pure returns (uint256) {
        return bytes(str).length;
    }

    function __deconAppArrayEntry(uint256 index) private view returns (string memory, string memory) {
        (string[] memory names, string[] memory versions) =
            abi.decode(__s().appsArray[index], (string[], string[]));
        string memory name = names[0];
        string memory version = versions[0];
        return (name, version);
    }

    function __getNameVersionHash(string memory name, string memory version) private pure returns (bytes32) {
        return bytes32(keccak256(abi.encode(name, ":", version)));
    }

    function __s() private pure returns (AppRegistryStorage.Layout storage) {
        return AppRegistryStorage.layout();
    }
}