// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title Interface for Native token
/// @dev This interface is used to interact with the native token
/// @dev The native token could be ETH for ethereum or BNB for Binance Smart Chain or MATIC for Polygon
interface IWrappedNative is IERC20 {
  /// @notice Deposit native token to get wrapped native token
  function deposit() external payable;

  /// @notice Withdraw wrapped native token to get native token
  function withdraw(uint256) external;
}