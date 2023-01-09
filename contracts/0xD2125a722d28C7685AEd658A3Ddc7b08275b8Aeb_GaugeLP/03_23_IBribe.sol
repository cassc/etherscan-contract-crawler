// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {IRegistry} from "./IRegistry.sol";

interface IBribe {
  function registry() external view returns (IRegistry);

  function notifyRewardAmount(address token, uint256 amount) external;

  function left(address token) external view returns (uint256);

  function _deposit(uint256 amount, uint256 tokenId) external;

  function _withdraw(uint256 amount, uint256 tokenId) external;

  function getRewardForOwner(uint256 tokenId, address[] memory tokens) external;

  event Deposit(address indexed from, uint256 tokenId, uint256 amount);
  event Withdraw(address indexed from, uint256 tokenId, uint256 amount);
  event NotifyReward(
    address indexed from,
    address indexed reward,
    uint256 amount
  );
  event ClaimRewards(
    address indexed from,
    address indexed reward,
    uint256 amount
  );
}