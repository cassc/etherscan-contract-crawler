// SPDX-License-Identifier: MIT 

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/finance/PaymentSplitter.sol";

contract Splitter is PaymentSplitter {

    constructor (
        address[] memory payees,
        uint256[] memory shares
    ) PaymentSplitter(payees, shares) {}
    
}