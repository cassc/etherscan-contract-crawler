// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12;

interface IFiduLense {
  /// @notice Returns the value of a given addresses FIDU holdings denominated in USDC
  ///           uses staked fidu and fidu held in wallet to determine position value.
  function fiduPositionValue(address addr) external view returns (uint256 usdcAmount);

  /// @notice Converts a given USDC amount to FIDU using the current FIDU share price
  function usdcToFidu(uint256 usdcAmount) external view returns (uint256 fiduAmount);

  /// @notice Converts a given amount of FIDU to USDC using the current FIDU share price
  function fiduToUsdc(uint256 fiduAmount) external view returns (uint256 usdcAmount);
}