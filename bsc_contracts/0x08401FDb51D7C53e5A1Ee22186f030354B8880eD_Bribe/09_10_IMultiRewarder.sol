// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.5;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface IMultiRewarder {
    function onReward(address _user, uint256 _lpAmount) external returns (uint256[] memory rewards);

    function pendingTokens(address _user) external view returns (uint256[] memory rewards);

    function rewardTokens() external view returns (IERC20[] memory tokens);

    function rewardLength() external view returns (uint256);
}