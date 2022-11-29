// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

/**
 * @dev Shows if royalties are enforced by blocklisting marketplaces with optional royalty.
 * @dev Derived from 'operator-filter-registry' NPM repository by OpenSea.
 */
interface IRoyaltyEnforcement {
    function hasRoyaltyEnforcement() external view returns (bool);
}