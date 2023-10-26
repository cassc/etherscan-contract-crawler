//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/**
 * @title Interface for Auction Houses
 */
interface ISlothMintV2 {
  event mintWithCloth(
    uint256 quantity
  );
  event mintWithClothAndItem(
    uint256 quantity,
    uint256 itemQuantity,
    bool piement
  );
  event mintWithClothAndPoupelle(
    uint256 quantity,
    bool piement
  );
  event mintPoupelle(
    uint256 quantity
  );
  event mintItem(
    uint256 quantity
  );
  event mintWithClothAndCollabo(
    uint256 quantity,
    uint256 specialType,
    bool piement
  );
  event mintCollabo(
    uint256 quantity,
    uint256 specialType
  );
}