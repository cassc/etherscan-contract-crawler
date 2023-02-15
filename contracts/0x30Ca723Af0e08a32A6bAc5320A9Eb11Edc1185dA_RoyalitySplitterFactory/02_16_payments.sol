// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/finance/PaymentSplitter.sol";

contract RoyalitySplitter is PaymentSplitter{

    string public name;
    constructor(address[] memory _payees, uint256[] memory _shares, string memory _name) PaymentSplitter(_payees, _shares) payable {
        name = _name;

    }
}