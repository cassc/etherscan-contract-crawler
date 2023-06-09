// SPDX-License-Identifier: UNLICENSED
// Copyright (c) Eywa.Fi, 2021-2023 - all rights reserved
pragma solidity 0.8.17;

interface IWETH9 {
    
    function withdraw(uint wad) external;

    function deposit() external payable;
    
}