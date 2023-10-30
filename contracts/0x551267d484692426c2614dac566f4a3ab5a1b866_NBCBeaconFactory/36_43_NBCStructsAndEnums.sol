// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

struct Init721Params {
  uint256 maxSupply;
  address initSigner;
  string baseTokenURI;
  address royaltyAddress;
  uint96 royaltyAmount;
}

struct InitPresaleParams {
  uint32 stageIndex;
  uint80 price;
  uint32 maxSupply;
  uint32 amountMinted;
  uint32 startTime;
  uint32 endTime;
  uint16 maxPerWallet;
  bytes32 merkleRoot;
}

struct PresaleSettings {
  uint80 price;
  uint32 maxSupply;
  uint32 amountMinted;
  uint32 startTime;
  uint32 endTime;
  uint16 maxPerWallet;
  bytes32 merkleRoot;
}

struct StandardSaleSettings {
  uint80 price;
  uint32 startTime;
  uint32 endTime;
  uint16 maxPerWallet;
  uint16 maxPerTx;
}

struct DutchAuctionSettings {
  uint80 startPrice;
  uint80 restPrice;
  uint80 dropPrice;
  uint32 dropInterval;
  uint32 startTime;
  uint32 endTime;
  uint16 maxPerWallet;
  uint16 maxPerTx;
}

enum SaleMode {
  Standard,
  Auction
}

struct PaymentSplitterSettings {
  address[] payees;
  uint256[] shares;
}