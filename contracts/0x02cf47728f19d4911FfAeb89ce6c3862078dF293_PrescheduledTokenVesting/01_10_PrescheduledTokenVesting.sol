// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import "./TokenVesting.sol";

contract PrescheduledTokenVesting is TokenVesting {
    constructor(address token_) TokenVesting(token_) {
    }
}