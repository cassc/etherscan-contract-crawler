// SPDX-License-Identifier: GPL-3.0-or-later
// Deployed with donations via Gitcoin GR9

pragma solidity 0.7.6;
pragma abicoder v2;

import './abstracts/TwapLPTokenRewarder.sol';

contract TwapLPTokenRewarderL1 is TwapLPTokenRewarder {
    using SafeMath for uint256;
    using SafeMath for int256;
    using TransferHelper for address;

    constructor(address _itgr) TwapLPTokenRewarder(_itgr) {}

    function sendReward(uint256 amount, address to) internal override {
        IIntegralToken(itgr).mint(to, amount);
    }
}