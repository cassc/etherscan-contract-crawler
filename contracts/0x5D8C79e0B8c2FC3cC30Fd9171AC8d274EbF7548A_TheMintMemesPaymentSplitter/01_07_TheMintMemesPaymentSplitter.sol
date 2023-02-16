// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/finance/PaymentSplitter.sol";

contract TheMintMemesPaymentSplitter is PaymentSplitter {
    address[] payeesArray = [
        0x2636b3fE1F8EB82270Fc383319c8F8A700cE4865,
        0x1494b2138B7897D13F13d27B700CfF1D32a79A4d
    ];
    uint256[] sharesArray = [80, 20];

    constructor() PaymentSplitter(payeesArray, sharesArray) {}
}