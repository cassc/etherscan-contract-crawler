//SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {PaymentSplitter} from "@openzeppelin/contracts/finance/PaymentSplitter.sol";

contract RoyaltySplitter is PaymentSplitter {
    constructor(
        address[] memory payees,
        uint256[] memory shares_
    ) PaymentSplitter(payees, shares_) {}
}