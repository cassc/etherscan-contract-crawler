// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IBridge {
    function unstake(
        address handler,
        address tokenAddress,
        uint256 amount
    ) external;

    function stake(
        address handler,
        address tokenAddress,
        uint256 amount
    ) external;

    function unstakeETH(address handler, uint256 amount) external;

    function stakeETH(address handler) external payable;
}