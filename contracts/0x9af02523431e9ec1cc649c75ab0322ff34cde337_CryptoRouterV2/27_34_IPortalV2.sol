// SPDX-License-Identifier: UNLICENSED
// Copyright (c) Eywa.Fi, 2021-2023 - all rights reserved
pragma solidity 0.8.17;


interface IPortalV2 {
    function lock(
        address token,
        uint256 amount,
        address from,
        address to
    ) external;

    function unlock(
        address token,
        uint256 amount,
        address from,
        address to
    ) external returns (uint256);

    function emergencyUnlock(
        address token,
        uint256 amount,
        address from,
        address to
    ) external returns (uint256);
}