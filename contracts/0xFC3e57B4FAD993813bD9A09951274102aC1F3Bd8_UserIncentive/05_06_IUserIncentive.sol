// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IUserIncentive {
    event RewardClaimed(address _rewardToken, address indexed _address);

    // This will be called by the Strategy to claim rewards for the user
    // This should be permissioned such that only the Strategy address can call
    function claimReward(uint256 _fERC20Burned, address _yieldTo) external;

    // This is a view function to determine how many reward tokens will be paid out
    // providing ??? fERC20 tokens are burned
    function quoteReward(uint256 _fERC20Burned) external view returns (uint256);

    // Administrator: setting the reward ratio
    function setRewardRatio(uint256 _ratio) external;

    // Administrator: adding the reward tokens
    function addRewardTokens(uint256 _tokenAmount) external;

    // Administrator: depositing the reward tokens
    function depositReward(
        address _rewardTokenAddress,
        uint256 _tokenAmount,
        uint256 _ratio
    ) external;
}