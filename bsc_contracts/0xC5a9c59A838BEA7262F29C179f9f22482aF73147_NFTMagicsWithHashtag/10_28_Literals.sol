// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract Literals {
    address internal constant _ZERO_ADDRESS = address(0);
    address internal constant _DEAD_ADDRESS =
        0x000000000000000000000000000000000000dEaD;

    uint256 internal constant _ONE_HUNDRED = 100;
    uint8 internal constant _TWENTY = 20;
    uint8 internal constant _ONE = 1;
    uint8 internal constant _TWO = 2;
    uint8 internal constant _THREE = 3;
    uint8 internal constant _FIVE = 5;
    uint8 internal constant _TEN = 10;
    uint8 internal constant _ZERO = 0;

    uint256 internal constant _PERCENTAGE_PRECISION = 1 ether;

    uint256 internal constant _MAX_UINT_256 = type(uint256).max;

    string internal constant _INSUFFICIENT_VALUE =
        'Insufficient value sent with transaction';
}