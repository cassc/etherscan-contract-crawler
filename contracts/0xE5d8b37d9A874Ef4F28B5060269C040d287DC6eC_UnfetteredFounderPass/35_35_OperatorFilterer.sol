// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {IOperatorFilterRegistry} from "./IOperatorFilterRegistry.sol";
import "../../contracts/v1/util/ArrayFind.sol";
import "../../contracts/v1/util/Types.sol";

/**
 * @title  OperatorFilterer
 * @notice Abstract contract whose constructor automatically registers and optionally subscribes to or copies another
 *         registrant's entries in the OperatorFilterRegistry.
 * @dev    This smart contract is meant to be inherited by token contracts so they can use the following:
 *         - `onlyAllowedOperator` modifier for `transferFrom` and `safeTransferFrom` methods.
 *         - `onlyAllowedOperatorApproval` modifier for `approve` and `setApprovalForAll` methods.
 *         Please note that if your token contract does not provide an owner with EIP-173, it must provide
 *         administration methods on the contract itself to interact with the registry otherwise the subscription
 *         will be locked to the options set during construction.
 */

abstract contract OperatorFilterer {
    /// @dev Emitted when an operator is not allowed.
    error OperatorNotAllowed(address operator);

    using ArrayFind for address;
    OperatorRegistry[] public _operatorRegistries;
    bool _operatorFiltering = true;

    /// @dev The constructor that is called when the contract is being deployed.
    // constructor(
    //     address registry,
    //     address subscriptionOrRegistrantToCopy,
    //     bool subscribe
    // ) {
    //     _registerOperatorFilter(registry, subscriptionOrRegistrantToCopy, subscribe);
    // }

    function _registerOperatorFilter(
        address registry,
        address subscriptionOrRegistrantToCopy,
        bool subscribe
    ) internal virtual {
        if (registry.code.length == 0) return;

        IOperatorFilterRegistry filterRegistry = IOperatorFilterRegistry(
            registry
        );

        if (subscribe) {
            filterRegistry.registerAndSubscribe(
                address(this),
                subscriptionOrRegistrantToCopy
            );
        } else {
            if (subscriptionOrRegistrantToCopy != address(0)) {
                filterRegistry.registerAndCopyEntries(
                    address(this),
                    subscriptionOrRegistrantToCopy
                );
            } else {
                filterRegistry.register(address(this));
            }
        }

        _operatorRegistries.push(
            OperatorRegistry(
                registry,
                subscribe ? subscriptionOrRegistrantToCopy : address(0)
            )
        );
    }

    function _unregisterOperatorFilter(address registry) internal virtual {
        IOperatorFilterRegistry(registry).unregister(address(this));

        uint256 ind;
        uint256 len = _operatorRegistries.length;
        for (uint i = 0; i < len; i++) {
            if (_operatorRegistries[i].registry == registry) {
                ind = i + 1;
                break;
            }
        }

        if (ind == 0) return;
        if (ind < len)
            _operatorRegistries[ind - 1] = _operatorRegistries[len - 1];

        _operatorRegistries.pop();
    }

    /**
     * @dev A helper function to check if an operator is allowed.
     */
    modifier onlyAllowedOperator(address from) virtual {
        // Allow spending tokens from addresses with balance
        // Note that this still allows listings and marketplaces with escrow to transfer tokens if transferred
        // from an EOA.
        if (from != msg.sender) {
            _checkFilterOperator(msg.sender);
        }
        _;
    }

    /**
     * @dev A helper function to check if an operator approval is allowed.
     */
    modifier onlyAllowedOperatorApproval(address operator) virtual {
        _checkFilterOperator(operator);
        _;
    }

    /**
     * @dev A helper function to check if an operator is allowed.
     */
    function _checkFilterOperator(address operator) internal view virtual {
        if (!_operatorFiltering) return;

        bool ok = false;
        for (uint i = 0; i < _operatorRegistries.length; i++) {
            address registry = _operatorRegistries[i].registry;
            ok = IOperatorFilterRegistry(registry).isOperatorAllowed(
                address(this),
                operator
            );

            // only one operator allowance is enough
            if (ok) break;
        }

        // if there is no operator allowance
        if (!ok) {
            revert OperatorNotAllowed(operator);
        }
    }
}

struct OperatorRegistry {
    address registry;
    address subscription;
}