// SPDX-License-Identifier: MIT
//pragma solidity ^0.6.12;
pragma solidity >=0.6.0;

interface StrongNFTBonusInterface {
  function getBonus(address _entity, uint128 _nodeId, uint256 _from, uint256 _to) external view returns (uint256);

  function getBonusValue(address _entity, uint128 _nodeId, uint256 _from, uint256 _to, uint256 _bonusValue) external view returns (uint256);

  function getStakedNftBonusName(address _entity, uint128 _nodeId, address _serviceContract) external view returns (string memory);

  function migrateNFT(address _entity, uint128 _fromNodeId, uint128 _toNodeId, address _toServiceContract) external;

  function unstakeNFT(address _entity, uint128 _nodeId, address _serviceContract) external;
}