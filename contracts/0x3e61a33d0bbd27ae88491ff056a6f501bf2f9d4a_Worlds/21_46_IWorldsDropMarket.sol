// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.18;

interface IWorldsDropMarket {
  function addToWorldByCollection(uint256 worldId, address nftContract, uint16 takeRateInBasisPoints) external;

  function getAssociationByCollection(
    address nftContract,
    address seller
  ) external view returns (uint256 worldId, uint16 takeRateInBasisPoints);

  function soldInWorldByCollection(
    address seller,
    address nftContract,
    uint256 count,
    uint256 totalSalePrice
  ) external returns (uint256 worldId, address payable paymentAddress, uint16 takeRateInBasisPoints);
}