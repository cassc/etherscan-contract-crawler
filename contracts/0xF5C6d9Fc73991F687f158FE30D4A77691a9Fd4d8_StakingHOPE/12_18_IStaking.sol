// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IStaking {
    event Staking(address indexed user, uint256 amount);
    event Unstaking(address indexed user, uint256 amount);
    event Redeem(address indexed user, uint256 amount);
    event RewardsAccrued(address user, uint256 amount);
    event RewardsClaimed(address indexed user, uint256 amount);

    function staking(uint256 amount, uint256 nonce, uint256 deadline, bytes memory signature) external returns (bool);

    function redeemAll() external returns (uint256);
}