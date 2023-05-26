// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './HookableStakingPool.sol';

contract NoundleStakingPool is HookableStakingPool {
  constructor(address tokenAddress) HookableStakingPool(tokenAddress) {}
}

contract CompanionStakingPool is HookableStakingPool {
  constructor(address tokenAddress) HookableStakingPool(tokenAddress) {}
}

contract EvilNoundleStakingPool is HookableStakingPool {
  constructor(address tokenAddress) HookableStakingPool(tokenAddress) {}
}