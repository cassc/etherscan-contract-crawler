// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.18;

interface INFTDropMarketExhibitionMigration {
  function worldsMigrateExhibitionListings(
    uint256 exhibitionId,
    address[] calldata collectionListings
  ) external returns (address[] memory collectionSellers);
}