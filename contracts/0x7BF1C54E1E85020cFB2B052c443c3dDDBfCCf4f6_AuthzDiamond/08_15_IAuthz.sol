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

library AuthzLib {

    uint256 public constant ROLE_AUTHZ_DIAMOND_ADMIN = uint256(keccak256(bytes("ROLE_AUTHZ_DIAMOND_ADMIN")));
    uint256 public constant ROLE_AUTHZ_ADMIN = uint256(keccak256(bytes("ROLE_AUTHZ_ADMIN")));

    bytes32 constant public GLOBAL_DOMAIN_HASH = keccak256(abi.encodePacked("global"));
    bytes32 constant public MATCH_ALL_WILDCARD_HASH = keccak256(abi.encodePacked("*"));

    // operations
    uint256 constant public CALL_OP = 5000;
    uint256 constant public MATCH_ALL_WILDCARD_OP = 9999;

    // actions
    uint256 constant public ACCEPT_ACTION = 1;
    uint256 constant public REJECT_ACTION = 100;
}

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
interface IAuthz {

    function authorize(
        bytes32 domainHash,
        bytes32 identityHash,
        bytes32[] memory targets,
        uint256[] memory ops
    ) external view returns (uint256[] memory);
}