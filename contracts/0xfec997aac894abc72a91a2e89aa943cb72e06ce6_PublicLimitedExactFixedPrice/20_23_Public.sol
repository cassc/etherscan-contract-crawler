// SPDX-License-Identifier: MIT
// Copyright 2023 PROOF Holdings Inc
pragma solidity ^0.8.16;

import {Seller} from "../base/Seller.sol";
import {InternallyPriced} from "../base/InternallyPriced.sol";

/**
 * @notice Introduces public purchase interface with an internally computed cost.
 */
abstract contract Public is InternallyPriced {
    /**
     * @notice Interface to perform public purchases.
     */
    function purchase(address to, uint64 num) public payable virtual {
        InternallyPriced._purchase(to, num, "");
    }
}