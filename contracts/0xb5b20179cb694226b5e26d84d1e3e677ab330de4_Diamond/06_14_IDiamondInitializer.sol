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

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
interface IDiamondInitializer {

    function initialize(
        string memory name,
        address taskManager,
        address appRegistry,
        address authzSource,
        string memory authzDomain,
        string[][2] memory defaultApps, // [0] > names, [1] > versions
        address[] memory defaultFacets,
        string[][2] memory defaultFuncSigsToProtectOrUnprotect, // [0] > protect, [1] > unprotect
        address[] memory defaultFacetsToFreeze,
        bool[3] memory instantLockAndFreezes // [0] > lock, [1] > freeze-authz, [2] > freeze-diamond
    ) external;
}