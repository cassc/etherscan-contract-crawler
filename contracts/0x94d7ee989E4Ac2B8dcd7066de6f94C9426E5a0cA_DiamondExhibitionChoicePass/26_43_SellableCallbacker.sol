// SPDX-License-Identifier: MIT
// Copyright 2023 PROOF Holdings Inc
pragma solidity >=0.8.0 <0.9.0;

import {ISellable} from "../interfaces/ISellable.sol";
import {PurchaseExecuter} from "../interfaces/PurchaseExecuter.sol";

/**
 * @notice Executes a purchase by calling the purchase interface of a `ISellable`  contract.
 */
abstract contract SellableCallbacker is PurchaseExecuter {
    /**
     * @notice Emitted when the callback to the `ISellable` contract fails.
     */
    error CallbackFailed(bytes reason);

    /**
     * @notice The `ISellable` contract that will be called to execute the purchase.
     */
    ISellable public immutable sellable;

    constructor(ISellable sellable_) {
        sellable = ISellable(sellable_);
    }

    /**
     * @notice Executes a purchase by calling the sale interface of a `ISellable` contract.
     */
    function _executePurchase(address to, uint64 num, uint256 cost, bytes memory data) internal virtual override {
        try sellable.handleSale{value: cost}(to, num, data) {}
        catch (bytes memory reason) {
            // TODO(dave): the reason is empty if the above call runs OutOfFund. Explore ways to bubble this up more cleanly.
            revert CallbackFailed(reason);
        }
    }
}