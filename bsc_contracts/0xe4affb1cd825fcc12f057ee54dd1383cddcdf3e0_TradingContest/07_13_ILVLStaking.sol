// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface ILVLStaking {
    function userInfo(address _user) external view returns (uint256, uint256);
    function rewardsPerSecond() external view returns (uint256);
    function swap(address _fromToken, address _toToken, uint256 _amountIn, uint256 _minAmountOut) external;
    function convert(address _token, uint256 _amount, uint256 _minLlpAmount) external;
    function setRewardsPerSecond(uint256 _rewardsPerSecond) external;
}