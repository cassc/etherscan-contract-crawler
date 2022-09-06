// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.10;
pragma abicoder v2;

struct ExactInQueryParam{
    address tokenIn;
    address tokenOut;
    uint256 balanceIn;
    uint256 weightIn;
    uint256 balanceOut;
    uint256 weightOut;
    uint256 amountIn;
    uint256 swapFeePercentage;
}

struct ExactInStableQueryParam{
    address[] tokens;
    uint256[] balances;
    uint256 currentAmp;
    uint256 tokenIndexIn;
    uint256 tokenIndexOut;
    uint256 amountIn;
    uint256 swapFeePercentage;
}

interface IBalancerV2Simulator {
    function calcOutGivenIn(ExactInQueryParam memory _query) external view returns (uint256);
    function calcOutGivenInForStable(ExactInStableQueryParam memory _query) external view returns (uint256);
}