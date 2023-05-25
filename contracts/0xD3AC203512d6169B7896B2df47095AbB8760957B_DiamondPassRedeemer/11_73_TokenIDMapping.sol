// SPDX-License-Identifier: MIT
// Copyright 2023 Proof Holdings Inc.
pragma solidity ^0.8.0;

uint256 constant AB_ENGINE_PROJECT_MULTIPLIER = 1_000_000;

function artblocksTokenID(uint256 projectId, uint256 edition) pure returns (uint256) {
    return (projectId * AB_ENGINE_PROJECT_MULTIPLIER) + edition;
}