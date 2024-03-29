// SPDX-License-Identifier: MIT

pragma solidity >=0.8.1;

/**
 * @dev OnChain Staking interface
 */
interface IOnChainStakingPool {

    event Staked(address indexed token, address indexed staker_, uint256 requestedAmount_, uint256 stakedAmount_);

    event PaidOut(address indexed token, address indexed rewardToken, address indexed staker_, uint256 amount_, uint256 reward_);

    function stake(uint256 amount) external returns (bool);

    function stakeFor(address staker, uint256 amount) external returns (bool);

    function stakeForMultiple(address[] calldata stakers, uint256[] calldata amounts) external returns (bool);

    function stakeOf(address account) external view returns (uint256);

    function tokenAddress() external view returns (address);

    function stakedTotal() external view returns (uint256);

    function stakedBalance() external view returns (uint256);

    function stakingStarts() external view returns (uint256);

    function stakingEnds() external view returns (uint256);
}