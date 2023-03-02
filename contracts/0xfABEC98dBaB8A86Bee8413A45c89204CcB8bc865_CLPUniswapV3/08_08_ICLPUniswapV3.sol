// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;

interface ICLPUniswapV3 {
    struct UniswapV3LPDepositParams {
        address router;
        uint256 amountAMin;
        uint256 amountBMin;
        address receiver;
        uint256 deadline;
    }
    struct UniswapV3LPWithdrawParams {
        address router;
        uint256 amountAMin;
        uint256 amountBMin;
        address receiver;
        uint256 deadline;
    }
}