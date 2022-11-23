// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.2;
pragma experimental ABIEncoderV2;

import { IERC20 } from "ERC20.sol";

interface IDexAggregatorAdaptor {
    struct SwapDescription {
        IERC20 fromToken;
        IERC20 toToken;
        address receiver;
        uint256 amount;
        uint256 minReturnAmount;
    }
    // spec:
    //    (revert if any of the following steps fails)
    //    1. IDexAggregatorAdaptor receives `amountIn` `fromToken` where `amountIn >= amount`.
    //    2. IDexAggregatorAdaptor receives `amountOut` `toToken` where `amountOut >= minReturnAmount`.
    //    3. `receiver` receives `amountOut` `toToken`.
    function swap(SwapDescription calldata desc, bytes calldata data) external payable returns (uint256 returnAmount);
}