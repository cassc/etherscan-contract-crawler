// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IMasterChefRewarder {
  function onSushiReward(
    uint256 pid,
    address user,
    address recipient,
    uint256 sushiAmount,
    uint256 newLpAmount
  ) external;

  function pendingTokens(
    uint256 pid,
    address user,
    uint256 sushiAmount
  ) external view returns (IERC20[] memory, uint256[] memory);
}