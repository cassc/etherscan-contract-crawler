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

    function _sellable(address to, uint64 num, uint256 cost, bytes memory data) internal virtual returns (ISellable);

    /**
     * @notice Executes a purchase by calling the sale interface of a `ISellable` contract.
     */
    function _executePurchase(address to, uint64 num, uint256 cost, bytes memory data) internal virtual override {
        ISellable sellable = _sellable(to, num, cost, data);
        try sellable.handleSale{value: cost}(to, num, data) {}
        catch (bytes memory reason) {
            // TODO(dave): the reason is empty if the above call runs OutOfFund. Explore ways to bubble this up more cleanly.
            revert CallbackFailed(reason);
        }
    }
}

/**
 * @notice Executes a purchase by calling the purchase interface of a `ISellable`  contract.
 */
abstract contract ImmutableSellableCallbacker is SellableCallbacker {
    /**
     * @notice The `ISellable` contract that will be called to execute the purchase.
     */
    ISellable public immutable sellable;

    constructor(ISellable sellable_) {
        sellable = sellable_;
    }

    function _sellable(address, uint64, uint256, bytes memory) internal virtual override returns (ISellable) {
        return sellable;
    }
}

/**
 * @notice Executes a purchase by calling the purchase interface of a `ISellable`  contract.
 */
abstract contract SettableSellableCallbacker is SellableCallbacker {
    /**
     * @notice The `ISellable` contract that will be called to execute the purchase.
     */
    ISellable private _sellable_;

    function _sellable(address, uint64, uint256, bytes memory) internal virtual override returns (ISellable) {
        return _sellable_;
    }

    function _setSellable(ISellable sellable_) internal {
        _sellable_ = sellable_;
    }

    function sellable() public view returns (ISellable) {
        return _sellable_;
    }
}