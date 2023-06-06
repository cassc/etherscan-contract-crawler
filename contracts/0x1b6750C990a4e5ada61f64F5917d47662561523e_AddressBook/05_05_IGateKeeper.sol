// SPDX-License-Identifier: UNLICENSED
// Copyright (c) Eywa.Fi, 2021-2023 - all rights reserved
pragma solidity 0.8.17;


interface IGateKeeper {

    function calculateCost(
        address payToken,
        uint256 dataLength,
        uint64 chainIdTo,
        address sender
    ) external returns (uint256 amountToPay);

    function sendData(
        bytes calldata data,
        address to,
        uint64 chainIdTo,
        address payToken
    ) external payable;

    function getNonce() external view returns (uint256);

    function bridge() external view returns (address);
}