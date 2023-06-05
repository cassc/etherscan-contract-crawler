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

import "../../diamond/IDiamondFacet.sol";
import "./RBACInternal.sol";

contract RBACFacet is IDiamondFacet {

    function getFacetName()
      external pure override returns (string memory) {
        return "rbac";
    }

    // CAUTION: Don't forget to update the version when adding new functionality
    function getFacetVersion()
      external pure override returns (string memory) {
        return "1.0.0";
    }

    function getFacetPI()
      external pure override returns (string[] memory) {
        string[] memory pi = new string[](3);
        pi[ 0] = "hasRole(address,uint256)";
        pi[ 1] = "grantRole(uint256,string,address,uint256)";
        pi[ 2] = "revokeRole(uint256,string,address,uint256)";
        return pi;
    }

    function getFacetProtectedPI()
      external pure override returns (string[] memory) {
        string[] memory pi = new string[](2);
        pi[ 0] = "grantRole(uint256,string,address,uint256)";
        pi[ 1] = "revokeRole(uint256,string,address,uint256)";
        return pi;
    }

    function supportsInterface(bytes4 interfaceId)
      external pure override returns (bool) {
        return interfaceId == type(IDiamondFacet).interfaceId;
    }

    function hasRole(
        address account,
        uint256 role
    ) external view returns (bool) {
        return RBACInternal._hasRole(account, role);
    }

    function grantRole(
        uint256 taskId,
        string memory taskManagerKey,
        address account,
        uint256 role
    ) external {
        RBACInternal._grantRole(taskId, taskManagerKey, account, role);
    }

    function revokeRole(
        uint256 taskId,
        string memory taskManagerKey,
        address account,
        uint256 role
    ) external {
        RBACInternal._revokeRole(taskId, taskManagerKey, account, role);
    }
}