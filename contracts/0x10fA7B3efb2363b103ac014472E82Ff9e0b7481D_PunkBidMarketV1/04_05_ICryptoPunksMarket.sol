// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

interface ICryptoPunksMarket {
  struct Offer {
    bool isForSale;
    uint256 punkIndex;
    address seller;
    uint256 minValue;
    address onlySellTo;
  }

  function punksOfferedForSale(
    uint256 punkIndex
  ) external returns (Offer memory offer);

  function buyPunk(uint256 punkIndex) external payable;

  function offerPunkForSaleToAddress(uint256 punkIndex, uint256 minSalePriceInWei, address toAddress) external;

  function transferPunk(address to, uint256 punkIndex) external;

  function punkIndexToAddress(uint256) external returns (address);
}