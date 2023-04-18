// SPDX-License-Identifier: MIT
// Copyright 2023 PROOF Holdings Inc
pragma solidity ^0.8.16;

import {CallbackerWithAccessControl} from "./CallbackerWithAccessControl.sol";
import {ExactFixedPrice} from "../base/InternallyPriced.sol";

/**
 * @notice Seller with a steerer-settable price.
 */
abstract contract ExactSettableFixedPrice is ExactFixedPrice, CallbackerWithAccessControl {
    constructor(uint256 price) ExactFixedPrice(price) {}

    /**
     * @notice Sets the price of a single purchase.
     */
    function setPrice(uint256 price) external onlyRole(DEFAULT_STEERING_ROLE) {
        _setPrice(price);
    }
}