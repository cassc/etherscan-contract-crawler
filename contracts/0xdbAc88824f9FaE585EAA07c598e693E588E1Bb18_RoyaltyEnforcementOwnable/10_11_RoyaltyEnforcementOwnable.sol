// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "@openzeppelin/contracts/utils/Strings.sol";

import "../../access/ownable/OwnableInternal.sol";

import "./RoyaltyEnforcementStorage.sol";
import "./IRoyaltyEnforcementAdmin.sol";
import "./RoyaltyEnforcementInternal.sol";

/**
 * @title Royalty Enforcement - Admin - Ownable
 * @notice Controls where on-chain royalties must be enforced by blocklisting marketplaces.
 *
 * @custom:type eip-2535-facet
 * @custom:category Tokens
 * @custom:peer-dependencies IRoyaltyEnforcement
 * @custom:provides-interfaces IRoyaltyEnforcementAdmin
 */
contract RoyaltyEnforcementOwnable is IRoyaltyEnforcementAdmin, RoyaltyEnforcementInternal, OwnableInternal {
    function toggleRoyaltyEnforcement(bool enforce) external override onlyOwner {
        _toggleRoyaltyEnforcement(enforce);
    }

    function registerRoyaltyEnforcement(address subscriptionOrRegistrantToCopy, bool subscribe)
        external
        override
        onlyOwner
    {
        _register(subscriptionOrRegistrantToCopy, subscribe);
    }
}