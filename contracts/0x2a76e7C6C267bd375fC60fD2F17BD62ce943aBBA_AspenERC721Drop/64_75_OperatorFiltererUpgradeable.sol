// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./interfaces/IOperatorFilterRegistry.sol";
import "./OperatorFilterToggle.sol";

abstract contract OperatorFiltererUpgradeable is Initializable, OperatorFilterToggle {
    error OperatorNotAllowed(address operator);

    IOperatorFilterRegistry OPERATOR_FILTER_REGISTRY;

    function __OperatorFilterer_init(
        address subscriptionOrRegistrantToCopy,
        address operatorFilterRegistry,
        bool subscribe
    ) internal onlyInitializing {
        __OperatorFilterer_init_internal(subscriptionOrRegistrantToCopy, operatorFilterRegistry, subscribe);
    }

    function __OperatorFilterer_init_internal(
        address subscriptionOrRegistrantToCopy,
        address operatorFilterRegistry,
        bool subscribe
    ) internal {
        // If an inheriting token contract is deployed to a network without the registry deployed, the modifier
        // will not revert, but the contract will need to be registered with the registry once it is deployed in
        // order for the modifier to filter addresses.
        OPERATOR_FILTER_REGISTRY = IOperatorFilterRegistry(operatorFilterRegistry);
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

    function getOperatorFilterRegistryAddress() public view returns (address) {
        return address(OPERATOR_FILTER_REGISTRY);
    }

    modifier onlyAllowedOperator(address from) virtual {
        // Check registry code length to facilitate testing in environments without a deployed registry.
        if (operatorRestriction) {
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
        if (operatorRestriction) {
            if (address(OPERATOR_FILTER_REGISTRY).code.length > 0) {
                if (!OPERATOR_FILTER_REGISTRY.isOperatorAllowed(address(this), operator)) {
                    revert OperatorNotAllowed(operator);
                }
            }
        }
        _;
    }
}