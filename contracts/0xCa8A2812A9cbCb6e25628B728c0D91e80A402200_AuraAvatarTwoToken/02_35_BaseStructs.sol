// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

struct TokenAmount {
    address token;
    uint256 amount;
}

struct BpsConfig {
    uint256 val;
    uint256 min;
}