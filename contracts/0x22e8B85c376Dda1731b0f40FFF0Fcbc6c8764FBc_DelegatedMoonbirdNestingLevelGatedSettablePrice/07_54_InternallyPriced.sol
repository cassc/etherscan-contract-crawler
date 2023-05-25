// SPDX-License-Identifier: MIT
// Copyright 2023 PROOF Holdings Inc
pragma solidity >=0.8.0 <0.9.0;

import {Seller} from "./Seller.sol";

/**
 * @notice Extends the basic seller by assuming that the total cost of the purchase can be computed by an internal
 * function and is not supplied externally.
 */
abstract contract InternallyPriced is Seller {
    /**
     * @notice Computes the total cost of purchasing `num` tokens.
     * @dev This is intended to be overridden by derived contracts.
     */
    function _cost(uint64 num) internal view virtual returns (uint256);

    /**
     * @notice Returns the total cost of purchasing `num` tokens.
     * @dev Intended for third-party integrations.
     */
    function cost(uint64 num) external view returns (uint256) {
        return _cost(num);
    }
    /**
     * @dev Replaces the cost of the purchase with the computed value.
     */

    function _checkAndModifyPurchase(address to, uint64 num, uint256 cost_, bytes memory data)
        internal
        view
        virtual
        override
        returns (address, uint64, uint256)
    {
        (to, num, cost_) = super._checkAndModifyPurchase(to, num, cost_, data);
        return (to, num, _cost(num));
    }

    /**
     * @dev Convenience function without cost that is now computed internally instead.
     */
    function _purchase(address to, uint64 num, bytes memory data) internal {
        _purchase(to, num, _UNDEFINED_COST, data);
    }
}

/**
 * @notice Extends internally priced sellers by ensuring that the sent value matches the computed cost exactly.
 */
abstract contract ExactInternallyPriced is InternallyPriced {
    // =========================================================================
    //                           Errors
    // =========================================================================

    /**
     * @notice Thrown if the payment does not match the computed cost.
     */
    error WrongPayment(uint256 actual, uint256 expected);

    /**
     * @inheritdoc Seller
     */
    function _checkAndModifyPurchase(address to, uint64 num, uint256 cost_, bytes memory data)
        internal
        view
        virtual
        override
        returns (address, uint64, uint256)
    {
        (to, num, cost_) = InternallyPriced._checkAndModifyPurchase(to, num, cost_, data);
        if (msg.value != cost_) {
            revert WrongPayment(msg.value, cost_);
        }
        return (to, num, cost_);
    }
}

/**
 * @notice Public seller with a fixed price.
 */
abstract contract ExactFixedPrice is ExactInternallyPriced {
    constructor(uint256 price) {
        _setPrice(price);
    }

    /**
     * @notice The price of a single purchase.
     */
    uint256 private _price;

    /**
     * @notice Computes the cost of a purchase.
     */
    function _cost(uint64 num) internal view virtual override returns (uint256) {
        return num * _price;
    }

    /**
     * @notice Sets the price of a single purchase.
     */
    function _setPrice(uint256 price) internal {
        _price = price;
    }
}