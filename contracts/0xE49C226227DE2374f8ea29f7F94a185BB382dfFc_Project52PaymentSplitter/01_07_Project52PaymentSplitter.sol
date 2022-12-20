// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/finance/PaymentSplitter.sol";

contract Project52PaymentSplitter is PaymentSplitter {
    address[] payeesArray = [0xd409fC74A6886bE0F5C657948C5F3f3D5d40d04C,0x120f7a4FFd02d5f3c65A8D7bBD9bD17d0d16Ff50,0xefA77C4Af9973cF93F93814Dde8D9F12e3Fb8007,0xEb404c1fa794D6633ef58187BdaE5a75Bb352712,0x6d117b32b7Fb98E154B1c588B795C0FFB9be8921];
    uint256[] sharesArray = [50, 16, 16, 16, 2];

    constructor() 
        PaymentSplitter(payeesArray, sharesArray) {
    }
}