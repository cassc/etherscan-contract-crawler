// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.6;

interface IBetaConfig {
  /// @dev Returns the risk level for the given asset.
  function getRiskLevel(address token) external view returns (uint);

  /// @dev Returns the rate of interest collected to be distributed to the protocol reserve.
  function reserveRate() external view returns (uint);

  /// @dev Returns the beneficiary to receive a portion interest rate for the protocol.
  function reserveBeneficiary() external view returns (address);

  /// @dev Returns the ratio of which the given token consider for collateral value.
  function getCollFactor(address token) external view returns (uint);

  /// @dev Returns the max amount of collateral to accept globally.
  function getCollMaxAmount(address token) external view returns (uint);

  /// @dev Returns max ltv of collateral / debt to allow a new position.
  function getSafetyLTV(address token) external view returns (uint);

  /// @dev Returns max ltv of collateral / debt to liquidate a position of the given token.
  function getLiquidationLTV(address token) external view returns (uint);

  /// @dev Returns the bonus incentive reward factor for liquidators.
  function getKillBountyRate(address token) external view returns (uint);
}