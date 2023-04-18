// SPDX-License-Identifier: MIT
// Copyright 2023 PROOF Holdings Inc
pragma solidity ^0.8.15;

interface MythicsEggErrors {
    /**
     * @notice Thrown if one attempts an action on a nonexistent egg.
     */
    error NonexistentEgg(uint256 tokenId);
}