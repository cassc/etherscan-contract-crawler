// SPDX-License-Identifier: MIT
// Copyright 2022 PROOF Holdings Inc
pragma solidity >=0.8.16 <0.9.0;

/**
 * @notice Interface to encapsulate generic eligibility requirements.
 * @dev This is intended to be used with the activation of Mutators.
 */
interface IEligibilityConstraint {
    /**
     * @notice Checks if a given moonbird is eligible.
     */
    function isEligible(uint256 tokenId) external view returns (bool);
}