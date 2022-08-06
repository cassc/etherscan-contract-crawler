// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/finance/PaymentSplitter.sol";

contract breezySplitterV2 is PaymentSplitter {
    constructor(address[] memory payees, uint256[] memory shares)
        PaymentSplitter(payees, shares)
    {}
}