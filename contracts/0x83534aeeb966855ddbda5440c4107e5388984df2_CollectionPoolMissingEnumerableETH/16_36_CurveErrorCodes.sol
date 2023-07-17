// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

contract CurveErrorCodes {
    error InvalidNumItems(); // The numItem value is 0
    error SpotPriceOverflow(); // The updated spot price doesn't fit into 128 bits
    error TooManyItems(); // The value of numItems passed was too great
}