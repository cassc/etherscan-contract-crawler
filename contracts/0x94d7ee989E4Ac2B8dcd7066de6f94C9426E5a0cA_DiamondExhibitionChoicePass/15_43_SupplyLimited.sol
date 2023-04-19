// SPDX-License-Identifier: MIT
// Copyright 2023 PROOF Holdings Inc
pragma solidity >=0.8.0 <0.9.0;

import {Seller} from "./Seller.sol";

/**
 * @notice Seller module that adds an upper limit on the number of sellable items.
 */
abstract contract SupplyLimited is Seller {
    error SupplyLimitExceeded(uint64 numRequested, uint64 numLeft);

    /**
     * @notice The number of tokens that have already been sold by the seller.
     */
    uint64 private _numSold;

    /**
     * @notice Returns the total number of items sold by this contract.
     */
    function numSold() public view returns (uint64) {
        return _numSold;
    }
    /**
     * @notice Returns the total number of items sold by this contract.
     */

    function maxNumSellable() public view virtual returns (uint64);

    // -------------------------------------------------------------------------
    //
    //  Internals
    //
    // -------------------------------------------------------------------------

    /**
     * @notice Checks if the number of requested purchases is below the limit
     * given by the inventory.
     * @dev Reverts otherwise.
     */
    function _checkAndModifyPurchase(address to, uint64 num, uint256 cost, bytes memory data)
        internal
        view
        virtual
        override(Seller)
        returns (address, uint64, uint256)
    {
        (to, num, cost) = Seller._checkAndModifyPurchase(to, num, cost, data);

        uint64 numLeft = maxNumSellable() - numSold();
        if (num > numLeft) {
            revert SupplyLimitExceeded(num, numLeft);
        }

        return (to, num, cost);
    }
    /**
     * @notice Updating the total number of sold tokens.
     */

    function _beforePurchase(address to, uint64 num, uint256 cost, bytes memory data)
        internal
        virtual
        override(Seller)
    {
        Seller._beforePurchase(to, num, cost, data);
        _numSold += num;
    }
}

/**
 * @notice Seller module with a supply limit that is fixed at deployment.
 */
abstract contract FixedSupply is SupplyLimited {
    /**
     * @notice The maximum number of sellable items.
     */
    uint64 private immutable _maxNumSellable;

    constructor(uint64 maxNumSellable_) {
        _maxNumSellable = maxNumSellable_;
    }

    /**
     * @inheritdoc SupplyLimited
     */
    function maxNumSellable() public view virtual override returns (uint64) {
        return _maxNumSellable;
    }
}