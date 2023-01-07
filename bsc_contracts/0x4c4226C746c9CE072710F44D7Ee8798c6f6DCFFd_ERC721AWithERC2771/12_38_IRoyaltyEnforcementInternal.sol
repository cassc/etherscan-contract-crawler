// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

/**
 * @dev Manages where on-chain royalties must be enforced by blocklisting marketplaces with optional royalty.
 * @dev Derived from 'operator-filter-registry' NPM repository by OpenSea.
 */
interface IRoyaltyEnforcementInternal {
    error OperatorNotAllowed(address operator);
}