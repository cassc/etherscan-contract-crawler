// SPDX-License-Identifier: MIT LICENSE 

pragma solidity ^0.8.0;

interface ITrainingGrounds {
  function addManyToTowerAndFlight(address tokenOwner, uint16[] calldata tokenIds) external;
  function claimManyFromTowerAndFlight(address tokenOwner, uint16[] calldata tokenIds, bool unstake) external;
  function addManyToTrainingAndFlight(uint256 seed, address tokenOwner, uint16[] calldata tokenIds) external;
  function claimManyFromTrainingAndFlight(uint256 seed, address tokenOwner, uint16[] calldata tokenIds, bool unstake) external;
  function randomDragonOwner(uint256 seed) external view returns (address);
  function isTokenStaked(uint256 tokenId, bool isTraining) external view returns (bool);
}