// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;
pragma abicoder v2;

// https://github.com/Uniswap/v3-core/blob/main/contracts/libraries/FixedPoint96.sol
library FixedPoint96 {
    uint8 internal constant RESOLUTION = 96;
    uint256 internal constant Q96 = 0x1000000000000000000000000;
}