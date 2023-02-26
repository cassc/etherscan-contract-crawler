// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface ILlpRewardDistributor {
    function withdrawableTokens(address _token) external view returns (bool);

    function rewardsPerSecond() external view returns (uint256);

    function transferRewards(address _to, uint256 _amount) external;

    function transferRewardsToSingleToken(address _to, uint256 _amount, address _tokenOut, uint256 _minAmountOut)
        external;

    function rewardToken() external view returns (address);

    function swap(address _fromToken, address _toToken, uint256 _amountIn, uint256 _minAmountOut) external;

    function convertToLlp(address _token, uint256 _amount, uint256 _minLlpAmount) external;

    function setRewardsPerSecond(uint256 _rewardsPerSecond) external;

    function requester() external view returns (address);
}