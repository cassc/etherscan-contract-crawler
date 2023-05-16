pragma solidity 0.8.4;

// SPDX-License-Identifier: MIT

import "./TokenTimelock.sol";

contract Locker is TokenTimelock {
    constructor(IERC20 token, address beneficiary, uint256 releaseTime) TokenTimelock(token, beneficiary, releaseTime) {}
}