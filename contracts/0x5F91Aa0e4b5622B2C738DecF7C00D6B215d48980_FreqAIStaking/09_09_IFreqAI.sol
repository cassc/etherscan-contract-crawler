// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "IERC20.sol";

interface IFreqAI is IERC20 {
    struct LiquidityETHParams {
        address pair;
        address to;
        uint256 amountTokenOrLP;
        uint256 amountTokenMin;
        uint256 amountETHMin;
        uint256 deadline;
    }
}