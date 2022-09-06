// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/finance/PaymentSplitterUpgradeable.sol";

contract MarketPaymentSplitter is PaymentSplitterUpgradeable {
    function initialize(address[] memory payees, uint256[] memory shares_)
        public
        initializer
    {
        __PaymentSplitter_init(payees, shares_);
    }
}