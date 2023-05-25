// SPDX-License-Identifier: UNLICENSED
// Copyright 2023 Shipyard Software, Inc.
pragma solidity ^0.8.0;

interface SanctionsList {
    function isSanctioned(address addr) external view returns (bool);
}