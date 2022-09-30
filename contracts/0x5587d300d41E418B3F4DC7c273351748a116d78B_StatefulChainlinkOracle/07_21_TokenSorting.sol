// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >0.6;

/**
 * @title TokenSorting library
 * @notice Provides functions to sort tokens easily
 */
library TokenSorting {
  /**
   * @notice Takes two tokens, and returns them sorted
   * @param _tokenA One of the tokens
   * @param _tokenB The other token
   * @return __tokenA The first of the tokens
   * @return __tokenB The second of the tokens
   */
  function sortTokens(address _tokenA, address _tokenB) internal pure returns (address __tokenA, address __tokenB) {
    (__tokenA, __tokenB) = _tokenA < _tokenB ? (_tokenA, _tokenB) : (_tokenB, _tokenA);
  }
}