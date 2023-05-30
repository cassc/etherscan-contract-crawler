// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {OperatorFilterer} from "./OperatorFilterer.sol";

/**
 * @title FlexibleOperatorFilterer
 * @author BaseLabs
 */
abstract contract FlexibleOperatorFilterer is OperatorFilterer {
    error ErrOnlyOwner();

    address constant DEFAULT_SUBSCRIPTION =
        address(0x3cc6CddA760b79bAfa08dF41ECFA224f810dCeB6);
    bool public isOperatorFilterRegistryEnabled;
    mapping(address => bool) public operatorFilterWhitelist;

    constructor() OperatorFilterer(DEFAULT_SUBSCRIPTION, true) {}

    modifier onlyAllowedOperator(address from) override {
        // Check registry code length to facilitate testing in environments without a deployed registry.
        if (
            isOperatorFilterRegistryEnabled &&
            !operatorFilterWhitelist[msg.sender] &&
            address(OPERATOR_FILTER_REGISTRY).code.length > 0
        ) {
            // Allow spending tokens from addresses with balance
            // Note that this still allows listings and marketplaces with escrow to transfer tokens if transferred
            // from an EOA.
            if (from == msg.sender) {
                _;
                return;
            }
            if (
                !OPERATOR_FILTER_REGISTRY.isOperatorAllowed(
                    address(this),
                    msg.sender
                )
            ) {
                revert OperatorNotAllowed(msg.sender);
            }
        }
        _;
    }

    modifier onlyAllowedOperatorApproval(address operator) override {
        // Check registry code length to facilitate testing in environments without a deployed registry.
        if (
            isOperatorFilterRegistryEnabled &&
            !operatorFilterWhitelist[operator] &&
            address(OPERATOR_FILTER_REGISTRY).code.length > 0
        ) {
            if (
                !OPERATOR_FILTER_REGISTRY.isOperatorAllowed(
                    address(this),
                    operator
                )
            ) {
                revert OperatorNotAllowed(operator);
            }
        }
        _;
    }

    /**
     * @notice setOperatorFilterRegistryWhitelist is used to set the whitelist of operator filter registry.
     * @param state_ If state_ is true, OperatorFilterRegistry for this address will be disabled.
     */
    function setOperatorFilterRegistryWhitelist(
        address address_,
        bool state_
    ) external {
        if (msg.sender != owner()) {
            revert ErrOnlyOwner();
        }
        operatorFilterWhitelist[address_] = state_;
    }

    /**
     * @notice setOperatorFilterRegistryState is used to update the state of isOperatorFilterRegistryEnabled flag.
     * @param enabled_ If enabled_ is true, OperatorFilterRegistry will be enabled.
     */
    function setOperatorFilterRegistryState(bool enabled_) external {
        if (msg.sender != owner()) {
            revert ErrOnlyOwner();
        }
        isOperatorFilterRegistryEnabled = enabled_;
    }

    /**
     * @dev assume the contract has an owner, but leave specific Ownable implementation up to inheriting contract
     */
    function owner() public view virtual returns (address);
}