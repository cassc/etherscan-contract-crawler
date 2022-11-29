// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

/**
 * @dev Manages if royalties are enforced by blocklisting marketplaces with optional royalty.
 * @dev Derived from 'operator-filter-registry' NPM repository by OpenSea.
 */
interface IRoyaltyEnforcementAdmin {
    function toggleRoyaltyEnforcement(bool enforce) external;

    function registerRoyaltyEnforcement(address subscriptionOrRegistrantToCopy, bool subscribe) external;
}