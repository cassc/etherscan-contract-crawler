// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './StakingPool.sol';

contract HookableStakingPool is StakingPool {
  address public hookAddress;

  constructor(address tokenAddress) StakingPool(tokenAddress) {}

  function setHookAddress(address hookAddress_) external onlyOwner {
    hookAddress = hookAddress_;
  }

  function _beforeStake(uint256 tokenId, address owner)
    internal
    virtual
    override
  {
    if (hookAddress != address(0)) {
      StakingHook(hookAddress).onStake(tokenId, owner);
    }
  }

  function _beforeUnstake(uint256 tokenId, address owner)
    internal
    virtual
    override
  {
    if (hookAddress != address(0)) {
      StakingHook(hookAddress).onUnstake(tokenId, owner);
    }
  }
}

interface StakingHook {
  function onStake(uint256 tokenId, address owner) external;

  function onUnstake(uint256 tokenId, address owner) external;
}