// SPDX-License-Identifier: MIT

// Copyright 2023 Energi Core

pragma solidity 0.5.16;

interface IOwnable {
    function owner() external returns (address);

    function transferOwnership(address newOwner) external;
}