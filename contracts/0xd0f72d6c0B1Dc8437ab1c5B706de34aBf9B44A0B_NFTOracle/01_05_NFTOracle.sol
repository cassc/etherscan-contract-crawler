// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.11;

import {INFTOracle} from '../interfaces/INFTOracle.sol';
import {Ownable} from '../dependencies/openzeppelin/contracts/Ownable.sol';
import {Pausable} from '../dependencies/openzeppelin/contracts/Pausable.sol';

/**
 * @title NFTOracle
 * @author Vinci
 **/
contract NFTOracle is INFTOracle, Ownable, Pausable {

  // asset address
  mapping (address => uint256) private _addressIndexes;
  mapping (address => bool) private _emergencyAdmin;
  address[] private _addressList;
  address private _operator;

  // price
  struct Price {
    uint32 v1;
    uint32 v2;
    uint32 v3;
    uint32 v4;
    uint32 v5;
    uint32 v6;
    uint32 v7;
    uint32 ts;
  }
  Price private _price;
  uint256 private constant PRECISION = 1e18;
  uint256 public constant MAX_PRICE_DEVIATION = 15 * 1e16;  // 15%
  uint32 public constant MIN_UPDATE_TIME = 30 * 60; // 30 min

  event SetAssetData(uint32[7] prices);
  event ChangeOperator(address indexed oldOperator, address indexed newOperator);
  event SetEmergencyAdmin(address indexed admin, bool enabled);

  /// @notice Constructor
  /// @param assets The addresses of the assets
  constructor(address[] memory assets) {
    _operator = _msgSender();
    _addAssets(assets);
  }

  function _addAssets(address[] memory addresses) private {
    uint256 index = _addressList.length + 1;
    for (uint256 i = 0; i < addresses.length; i++) {
      address addr = addresses[i];
      if (_addressIndexes[addr] == 0) {
        _addressIndexes[addr] = index;
        _addressList.push(addr);
        index++;
      }
    }
  }

  function operator() external view returns (address) {
    return _operator;
  }

  function isEmergencyAdmin(address admin) external view returns (bool) {
    return _emergencyAdmin[admin];
  }

  function getAddressList() external view returns (address[] memory) {
    return _addressList;
  }

  function getIndex(address asset) external view returns (uint256) {
    return _addressIndexes[asset];
  }

  function addAssets(address[] memory assets) external onlyOwner {
    require(assets.length > 0);
    _addAssets(assets);
  }

  function setPause(bool val) external {
    require(_emergencyAdmin[_msgSender()], "NFTOracle: caller is not the emergencyAdmin");
    if (val) {
      _pause();
    } else {
      _unpause();
    }
  }

  function setOperator(address newOperator) external onlyOwner {
    require(newOperator != address(0), 'NFTOracle: invalid operator');
    address oldOperator = _operator;
    _operator = newOperator;
    emit ChangeOperator(oldOperator, newOperator);
  }

  function setEmergencyAdmin(address admin, bool enabled) external onlyOwner {
    require(admin != address(0), 'NFTOracle: invalid admin');
    _emergencyAdmin[admin] = enabled;
    emit SetEmergencyAdmin(admin, enabled);
  }

  function _getPriceByIndex(uint256 index) private view returns(uint256) {
    Price memory cachePrice = _price;
    if (index == 1) {
      return cachePrice.v1;
    } else if (index == 2) {
      return cachePrice.v2;
    } else if (index == 3) {
      return cachePrice.v3;
    } else if (index == 4) {
      return cachePrice.v4;
    } else if (index == 5) {
      return cachePrice.v5;
    } else if (index == 6) {
      return cachePrice.v6;
    } else if (index == 7) {
      return cachePrice.v7;
    } else {
      return 0;
    }
  }

  function getLatestTimestamp() external view returns (uint256) {
    return uint256(_price.ts);
  }

  // return in Wei
  function getAssetPrice(address asset) external view returns (uint256) {
    uint256 price = _getPriceByIndex(_addressIndexes[asset]);
    return price * 1e14;
  }

  function getNewPrice(
    uint256 latestPrice,
    uint256 currentPrice
  ) private pure returns (uint256) {

    if (latestPrice == 0) {
      return currentPrice;
    }

    if (currentPrice == 0 || currentPrice == latestPrice) {
      return latestPrice;
    }

    uint256 percentDeviation;
    if (latestPrice > currentPrice) {
      percentDeviation = ((latestPrice - currentPrice) * PRECISION) / latestPrice;
    } else {
      percentDeviation = ((currentPrice - latestPrice) * PRECISION) / latestPrice;
    }

    if (percentDeviation > MAX_PRICE_DEVIATION) {
      return latestPrice;
    }
    return currentPrice;
  }

  // set with 1e4
  function batchSetAssetPrice(uint256[7] memory prices) external whenNotPaused {
    require(_operator == _msgSender(), "NFTOracle: caller is not the operator");
    Price storage cachePrice = _price;
    uint32 currentTimestamp = uint32(block.timestamp);
    if ((currentTimestamp - cachePrice.ts) >= MIN_UPDATE_TIME) {
      uint32[7] memory newPrices = [
        uint32(getNewPrice(cachePrice.v1, prices[0])),
        uint32(getNewPrice(cachePrice.v2, prices[1])),
        uint32(getNewPrice(cachePrice.v3, prices[2])),
        uint32(getNewPrice(cachePrice.v4, prices[3])),
        uint32(getNewPrice(cachePrice.v5, prices[4])),
        uint32(getNewPrice(cachePrice.v6, prices[5])),
        uint32(getNewPrice(cachePrice.v7, prices[6]))
      ];

      cachePrice.v1 = newPrices[0];
      cachePrice.v2 = newPrices[1];
      cachePrice.v3 = newPrices[2];
      cachePrice.v4 = newPrices[3];
      cachePrice.v5 = newPrices[4];
      cachePrice.v6 = newPrices[5];
      cachePrice.v7 = newPrices[6];
      cachePrice.ts = currentTimestamp;

      emit SetAssetData(newPrices);
    }
  }
}