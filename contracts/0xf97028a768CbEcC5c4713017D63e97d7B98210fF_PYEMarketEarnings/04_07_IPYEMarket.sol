// SPDX-License-Identifier: MIT LICENSE 

pragma solidity ^0.8.0;

interface IPYEMarket {
  function addManyToStakingPool(address account, uint16[] calldata tokenIds) external;
  function isOwner(uint16 tokenId, address owner) external view returns (bool);
  function getUnclaimedGenesis(uint16 tokenId) external view returns (uint256);
}