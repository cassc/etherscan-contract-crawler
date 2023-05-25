// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

import "synthetix/contracts/interfaces/IStakingRewards.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

contract EarnedAggregator {
  /// @notice The address of the Float Protocol Timelock
  address public timelock;

  /// @notice addresses of pools (Staking Rewards Contracts)
  address[] public pools;

  constructor(address timelock_, address[] memory pools_) {
    timelock = timelock_;
    pools = pools_;
  }

  function getPools() public view returns (address[] memory) {
    address[] memory pls = pools;
    return pls;
  }

  function addPool(address pool) public {
    // Sanity check for function and no error
    IStakingRewards(pool).earned(timelock);

    for (uint256 i = 0; i < pools.length; i++) {
      require(pools[i] != pool, "already added");
    }

    require(msg.sender == address(timelock), "EarnedAggregator: !timelock");
    pools.push(pool);
  }

  function removePool(uint256 index) public {
    require(msg.sender == address(timelock), "EarnedAggregator: !timelock");
    if (index >= pools.length) return;

    if (index != pools.length - 1) {
      pools[index] = pools[pools.length - 1];
    }

    pools.pop();
  }

  function getCurrentEarned(address account) public view returns (uint256) {
    uint256 votes = 0;
    for (uint256 i = 0; i < pools.length; i++) {
      // get tokens earned for staking
      votes = SafeMath.add(votes, IStakingRewards(pools[i]).earned(account));
    }
    return votes;
  }
}