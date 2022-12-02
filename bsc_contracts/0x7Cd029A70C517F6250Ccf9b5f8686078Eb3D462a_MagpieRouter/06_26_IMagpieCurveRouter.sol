// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0 <0.9.0;

interface IMagpieCurveRouter {
    struct ExchangeArgs {
        address pool;
        address from;
        address to;
        uint256 amount;
        uint256 expected;
        address receiver;
    }

    function exchange(ExchangeArgs calldata exchangeArgs) external returns (uint256 amountOut);
}