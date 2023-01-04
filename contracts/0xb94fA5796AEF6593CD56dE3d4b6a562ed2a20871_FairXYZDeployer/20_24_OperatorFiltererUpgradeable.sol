// SPDX-License-Identifier: MIT

// @author: Fair.xyz dev

pragma solidity 0.8.17;

import {IOperatorFilterRegistry} from "./OperatorFilterRegistry/IOperatorFilterRegistry.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

abstract contract OperatorFiltererUpgradeable is Initializable {
    error OnlyAdmin();
    error OperatorNotAllowed(address operator);
    error RegistryInvalid();

    event OperatorFilterDisabled(bool disabled);

    bool public operatorFilterDisabled;

    IOperatorFilterRegistry public operatorFilterRegistry;

    function __OperatorFilterer_init(
        address registry_,
        address subscriptionOrRegistrantToCopy,
        bool subscribe
    ) internal onlyInitializing {
        if (address(registry_).code.length > 0) {
            IOperatorFilterRegistry registry = IOperatorFilterRegistry(
                registry_
            );
            _registerAndSubscribe(
                registry,
                subscriptionOrRegistrantToCopy,
                subscribe
            );
            operatorFilterRegistry = registry;
        }
    }

    // * MODIFIERS * //

    modifier onlyAllowedOperator(address from) virtual {
        // Check registry code length to facilitate testing in environments without a deployed registry.
        if (
            !operatorFilterDisabled &&
            address(operatorFilterRegistry).code.length > 0
        ) {
            // Allow spending tokens from addresses with balance
            // Note that this still allows listings and marketplaces with escrow to transfer tokens if transferred
            // from an EOA.
            if (from == msg.sender) {
                _;
                return;
            }
            if (
                !operatorFilterRegistry.isOperatorAllowed(
                    address(this),
                    msg.sender
                )
            ) {
                revert OperatorNotAllowed(msg.sender);
            }
        }
        _;
    }

    modifier onlyAllowedOperatorApproval(address operator) virtual {
        // Check registry code length to facilitate testing in environments without a deployed registry.
        if (
            !operatorFilterDisabled &&
            address(operatorFilterRegistry).code.length > 0
        ) {
            if (
                !operatorFilterRegistry.isOperatorAllowed(
                    address(this),
                    operator
                )
            ) {
                revert OperatorNotAllowed(operator);
            }
        }
        _;
    }

    modifier onlyOperatorFilterAdmin() {
        if (!_isOperatorFilterAdmin(msg.sender)) {
            revert OnlyAdmin();
        }
        _;
    }

    // * ADMIN * //

    /**
     * @notice Enable/Disable Operator Filter
     */
    function toggleOperatorFilterDisabled()
        public
        virtual
        onlyOperatorFilterAdmin
        returns (bool)
    {
        bool disabled = !operatorFilterDisabled;
        operatorFilterDisabled = disabled;
        emit OperatorFilterDisabled(disabled);
        return disabled;
    }

    /**
     * @notice Update Operator Filter Registry and optionally subscribe to registrant (if supplied)
     */
    function updateOperatorFilterRegistry(
        address newRegistry,
        address subscriptionOrRegistrantToCopy,
        bool subscribe
    ) public virtual onlyOperatorFilterAdmin {
        IOperatorFilterRegistry registry = IOperatorFilterRegistry(newRegistry);
        if (address(registry).code.length == 0) revert RegistryInvalid();

        // it is technically possible that the owner has already registered the contract with the registry directly
        // so we check before attempting to subscribe, otherwise it might revert without saving the address here
        if (!registry.isRegistered(address(this))) {
            _registerAndSubscribe(
                registry,
                subscriptionOrRegistrantToCopy,
                subscribe
            );
        }
        operatorFilterRegistry = registry;
    }

    /**
     * @notice Update Subcription at the current Operator Filter Registry
     */
    function updateRegistrySubscription(
        address subscriptionOrRegistrantToCopy,
        bool subscribe,
        bool copyEntries
    ) public virtual onlyOperatorFilterAdmin {
        IOperatorFilterRegistry registry = operatorFilterRegistry;
        if (address(registry).code.length == 0) revert RegistryInvalid();
        if (subscriptionOrRegistrantToCopy == address(0)) {
            registry.unsubscribe(address(this), copyEntries);
        } else {
            _registerAndSubscribe(
                registry,
                subscriptionOrRegistrantToCopy,
                subscribe
            );
        }
    }

    // * INTERNAL * //

    /**
     * @dev Inheriting contract is responsible for implementation
     */
    function _isOperatorFilterAdmin(address operator)
        internal
        view
        virtual
        returns (bool);

    /**
     * @dev Register and/or subscribe to/copy entries of registrant at the given registry
     */
    function _registerAndSubscribe(
        IOperatorFilterRegistry registry,
        address subscriptionOrRegistrantToCopy,
        bool subscribe
    ) internal virtual {
        if (registry.isRegistered(address(this))) {
            if (subscribe) {
                registry.subscribe(
                    address(this),
                    subscriptionOrRegistrantToCopy
                );
            } else {
                registry.copyEntriesOf(
                    address(this),
                    subscriptionOrRegistrantToCopy
                );
            }
        } else {
            if (subscribe) {
                registry.registerAndSubscribe(
                    address(this),
                    subscriptionOrRegistrantToCopy
                );
            } else {
                if (subscriptionOrRegistrantToCopy != address(0)) {
                    registry.registerAndCopyEntries(
                        address(this),
                        subscriptionOrRegistrantToCopy
                    );
                } else {
                    registry.register(address(this));
                }
            }
        }
    }

    uint256[50] private __gap;
}