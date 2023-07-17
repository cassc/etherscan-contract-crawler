// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

interface IConverterRegistry {
  /*************************
   * Public View Functions *
   *************************/

  /// @notice Return the input token and output token for the route.
  /// @param route The encoding of the route.
  /// @return tokenIn The address of input token.
  /// @return tokenOut The address of output token.
  function getTokenPair(uint256 route) external view returns (address tokenIn, address tokenOut);

  /// @notice Return the address of converter for a specific pool type.
  /// @param poolType The type of converter.
  /// @return converter The address of converter.
  function getConverter(uint256 poolType) external view returns (address converter);
}