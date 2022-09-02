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

import "../diamond/Diamond.sol";
import "./facet/AppRegistryConfig.sol";

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
contract AppRegistry is Diamond {

    constructor(
        string memory name,
        address taskManager,
        address[] memory diamondAdmins,
        address[] memory appRegistryAdmins
    ) Diamond(
        taskManager,
        diamondAdmins,
        name,
        address(0)
    ) {
        for (uint256 i = 0; i < appRegistryAdmins.length; i++) {
            RoleManagerLib._grantRole(appRegistryAdmins[i], AppRegistryConfig.ROLE_APP_REGISTRY_ADMIN);
        }
    }

    /* solhint-disable no-complex-fallback */
    fallback() external payable {
        address facet = _findFacet(msg.sig);
        /* solhint-disable no-inline-assembly */
        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), facet, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch result
                case 0 {
                    revert(0, returndatasize())
                }
                default {
                    return(0, returndatasize())
                }
        }
        /* solhint-enable no-inline-assembly */
    }

    /* solhint-disable no-empty-blocks */
    receive() external payable {}
}