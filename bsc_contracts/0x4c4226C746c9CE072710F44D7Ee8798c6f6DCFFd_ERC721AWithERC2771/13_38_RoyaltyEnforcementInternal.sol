// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "operator-filter-registry/src/IOperatorFilterRegistry.sol";

import "./IRoyaltyEnforcementInternal.sol";
import "./RoyaltyEnforcementStorage.sol";

/**
 * @dev Manages and shows if royalties are enforced by blocklisting marketplaces with optional royalty.
 * @dev Derived from 'operator-filter-registry' NPM repository by OpenSea.
 */
abstract contract RoyaltyEnforcementInternal is IRoyaltyEnforcementInternal {
    // address private constant DEFAULT_SUBSCRIPTION = address(0x3cc6CddA760b79bAfa08dF41ECFA224f810dCeB6);

    IOperatorFilterRegistry private constant OPERATOR_FILTER_REGISTRY =
        IOperatorFilterRegistry(0x000000000000AAeB6D7670E522A718067333cd4E);

    function _hasRoyaltyEnforcement() internal view virtual returns (bool) {
        return RoyaltyEnforcementStorage.layout().enforceRoyalties;
    }

    function _toggleRoyaltyEnforcement(bool enforce) internal virtual {
        RoyaltyEnforcementStorage.layout().enforceRoyalties = enforce;
    }

    function _register(address subscriptionOrRegistrantToCopy, bool subscribe) internal virtual {
        // If an inheriting token contract is deployed to a network without the registry deployed, the modifier
        // will not revert, but the contract will need to be registered with the registry once it is deployed in
        // order for the modifier to filter addresses.
        if (address(OPERATOR_FILTER_REGISTRY).code.length > 0) {
            if (!OPERATOR_FILTER_REGISTRY.isRegistered(address(this))) {
                if (subscribe) {
                    OPERATOR_FILTER_REGISTRY.registerAndSubscribe(address(this), subscriptionOrRegistrantToCopy);
                } else {
                    if (subscriptionOrRegistrantToCopy != address(0)) {
                        OPERATOR_FILTER_REGISTRY.registerAndCopyEntries(address(this), subscriptionOrRegistrantToCopy);
                    } else {
                        OPERATOR_FILTER_REGISTRY.register(address(this));
                    }
                }
            }
        }
    }

    modifier onlyAllowedOperator(address from) virtual {
        // Check registry code length to facilitate testing in environments without a deployed registry.
        if (RoyaltyEnforcementStorage.layout().enforceRoyalties) {
            if (address(OPERATOR_FILTER_REGISTRY).code.length > 0) {
                // Allow spending tokens from addresses with balance
                // Note that this still allows listings and marketplaces with escrow to transfer tokens if transferred
                // from an EOA.
                if (from == msg.sender) {
                    _;
                    return;
                }
                if (!OPERATOR_FILTER_REGISTRY.isOperatorAllowed(address(this), msg.sender)) {
                    revert OperatorNotAllowed(msg.sender);
                }
            }
        }
        _;
    }

    modifier onlyAllowedOperatorApproval(address operator) virtual {
        // Check registry code length to facilitate testing in environments without a deployed registry.
        if (RoyaltyEnforcementStorage.layout().enforceRoyalties) {
            if (address(OPERATOR_FILTER_REGISTRY).code.length > 0) {
                if (!OPERATOR_FILTER_REGISTRY.isOperatorAllowed(address(this), operator)) {
                    revert OperatorNotAllowed(operator);
                }
            }
        }
        _;
    }
}