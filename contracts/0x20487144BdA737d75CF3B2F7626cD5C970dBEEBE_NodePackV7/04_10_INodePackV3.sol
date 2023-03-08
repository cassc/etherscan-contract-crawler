// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

interface INodePackV3 {
  function doesPackExist(address entity, uint packId) external view returns (bool);

  function hasPackExpired(address entity, uint packId) external view returns (bool);

  function claim(uint packId, uint timestamp, address toStrongPool) external payable returns (uint);

//  function getBonusAt(address _entity, uint _packType, uint _timestamp) external view returns (uint);

  function getPackId(address _entity, uint _packType) external pure returns (bytes memory);

  function getEntityPackTotalNodeCount(address _entity, uint _packType) external view returns (uint);

  function getEntityPackActiveNodeCount(address _entity, uint _packType) external view returns (uint);

  function migrateNodes(address _entity, uint _nodeType, uint _nodeCount, uint _lastPaidAt, uint _rewardsDue, uint _totalClaimed) external returns (bool);

//  function addPackRewardDue(address _entity, uint _packType, uint _rewardDue) external;

  function updatePackState(address _entity, uint _packType) external;
}