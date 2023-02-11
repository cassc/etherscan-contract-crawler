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

import "./RoleManagerStorage.sol";

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
library RoleManagerInternal {

    event RoleGrant(uint256 role, address account);
    event RoleRevoke(uint256 role, address account);

    function _checkRole(uint256 role) internal view {
        require(__s().roles[role][msg.sender], "RM:MR");
    }

    function _hasRole(uint256 role) internal view returns (bool) {
        return __s().roles[role][msg.sender];
    }

    function _hasRole2(
        address account,
        uint256 role
    ) internal view returns (bool) {
        return __s().roles[role][account];
    }

    function _grantRole(
        address account,
        uint256 role
    ) internal {
        require(!__s().roles[role][account], "RM:AHR");
        __s().roles[role][account] = true;
        emit RoleGrant(role, account);
    }

    function _revokeRole(
        address account,
        uint256 role
    ) internal {
        require(__s().roles[role][account], "RM:DNHR");
        __s().roles[role][account] = false;
        emit RoleRevoke(role, account);
    }

    function __s() private pure returns (RoleManagerStorage.Layout storage) {
        return RoleManagerStorage.layout();
    }
}