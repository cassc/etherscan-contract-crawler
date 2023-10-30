// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.18;

interface INFTMarketExhibitionMigration {
  struct NFTListing {
    address nftContract;
    uint256 nftTokenId;
  }

  function worldsInitializeMigration() external returns (uint256 lastExhibitionIdCreated);

  function worldsMigrateExhibition(
    uint256 exhibitionId,
    address curator
  ) external returns (string memory name, uint16 takeRateInBasisPoints);

  function worldsMigrateExhibitionListings(
    uint256 exhibitionId,
    INFTMarketExhibitionMigration.NFTListing[] calldata nftListings
  ) external returns (address[] memory nftSellers);
}