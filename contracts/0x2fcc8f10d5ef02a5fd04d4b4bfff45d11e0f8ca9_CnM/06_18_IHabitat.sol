// SPDX-License-Identifier: MIT LICENSE 

pragma solidity ^0.8.0;

interface IHabitat {
  function addManyToStakingPool(address account, uint16[] calldata tokenIds) external;
  function addManyHouseToStakingPool(address account, uint16[] calldata tokenIds) external;
  function randomCatOwner(uint256 seed) external view returns (address);
  function randomCrazyCatOwner(uint256 seed) external view returns (address);
  function isOwner(uint256 tokenId, address owner) external view returns (bool);
}