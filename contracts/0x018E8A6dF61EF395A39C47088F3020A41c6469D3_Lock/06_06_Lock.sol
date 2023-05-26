// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/utils/TokenTimelock.sol';

contract Lock is TokenTimelock {
    constructor(IERC20 token, address beneficiary, uint256 releaseTime)
        TokenTimelock(token, beneficiary, releaseTime)
    {}
}