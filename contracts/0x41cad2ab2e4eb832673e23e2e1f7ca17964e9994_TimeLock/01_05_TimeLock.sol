// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/TokenTimeLock.sol";

contract TimeLock is TokenTimelock {

    constructor(IERC20 token, address beneficiary, uint256 releaseTime) TokenTimelock(token, beneficiary, releaseTime) {
    }
}