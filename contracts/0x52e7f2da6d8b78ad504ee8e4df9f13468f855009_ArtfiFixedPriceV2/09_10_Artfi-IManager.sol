// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

enum ContractType {
  ARTFI_V2,
  UNSUPPORTED
}

struct CalculatePayout {
  uint256 tokenId;
  address contractAddress;
  address seller;
  uint256 price;
  uint256 quantity;
}

struct LazyMintSellData {
  address tokenAddress;
  string uri;
  address seller;
  address buyer;
  string uid;
  uint256 fractionId;
  address[] creators;
  uint256[] royalties;
  uint256 minPrice;
  uint256 quantity;
  bytes signature;
  string currency;
}

struct OnlyWhiteListed {
  address tokenAddress;
  uint256 startDate;
}

struct CryptoTokens {
  address tokenAddress;
  uint256 tokenValue;
  bool isEnabled;
}

struct ArtfiCollection {
  address contractAddress;
  address owner;
}

interface ArtfiIManager {

  function isAdmin(address caller_) external view returns (bool);

  function isPauser(address caller_) external view returns (bool);

  function isBlocked(address caller_) external view returns (bool);

  function isPaused() external view returns (bool);

  // function serviceFeeWallet() external view returns (address);

  // function serviceFeePercent() external view returns (uint256);

  function addArtfiCollection(address collectionAddress, address owner) external;

  function getTokenDetail(
    string memory tokenName_
  ) external view returns (CryptoTokens memory cryptoToken_);

  function tokenExist(
    string memory tokenName_
  ) external view returns (bool tokenExist_);

  function verifyFixedPriceLazyMintV2(
    LazyMintSellData memory lazyData_
  ) external returns (address, bytes32);

  function getContractDetails(
    address contractAddress_
  ) external returns (ContractType contractType_, bool isERC1155_);

  function isOwnerOfNFT(
    address address_,
    uint256 tokenId_,
    address contractAddress_
  )
    external
    returns (ContractType contractType_, bool isOwner_);

  function calculatePayout(
    CalculatePayout memory calculatePayout_
  )
    external
    returns (
      address[] memory recepientAddresses_,
      uint256[] memory paymentAmount_,
      bool isTokenTransferable_,
      bool isOwner_
    );
}