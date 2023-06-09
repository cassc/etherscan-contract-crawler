// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/token/ERC20/TokenTimelock.sol";


pragma solidity 0.7.5;
pragma abicoder v2;

contract MAY2023Timelock is TokenTimelock {
    constructor(
        IERC20 token_,
        address beneficiary_,
        uint256 releaseTime_
    ) TokenTimelock(token_, beneficiary_, releaseTime_) {}
}