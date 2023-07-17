// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

abstract contract ParallelOperatorFilterer is DefaultOperatorFilterer {
    bool public isFilterDisabled;

    /**
     * @dev A helper function to check if an operator is allowed.
     */
    modifier onlyAllowedOperator(address from) override {
        // Allow spending tokens from addresses with balance
        // Note that this still allows listings and marketplaces with escrow to transfer tokens if transferred
        // from an EOA.
        if (from != msg.sender && !isFilterDisabled) {
            _checkFilterOperator(msg.sender);
        }
        _;
    }

    /**
     * @dev A helper function to check if an operator approval is allowed.
     */
    modifier onlyAllowedOperatorApproval(address operator) override {
        if (!isFilterDisabled) {
            _checkFilterOperator(operator);
        }
        _;
    }
}