// SPDX-License-Identifier: MIT
// Copyright 2022 PROOF Holdings Inc
pragma solidity ^0.8.16;

import {Mutators} from "moonbirds-inchain/types/Mutators.sol";

/**
 * @notice Interface for Moonbird mutator providiers (e.g. proof background
 * registry).
 */
interface IMutatorsProvider {
    /**
     * @notice Checks if the provider can return mutators for the given Moonbird.
     */
    function hasMutators(uint256 tokenId) external view returns (bool);

    /**
     * @notice Fetches the mutators for a given Moonbird.
     * @dev MUST revert if the provider has no mutators for the given tokenId.
     */
    function getMutators(uint256 tokenId)
        external
        view
        returns (Mutators memory);
}