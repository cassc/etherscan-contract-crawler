// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

// File: Types.sol

/**
 * @title MoneyInstant Types
 */
library Types {
    struct Payment {
        address recipient;
        uint256 deposit;
    }
}