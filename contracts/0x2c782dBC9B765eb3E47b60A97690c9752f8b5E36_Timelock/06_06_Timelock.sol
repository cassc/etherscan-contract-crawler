// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/utils/TokenTimelock.sol";

contract Timelock is TokenTimelock {
    IERC20 private constant USDC_AVATAR_LP = IERC20(0xf040eD78e6880Af04D5040c1C96F038A75eeFa9F);
    address private constant BENEFICIARY = 0x366307ed1C98aC8BEF7f9f190906216529563A2A;
    uint256 private constant RELEASE_TIME = 1673745947; // Same as `AVATAR.end()`

    constructor() TokenTimelock(USDC_AVATAR_LP, BENEFICIARY, RELEASE_TIME) {}
}