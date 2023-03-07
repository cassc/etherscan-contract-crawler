// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IHedgeStrategy {

    event Reward(uint256 amount);
    event PortfolioManagerUpdated(address value);

    event Stake(uint256 amount);
    event Unstake(uint256 amount, uint256 amountReceived);

    event BalanceHealthFactor(uint256 healthFactor);
    event SetHealthFactor(uint256 healthFactor);

    function stake(
        uint256 _amount // value for staking in USDC
    ) external;

    function unstake(
        uint256 _amount,
        address _to     // minimum expected value for unstaking in USDC
    ) external returns (uint256); // Real unstake value

    function netAssetValue() external view returns (uint256); // Return value in USDC - denominator 6

    function claimRewards(address to) external returns (uint256); // Return received amount in USDC - denominator 6

    function balance(uint256 balanceRatio) external; // Balancing aave health factor or position depends of ets

    function balancePosition() external; // Balancing position
}