//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.15;

import "@openzeppelin/contracts/finance/PaymentSplitter.sol";

contract SplitPayment is PaymentSplitter {
    
    constructor(address[] memory payees, uint256[] memory shares) PaymentSplitter(payees, shares) {}
    
}