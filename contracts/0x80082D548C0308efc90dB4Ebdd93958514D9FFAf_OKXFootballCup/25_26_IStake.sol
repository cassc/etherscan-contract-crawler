// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IStake {
    function deposit(address from, uint256 amount) external;

    function stakePrice() external returns (uint256);

    function depositETH(address from) external payable;

    function ethStakePrice() external returns (uint256);

    function unstake(address to, uint256 blockRate)
        external
        returns (uint256 unstakedAmount, uint256 unstakedETHAmount);
}