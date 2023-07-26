// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {IOperatorFilterRegistry} from "./operator-filter-registry/IOperatorFilterRegistry.sol";

import "./Authorizable.sol";

/**
 * @title  UpdateableOperatorFilterer
 * @notice Abstract contract whose constructor automatically registers and optionally subscribes to or copies another
 *         registrant's entries in the OperatorFilterRegistry.
 * @dev    This smart contract is meant to be inherited by token contracts so they can use the following:
 *         - `onlyAllowedOperator` modifier for `transferFrom` and `safeTransferFrom` methods.
 *         - `onlyAllowedOperatorApproval` modifier for `approve` and `setApprovalForAll` methods.
 */
abstract contract UpdateableOperatorFilterer is Authorizable {
    error OperatorNotAllowed(address operator);

    address constant DEFAULT_OPERATOR_FILTER_REGISTRY_ADDRESS =
        address(0x000000000000AAeB6D7670E522A718067333cd4E);

    address constant DEFAULT_SUBSCRIPTION =
        address(0x3cc6CddA760b79bAfa08dF41ECFA224f810dCeB6);

    IOperatorFilterRegistry public OperatorFilterRegistry =
        IOperatorFilterRegistry(DEFAULT_OPERATOR_FILTER_REGISTRY_ADDRESS);

    constructor() {
        if (address(OperatorFilterRegistry).code.length > 0) {
            OperatorFilterRegistry.registerAndSubscribe(
                address(this),
                DEFAULT_SUBSCRIPTION
            );
        }
    }

    modifier onlyAllowedOperator(address from) virtual {
        // Allow spending tokens from addresses with balance
        // Note that this still allows listings and marketplaces with escrow to transfer tokens if transferred
        // from an EOA.
        if (from != msg.sender) {
            _checkFilterOperator(msg.sender);
        }
        _;
    }

    modifier onlyAllowedOperatorApproval(address operator) virtual {
        _checkFilterOperator(operator);
        _;
    }

    function _checkFilterOperator(address operator) internal view virtual {
        // Check registry code length to facilitate testing in environments without a deployed registry.
        if (address(OperatorFilterRegistry).code.length > 0) {
            require(
                OperatorFilterRegistry.isOperatorAllowed(
                    address(this),
                    operator
                ),
                "operator is not allowed"
            );
        }
    }

    /**
     * @notice update the operator filter registry
     */
    function updateOperatorFilterRegistry(address operatorFilterRegisterAddress)
        external
        onlyOwner
    {
        OperatorFilterRegistry = IOperatorFilterRegistry(
            operatorFilterRegisterAddress
        );
    }
}