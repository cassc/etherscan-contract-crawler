// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IUserIncentiveV3 {
    event RewardClaimed(address _rewardToken, address indexed _claimer);
    event RewardsUpdated(address[] _rewardToken, uint256[] _rewardRatios);

    // This will be called by the Strategy to claim rewards for the user
    // This should be permissioned such that only the Strategy address can call
    function claimReward(uint256 _fERC20Burned, address _yieldTo) external;

    // This is a view function to determine how many reward tokens will be paid out
    // providing ??? fERC20 tokens are burned
    function quoteRewards(uint256 _fERC20Burned) external view returns (uint256[] memory);
}