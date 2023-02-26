// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {IOperatorFilterRegistry} from "./IOperatorFilterRegistry.sol";
import {CANONICAL_OPERATOR_FILTER_REGISTRY_ADDRESS} from "./lib/Constants.sol";

/**
 *      _____                     ______ __  __ _____   ______          ________ _____  ______ _____
 *     |_   _|                   |  ____|  \/  |  __ \ / __ \ \        / /  ____|  __ \|  ____|  __ \
 *       | |     __ _ _ __ ___   | |__  | \  / | |__) | |  | \ \  /\  / /| |__  | |__) | |__  | |  | |
 *       | |    / _` | '_ ` _ \  |  __| | |\/| |  ___/| |  | |\ \/  \/ / |  __| |  _  /|  __| | |  | |
 *      _| |_  | (_| | | | | | | | |____| |  | | |    | |__| | \  /\  /  | |____| | \ \| |____| |__| |
 *     |_____|  \__,_|_| |_| |_| |______|_|  |_|_|     \____/   \/  \/   |______|_|  \_\______|_____/
 *      _____   ______          __         __  __          _   _    _____ _____ _________     __
 *     |  __ \ / __ \ \        / /        |  \/  |   /\   | \ | |  / ____|_   _|__   __\ \   / /
 *     | |__) | |  | \ \  /\  / /  __  __ | \  / |  /  \  |  \| | | |      | |    | |   \ \_/ /
 *     |  ___/| |  | |\ \/  \/ /   \ \/ / | |\/| | / /\ \ | . ` | | |      | |    | |    \   /
 *     | |    | |__| | \  /\  /     >  <  | |  | |/ ____ \| |\  | | |____ _| |_   | |     | |
 *     |_|     \____/   \/  \/     /_/\_\ |_|  |_/_/    \_\_| \_|  \_____|_____|  |_|     |_|
 *
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

    IOperatorFilterRegistry public constant OPERATOR_FILTER_REGISTRY =
        IOperatorFilterRegistry(CANONICAL_OPERATOR_FILTER_REGISTRY_ADDRESS);

    /// @dev The constructor that is called when the contract is being deployed.
    constructor(address subscriptionOrRegistrantToCopy, bool subscribe) {
        // If an inheriting token contract is deployed to a network without the registry deployed, the modifier
        // will not revert, but the contract will need to be registered with the registry once it is deployed in
        // order for the modifier to filter addresses.
        if (address(OPERATOR_FILTER_REGISTRY).code.length > 0) {
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
        // Check registry code length to facilitate testing in environments without a deployed registry.
        if (address(OPERATOR_FILTER_REGISTRY).code.length > 0) {
            // under normal circumstances, this function will revert rather than return false, but inheriting contracts
            // may specify their own OperatorFilterRegistry implementations, which may behave differently
            if (!OPERATOR_FILTER_REGISTRY.isOperatorAllowed(address(this), operator)) {
                revert OperatorNotAllowed(operator);
            }
        }
    }
}