//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./CurveConvexExtraStratBase.sol";

abstract contract CurveConvexExtraStratBaseUSDT is CurveConvexExtraStratBase {
    constructor(
        Config memory config,
        address poolLPAddr,
        address rewardsAddr,
        uint256 poolPID,
        address tokenAddr,
        address extraRewardsAddr,
        address extraTokenAddr
    ) CurveConvexExtraStratBase(
        config,
        poolLPAddr,
        rewardsAddr,
        poolPID,
        tokenAddr,
        extraRewardsAddr,
        extraTokenAddr,
        [Constants.WETH_ADDRESS, Constants.USDT_ADDRESS]
    ) { }
}