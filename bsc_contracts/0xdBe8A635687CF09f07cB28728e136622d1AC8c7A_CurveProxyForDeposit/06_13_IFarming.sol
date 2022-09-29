// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import { IStrategy } from "./IStrategy.sol";
import { IERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

interface IFarming {
  function poolInfo(uint256 pid)
    external
    view
    returns (
      IERC20Upgradeable,
      IStrategy,
      uint256,
      uint256,
      uint256
    );

  function addPool(
    address token,
    address strategy,
    bool withUpdate
  ) external returns (uint256);

  function rewardToken() external returns (IERC20Upgradeable);

  function deposit(
    uint256 pid,
    uint256 wantAmt,
    bool claimRewards,
    address userAddress
  ) external returns (uint256);

  function withdraw(
    uint256 pid,
    uint256 wantAmt,
    bool claimRewards
  ) external returns (uint256);

  function claim(address user, uint256[] calldata pids) external returns (uint256);
}