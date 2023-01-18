//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

struct StakeInfo{
  uint16 tokenId;
  uint32 accrued;
  uint32 pending;
  bool isStaked;
}

interface IStakingProvider {
  function baseAward() external view returns(uint32);
  function getRewardHandler() external view returns(address);
  function getStakeInfo(uint16[] calldata tokenIds) external view returns(StakeInfo[] memory infos);
  function isStakeable() external view returns(bool);
  function ownerOfAll(uint16[] calldata tokenIds) external view returns(address[] memory);
}