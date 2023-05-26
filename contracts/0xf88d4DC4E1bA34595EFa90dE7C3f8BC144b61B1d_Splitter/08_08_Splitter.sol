// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.10;

import "@openzeppelin/contracts-upgradeable/finance/PaymentSplitterUpgradeable.sol";

contract Splitter is PaymentSplitterUpgradeable {
    function initialize(
        address[] memory payees_, 
        uint256[] memory shares_
    ) external initializer {
        __PaymentSplitter_init(payees_, shares_);
    }
}