// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";

import "./inc/MTMLibrary.sol";
import "./inc/UniswapV3.sol";
import "./inc/UniswapV2.sol";

abstract contract MShareCalculable is UniswapV3, UniswapV2 {
  using { MTMLibrary.isStable, MTMLibrary.isEther, MTMLibrary.decimals } for address;
  mapping(address => MTMLibrary.Pool) public availableTokens;

  uint public constant MSHARE_DECIMALS = 6;
  uint internal immutable MSHARE_RESOLUTION;
  uint public immutable MPOINT_RATE;
  uint public immutable MPOINT_RATE_PER_USD;

  error TokenIsNotAvailableForMTM(address token);

  constructor() {

    MSHARE_RESOLUTION = 10 ** MSHARE_DECIMALS;

    // MPOINT_RATE == $1
    MPOINT_RATE = 1 * MSHARE_RESOLUTION;

    MPOINT_RATE_PER_USD = MSHARE_RESOLUTION / MPOINT_RATE;

    // Setup the token lookup map;
    // Loop through all pools, set their corresponding tokens to the pools for lookup
    uint poolsLength = MTMLibrary.availablePools().length;
    for(uint i; i < poolsLength;) {
      MTMLibrary.Pool memory pool = MTMLibrary.availablePools()[i];

      address token = _getTokenAddressFromPair(pool);

      availableTokens[token] = pool;

      unchecked {
        i++;
      }
    }
  }

  // @dev Determine if token is available for minting M-Shares
  function isTokenAvailableForMTM(address token) public view returns(bool) {
    if(token == address(0)) {
      return true;
    }

    return
      availableTokens[token].poolAddress != address(0) ||
      token.isStable() ||
      token.isEther();
  }

  // @dev return the token price within their respective pool
  // @returns token price
  function _tokenToUSDPrice(address token, uint amount) internal view returns(uint) {
    uint usdPrice;

    // If token is a stable coin, it's price is always 1 (at least for MTMs)
    if(token.isStable()) {

      usdPrice = (amount * MSHARE_RESOLUTION) / (10 ** token.decimals());

    } else if(token.isEther()) {

      usdPrice = (etherV3Price() * amount) / 1e18;

    } else {

      MTMLibrary.Pool storage pool = availableTokens[token];

      usdPrice = _getUSDPrice(pool, amount) / (10 ** token.decimals());

    }

    return usdPrice;
  }

  function _getTokenAddressFromPair(MTMLibrary.Pool memory pool) private view returns(address) {
    if(pool.isV2) {
      return getV2TokenAddressFromPair(pool.poolAddress);
    } else {
      return getV3TokenAddressFromPair(pool.poolAddress);
    }
  }

  function _getUSDPrice(MTMLibrary.Pool memory pool, uint amount) private view returns(uint) {
    if(pool.isV2) {
      return getV2TokenPrice(pool.poolAddress, amount);
    } else {
      return getV3TokenPrice(pool.poolAddress, amount);
    }
  }
}