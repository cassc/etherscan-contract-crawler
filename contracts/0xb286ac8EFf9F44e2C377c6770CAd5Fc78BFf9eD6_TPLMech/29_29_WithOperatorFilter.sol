// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {IOperatorFilterRegistry} from "./IOperatorFilterRegistry.sol";

/// @title WithOperatorFilter
/// @author dev by @dievardump
/// @notice Adds OpenSea's OperatorFilter registry management
abstract contract WithOperatorFilter {
    error OperatorNotAllowed(address operator);

    address constant DEFAULT_SUBSCRIPTION = address(0x3cc6CddA760b79bAfa08dF41ECFA224f810dCeB6);

    IOperatorFilterRegistry public constant OPERATOR_FILTER_REGISTRY =
        IOperatorFilterRegistry(0x000000000000AAeB6D7670E522A718067333cd4E);

    bool public isOperatorFilterEnabled = true;

    constructor() {
        // auto subscribe to the default subscription
        if (address(OPERATOR_FILTER_REGISTRY).code.length > 0) {
            OPERATOR_FILTER_REGISTRY.registerAndSubscribe(address(this), DEFAULT_SUBSCRIPTION);
        }
    }

    /////////////////////////////////////////////////////////
    // modifier                                            //
    /////////////////////////////////////////////////////////

    /// @notice this modifier checks if "msg.sender" is not denied to do transfers
    /// @param from the user we want to transfer the nft from
    modifier onlyAllowedOperator(address from) virtual {
        // if from == msg.sender, always allow
        if (from != msg.sender) {
            // reverts if not allowed
            _checkOperatorFilter(msg.sender);
        }
        _;
    }

    /// @notice this modifier checks if "operator" is not denied to do transfers on the current contract
    /// @dev the check will only be performed when the user is trying to approve the `operator` not unapprove
    /// @param operator the operator to check
    /// @param _approved if we are currently trying to approve the operator
    modifier onlyAllowedOperatorForApproval(address operator, bool _approved) virtual {
        // only check when the user tries to approve an operator, unapprove should always work
        if (_approved) {
            // reverts if not allowed
            _checkOperatorFilter(operator);
        }
        _;
    }

    /////////////////////////////////////////////////////////
    // Internals                                           //
    /////////////////////////////////////////////////////////

    /// @dev Internally checks if the operator filter is enabled and if the current operator is allowed to transfer
    /// @param operator the owner of the item
    function _checkOperatorFilter(address operator) internal view {
        // if the operator filter is on, and the operator registry is
        if (isOperatorFilterEnabled && address(OPERATOR_FILTER_REGISTRY).code.length > 0) {
            // if the operator is not allowed, revert
            if (!OPERATOR_FILTER_REGISTRY.isOperatorAllowed(address(this), operator)) {
                revert OperatorNotAllowed(operator);
            }
        }
    }
}