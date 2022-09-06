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

import "../../security/role-manager/RoleManagerLib.sol";
import "../../diamond/IDiamondFacet.sol";
import "../IAppRegistry.sol";
import "./AppRegistryInternal.sol";
import "./AppRegistryConfig.sol";

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
contract AppRegistryFacet is IDiamondFacet, IAppRegistry {

    modifier onlyAppRegistryAdmin() {
        RoleManagerLib._checkRole(AppRegistryConfig.ROLE_APP_REGISTRY_ADMIN);
        _;
    }

    function getFacetName() external pure override returns (string memory) {
        return "app-registry";
    }

    function getFacetVersion() external pure override returns (string memory) {
        return "0.0.1";
    }

    function getFacetPI() external pure override returns (string[] memory) {
        string[] memory pi = new string[](6);
        pi[0] = "getAllApps()";
        pi[1] = "getEnabledApps()";
        pi[2] = "isAppEnabled(string,string)";
        pi[3] = "addApp(string,string,address[],bool)";
        pi[4] = "enableApp(string,string,bool)";
        pi[5] = "getAppFacets(string,string)";
        return pi;
    }

    function supportsInterface(bytes4 interfaceId)
      external view override virtual returns (bool) {
        return interfaceId == type(IDiamondFacet).interfaceId ||
               interfaceId == type(IAppRegistry).interfaceId;
    }

    function getAllApps() external view onlyAppRegistryAdmin returns (string[] memory) {
        return AppRegistryInternal._getAllApps();
    }

    function getEnabledApps() external view onlyAppRegistryAdmin returns (string[] memory) {
        return AppRegistryInternal._getEnabledApps();
    }

    function isAppEnabled(
        string memory name,
        string memory version
    ) external view onlyAppRegistryAdmin returns (bool) {
        return AppRegistryInternal._isAppEnabled(name, version);
    }

    function addApp(
        string memory name,
        string memory version,
        address[] memory facets,
        bool enabled
    ) external onlyAppRegistryAdmin {
        return AppRegistryInternal._addApp(name, version , facets, enabled);
    }

    // NOTE: This is the only mutator for the app entries
    function enableApp(
        string memory name,
        string memory version,
        bool enabled
    ) external onlyAppRegistryAdmin {
        return AppRegistryInternal._enableApp(name, version, enabled);
    }

    function getAppFacets(
        string memory name,
        string memory version
    ) external view override returns (address[] memory) {
        return AppRegistryInternal._getAppFacets(name, version);
    }
}