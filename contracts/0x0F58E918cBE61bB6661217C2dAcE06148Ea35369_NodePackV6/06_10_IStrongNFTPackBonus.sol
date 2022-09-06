// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface IStrongNFTPackBonus {
  function getBonus(address _entity, uint _packType, uint _from, uint _to) external view returns (uint);

  function setEntityPackBonusSaved(address _entity, uint _packType) external;

  function resetEntityPackBonusSaved(bytes memory _packId) external;
}