// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/finance/PaymentSplitter.sol";

contract DennisSchmelzPaymentSplitter is PaymentSplitter {
    address[] payeesArray = [
        0xf94DAF28caa759471e79e39DBcEea202690b4614,
        0xf97D3956c32552355E8Da6f18C5830332A3AA9CF,
        0x4C8408a3d0A047A983fC093e621b7b6C6F75077A
    ];
    uint256[] sharesArray = [50, 25, 25];

    constructor() PaymentSplitter(payeesArray, sharesArray) {}
}