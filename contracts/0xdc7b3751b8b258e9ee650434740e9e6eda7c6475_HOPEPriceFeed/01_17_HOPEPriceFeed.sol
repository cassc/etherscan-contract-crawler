// SPDX-License-Identifier: LGPL-3.0
pragma solidity 0.8.17;

import {HopeOneRole} from '../access/HopeOneRole.sol';
import {AggregatorV2V3Interface} from '../dependencies/chainlink/AggregatorV2V3Interface.sol';
import {IHOPE} from '../interfaces/IHOPE.sol';
import {IHOPEPriceFeed} from '../interfaces/IHOPEPriceFeed.sol';

contract HOPEPriceFeed is HopeOneRole, IHOPEPriceFeed {
  uint256 private constant K_FACTOR = 1e20;
  uint256 private constant PRICE_SCALE = 1e8;
  uint256 public immutable K; // 1080180484347501
  address public immutable ETH_ADDRESS; // 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE
  address public immutable BTC_ADDRESS; // 0xbBbBBBBbbBBBbbbBbbBbbbbBBbBbbbbBbBbbBBbB
  address public immutable HOPE_ADDRESS; // 0xc353Bf07405304AeaB75F4C2Fac7E88D6A68f98e

  struct TokenConfig {
    AggregatorV2V3Interface priceFeed;
    uint256 factor;
    bool isExist;
  }
  address[] private reserveTokens;
  mapping(address => TokenConfig) private reserveTokenConfigs;

  event ReserveUpdate(address[] tokens, address[] priceFeed, uint256[] factors);

  constructor(address _ethMaskAddress, address _btcMaskAddress, address _hopeAddress, uint256 _k) {
    ETH_ADDRESS = _ethMaskAddress;
    BTC_ADDRESS = _btcMaskAddress;
    HOPE_ADDRESS = _hopeAddress;
    K = _k;
  }

  function setReserveTokens(
    address[] memory tokens,
    address[] memory priceFeeds,
    uint256[] memory factors
  ) external onlyRole(OPERATOR_ROLE) {
    require(tokens.length == priceFeeds.length, 'HOPEPriceFeeds: Invalid input');
    require(tokens.length == factors.length, 'HOPEPriceFeeds: Invalid input');

    for (uint256 i = 0; i < tokens.length; i++) {
      if (!reserveTokenConfigs[tokens[i]].isExist) {
        reserveTokens.push(tokens[i]);
      }
      reserveTokenConfigs[tokens[i]] = TokenConfig(AggregatorV2V3Interface(priceFeeds[i]), factors[i], true);
    }

    emit ReserveUpdate(tokens, priceFeeds, factors);
  }

  function latestAnswer() external view override returns (uint256) {
    uint256 hopeSupply = getHOPETotalSupply();
    uint256 reserveTotalValue;
    uint256 hopePrice;

    unchecked {
      for (uint256 i = 0; i < reserveTokens.length; i++) {
        TokenConfig memory config = reserveTokenConfigs[reserveTokens[i]];
        uint256 reserveInToken = _calculateReserveAmount(hopeSupply, config);
        uint256 reserveValueInToken = _calculateReserveValue(reserveInToken, config);
        reserveTotalValue += reserveValueInToken;
      }

      hopePrice = reserveTotalValue / hopeSupply;
    }

    if (hopePrice >= PRICE_SCALE) return PRICE_SCALE;
    return hopePrice;
  }

  function _calculateReserveAmount(uint256 hopeSupply, TokenConfig memory config) internal view returns (uint256) {
    unchecked {
      uint256 reserveAmount = (hopeSupply * K * config.factor) / K_FACTOR;
      return reserveAmount;
    }
  }

  function _calculateReserveValue(uint256 reserveAmount, TokenConfig memory config) internal view returns (uint256) {
    uint256 reservePrice = uint256(config.priceFeed.latestAnswer());
    uint256 reserveDecimals = uint256(config.priceFeed.decimals());
    unchecked {
      uint256 reserveValue = (reserveAmount * reservePrice * PRICE_SCALE) / (10 ** reserveDecimals);
      return reserveValue;
    }
  }

  function getReservePrice(address token) external view returns (uint256) {
    TokenConfig memory config = reserveTokenConfigs[token];
    return uint256(config.priceFeed.latestAnswer());
  }

  function getHOPETotalSupply() public view returns (uint256) {
    return IHOPE(HOPE_ADDRESS).totalSupply();
  }

  function getReserveTokens() external view returns (address[] memory) {
    return reserveTokens;
  }

  function getReserveTokenConfig(address token) external view returns (address, uint256, bool) {
    TokenConfig memory config = reserveTokenConfigs[token];
    return (address(config.priceFeed), config.factor, config.isExist);
  }
}