// SPDX-License-Identifier: MIT
// Copyright 2022 PROOF Holdings Inc
pragma solidity ^0.8.16;

import {Features} from "moonbirds-inchain/gen/Features.sol";

/**
 * @notice Interface for Moonbird features providiers (registries).
 */
interface IFeaturesProvider {
    /**
     * @notice Checks if the provider can return features for the given Moonbird.
     */
    function hasFeatures(uint256 tokenId) external view returns (bool);

    /**
     * @notice Fetches the features of a given Moonbird.
     * @dev MUST revert if the provider has no features for the given tokenId.
     */
    function getFeatures(uint256 tokenId)
        external
        view
        returns (Features memory);
}