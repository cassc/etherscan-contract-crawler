// SPDX-License-Identifier: UNLICENSED
// Copyright (c) Eywa.Fi, 2021-2023 - all rights reserved
pragma solidity 0.8.17;


interface ISynthesisV2 {

    function synthByOriginal(uint64 chainIdFrom, address otoken) external view returns (address stoken);

    function synthBySynth(address stoken) external view returns (address adapter);

    function mint(
        address token,
        uint256 amount,
        address from,
        address to,
        uint64 chainIdFrom
    ) external returns (uint256 amountOut);

    function emergencyMint(
        address token,
        uint256 amount,
        address from,
        address to
    ) external returns (uint256 amountOut);

    function burn(
        address stoken,
        uint256 amount,
        address from,
        address to,
        uint64 chainIdTo
    ) external;
}