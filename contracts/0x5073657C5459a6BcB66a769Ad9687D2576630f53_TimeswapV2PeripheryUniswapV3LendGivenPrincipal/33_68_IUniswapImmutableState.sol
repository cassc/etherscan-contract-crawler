// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

/// @title UniswapImmutableState interface
interface IUniswapImmutableState {
  /// @return Returns the address of Uniswap Factory contract address
  function uniswapV3Factory() external view returns (address);
}