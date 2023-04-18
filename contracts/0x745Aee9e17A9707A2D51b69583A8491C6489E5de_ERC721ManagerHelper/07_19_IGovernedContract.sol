// SPDX-License-Identifier: MIT

// Copyright 2023 Energi Core

pragma solidity 0.8.0;

interface IGovernedContract {
    // Return actual proxy address for secure validation
    function proxy() external view returns (address);
}