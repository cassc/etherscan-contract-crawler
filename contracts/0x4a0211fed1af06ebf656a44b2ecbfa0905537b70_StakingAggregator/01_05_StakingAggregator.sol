// SPDX-License-Identifier: Business Source License 1.1
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/access/Ownable.sol';

import './IStaking.sol';
import './IStakingAggregator.sol';

contract StakingAggregator is IStakingAggregator, Ownable {
  IStaking[] public instances;
  mapping(address => IStaking) public assigned;

  function addInstance(IStaking instance) external onlyOwner {
    if (instance.getData().aggregator != address(this)) {
      revert StakingInvalidAggregatorAddress();
    }

    instances.push(instance);
  }

  function isAssigned(address sender) external view returns (bool) {
    return address(assigned[sender]) != address(0);
  }

  function increaseDeposit(uint256 instanceIndex, uint256 value) external {
    return _getStakingInstance(msg.sender, instanceIndex).increaseDeposit(msg.sender, value);
  }

  function withdrawDeposit(uint256 instanceIndex) external {
    _getStakingInstance(msg.sender, instanceIndex).withdrawDeposit(msg.sender);

    assigned[msg.sender] = IStaking(address(0));
  }

  function claim(uint256 instanceIndex) external {
    return _getStakingInstance(msg.sender, instanceIndex).claim(msg.sender);
  }

  function getInstances() external view returns (StakingInstanceData[] memory) {
    StakingInstanceData[] memory arr = new StakingInstanceData[](instances.length);

    for (uint256 i = 0; i < instances.length; i++) {
      arr[i] = StakingInstanceData({addr: address(instances[i]), data: instances[i].getData()});
    }

    return arr;
  }

  function _getStakingInstance(address sender, uint256 index) internal returns (IStaking) {
    if (address(assigned[sender]) != address(0)) return assigned[sender];

    assigned[sender] = instances[index];

    return instances[index];
  }
}