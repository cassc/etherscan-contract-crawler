// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface ArtfiIMarketplace {
  enum ContractType {
    ARTFI_V2,
    UNSUPPORTED
  }

  enum OfferState {
    OPEN,
    CANCELLED,
    ENDED
  }

  enum OfferType {
    SALE,
    AUCTION
  }

  struct Offer {
    uint256 tokenId;
    OfferType offerType;
    OfferState status;
    ContractType contractType;
  }

  struct MintData {
    address seller;
    address buyer;
    address tokenAddress;
    string uri;
    address[] creators;
    uint256[] royalties;
    uint256 quantity;
  }

  struct Payout {
    address currency;
    address[] refundAddresses;
    uint256[] refundAmounts;
  }

  function createSale(
    uint256 tokenId_,
    ContractType contractType_,
    OfferType offerType_
  ) external returns (uint256 offerId_);

  function endSale(uint256 offerId_, OfferState offerState_) external;

  function transferNFT(
    address from_,
    address to_,
    uint256 tokenId_,
    address tokenAddress_
  ) external;

  function getOfferStatus(
    uint256 offerId_
  ) external view returns (Offer memory offerDetails_);
}