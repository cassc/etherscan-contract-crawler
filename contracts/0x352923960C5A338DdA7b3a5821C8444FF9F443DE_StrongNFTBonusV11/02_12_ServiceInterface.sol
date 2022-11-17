// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

interface ServiceInterface {
  function claimingFeeNumerator() external view returns(uint256);

  function claimingFeeDenominator() external view returns(uint256);

  function doesNodeExist(address entity, uint128 nodeId) external view returns (bool);

  function getNodeId(address entity, uint128 nodeId) external view returns (bytes memory);

  function getReward(address entity, uint128 nodeId) external view returns (uint256);

  function getRewardByBlock(address entity, uint128 nodeId, uint256 blockNumber) external view returns (uint256);

  function hasNodeExpired(address _entity, uint _nodeId) external view returns (bool);

  function isEntityActive(address entity) external view returns (bool);

  function claim(uint128 nodeId, uint256 blockNumber, bool toStrongPool) external payable returns (uint256);
}