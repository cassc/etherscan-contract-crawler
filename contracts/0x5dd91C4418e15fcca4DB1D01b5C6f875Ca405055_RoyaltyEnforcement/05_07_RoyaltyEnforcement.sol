// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "@openzeppelin/contracts/utils/Strings.sol";

import "./RoyaltyEnforcementInternal.sol";
import "./RoyaltyEnforcementStorage.sol";
import "./IRoyaltyEnforcement.sol";

/**
 * @title Royalty Enforcement
 * @notice Shows current state of on-chain royalties enforcement on blocklisting marketplaces.
 *
 * @custom:type eip-2535-facet
 * @custom:category Tokens
 * @custom:provides-interfaces IRoyaltyEnforcement
 */
contract RoyaltyEnforcement is IRoyaltyEnforcement, RoyaltyEnforcementInternal {
    function hasRoyaltyEnforcement() external view override returns (bool) {
        return _hasRoyaltyEnforcement();
    }
}