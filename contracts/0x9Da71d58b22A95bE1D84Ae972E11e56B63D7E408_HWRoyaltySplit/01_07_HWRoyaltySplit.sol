// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/finance/PaymentSplitter.sol";

contract HWRoyaltySplit is PaymentSplitter {
    address[] _payees = [
        0x711eaaBe421bd9eE4d6FF158BeF8E72db3FD8315,
        0x7A682cDb8e30402364AEbcD0A94Abe74D99af1B8
    ];

    uint256[] _shares = [50, 50];

    constructor() payable PaymentSplitter(_payees, _shares) {}
}