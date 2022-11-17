// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface StrongNFTBonusLegacyInterface {
  function getBonus(address _entity, uint128 _nodeId, uint256 _fromBlock, uint256 _toBlock) external view returns (uint256);

  function getStakedNftId(address _entity, uint128 _nodeId) external view returns (uint256);

  function isNftStaked(uint256 _nftId) external view returns (bool);
}