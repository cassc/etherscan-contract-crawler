// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IStakingRewards {
    function balanceOf(address account) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function exit() external;

    function stake(uint256 amount) external;
    function invest(uint256 _deadline) external;
    function buyBack(uint256 _deadline) external;
    function hedgeToStable(uint256 _deadline) external;

    event Invested(uint256 amount, uint256 balance);
    event BuyBack(uint256 amount,uint256 rewards);
    event Hedged(uint256 amount);
}