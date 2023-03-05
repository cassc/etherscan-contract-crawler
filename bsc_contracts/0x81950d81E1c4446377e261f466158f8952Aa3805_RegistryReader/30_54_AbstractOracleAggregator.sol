// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.17;

import "./IOracleProvider.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableMap.sol";

abstract contract AbstractOracleAggregator is Ownable, IOracleProvider {
  using EnumerableMap for EnumerableMap.AddressToUintMap;

  uint256 public checkThreshold;

  mapping(bytes32 => IOracleProvider[]) public oracleProvidersPerPriceId;

  // priceId => cachedPrice
  mapping(bytes32 => PricePackage) internal _cachedPricePerPriceId;

  // UGP related variables
  EnumerableMap.AddressToUintMap internal _ugpDiscount;

  event AddOracleProviderEvent(bytes32 priceId, address oracleProvider);
  event SetCheckThresholdEvent(uint256 checkThreshold);
  event SetUGPDiscountEvent(address ugpAddress, uint256 ugpDiscount);

  constructor(address owner) {
    _transferOwnership(owner);
    checkThreshold = type(uint256).max;
  }

  // governance functions

  function setCheckThreshold(uint256 _checkThreshold) external onlyOwner {
    checkThreshold = _checkThreshold;
    emit SetCheckThresholdEvent(checkThreshold);
  }

  function addOracleProviderPerPriceId(
    bytes32 priceId,
    IOracleProvider oracleProvider
  ) external onlyOwner {
    oracleProvidersPerPriceId[priceId].push(oracleProvider);
    emit AddOracleProviderEvent(priceId, address(oracleProvider));
  }

  function setUGPDiscount(
    address ugpAddress,
    uint256 ugpDiscount
  ) external onlyOwner {
    _ugpDiscount.set(ugpAddress, ugpDiscount);
    emit SetUGPDiscountEvent(ugpAddress, ugpDiscount);
  }

  // external functions

  function cachedPricePerPriceId(
    bytes32 priceId
  ) external view returns (PricePackage memory) {
    return _cachedPricePerPriceId[priceId];
  }

  function getUGPDiscount(address ugpAddress) external view returns (uint256) {
    return _ugpDiscount.get(ugpAddress);
  }

  function getLatestPrice(
    bytes32 priceId
  ) external view returns (PricePackage memory) {
    return _cachedPricePerPriceId[priceId];
  }

  function parsePriceFeed(
    address user,
    bytes32 priceId,
    bytes[] memory updateData
  ) external view virtual returns (PricePackage memory);

  function getUpdateFee(
    uint256 updateDataSize
  ) external view virtual returns (uint256 feeAmount);

  function updatePriceFeeds(
    bytes[] memory priceData,
    bytes32[] memory priceIds,
    uint256 updateFee
  ) external payable virtual;

  function updateLatestPrice(
    address user,
    bytes32 priceId,
    bytes[] calldata priceData,
    uint256 updateFee
  ) external payable virtual returns (PricePackage memory);

  // internal functions

  // TODO: check publishTime
  function _checkPrice(
    bytes32 priceId
  ) internal view returns (uint256 askPrice, uint256 bidPrice) {
    IOracleProvider[] storage providers = oracleProvidersPerPriceId[priceId];
    uint256 size = providers.length;
    if (size < checkThreshold) {
      askPrice = 0;
      bidPrice = 0;
    } else {
      uint256[] memory askPrices = new uint256[](size);
      uint256[] memory bidPrices = new uint256[](size);
      for (uint256 i = 0; i < size; ++i) {
        askPrices[i] = providers[i].getLatestPrice(priceId).ask;
        bidPrices[i] = providers[i].getLatestPrice(priceId).bid;
      }

      uint256[] memory sortedAskPrices = sort(askPrices);
      askPrice = size % 2 == 1
        ? sortedAskPrices[(size - 1) / 2]
        : (sortedAskPrices[size / 2 - 1] + sortedAskPrices[size / 2]) / 2;

      uint256[] memory sortedBidPrices = sort(bidPrices);
      bidPrice = size % 2 == 1
        ? sortedBidPrices[(size - 1) / 2]
        : (sortedBidPrices[size / 2 - 1] + sortedBidPrices[size / 2]) / 2;
    }
  }

  function abs(int256 x) internal pure returns (uint256) {
    return x >= 0 ? uint256(x) : uint256(-x);
  }

  function sort(uint256[] memory arr) internal pure returns (uint256[] memory) {
    uint256 l = arr.length;
    for (uint256 i = 0; i < l; ++i) {
      for (uint256 j = i + 1; j < l; j++) {
        if (arr[i] > arr[j]) {
          uint256 temp = arr[i];
          arr[i] = arr[j];
          arr[j] = temp;
        }
      }
    }
    return arr;
  }
}