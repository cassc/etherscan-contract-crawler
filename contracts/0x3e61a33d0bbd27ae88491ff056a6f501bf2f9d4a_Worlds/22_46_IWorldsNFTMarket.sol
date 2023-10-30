// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.18;

interface IWorldsNFTMarket {
  ////////////////////////////////////////////////////////////////
  // World management
  ////////////////////////////////////////////////////////////////

  function mint(
    uint16 defaultTakeRateInBasisPoints,
    address payable paymentAddress,
    string calldata name
  ) external returns (uint256 worldId);

  function burn(uint256 worldId) external;

  ////////////////////////////////////////////////////////////////
  // Allowlist
  ////////////////////////////////////////////////////////////////

  function addToAllowlistBySeller(uint256 worldId, address seller) external;

  function isSellerAllowed(uint256 worldId, address seller) external view returns (bool isAllowed);

  ////////////////////////////////////////////////////////////////
  // NFT specific
  ////////////////////////////////////////////////////////////////

  function addToWorldByNft(
    uint256 worldId,
    address nftContract,
    uint256 nftTokenId,
    uint16 takeRateInBasisPoints
  ) external;

  function getAssociationByNft(
    address nftContract,
    uint256 nftTokenId,
    address seller
  ) external view returns (uint256 worldId, uint16 takeRateInBasisPoints);

  function removeFromWorldByNft(address nftContract, uint256 nftTokenId) external;

  function soldInWorldByNft(
    address seller,
    address nftContract,
    uint256 nftTokenId,
    address buyer,
    uint256 salePrice
  ) external returns (uint256 worldId, address payable paymentAddress, uint16 takeRateInBasisPoints);
}