// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;


interface IAggregator {

    struct ERC20Pair {
        address token;
        uint256 amount;
    }

    function batchBuyWithETH(bytes calldata tradeBytes) external payable;

    function batchBuyWithERC20s(
        ERC20Pair[] calldata erc20Pairs,
        bytes calldata tradeBytes,
        address[] calldata dustTokens
    ) external payable;
}