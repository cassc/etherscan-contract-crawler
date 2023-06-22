// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

/// @title Saffron Fixed Income Adapter
/// @author psykeeper, supafreq, everywherebagel, maze, rx
/// @notice Manages funds deposited into vaults to generate yield
interface IAdapter {
  /// @notice Used to determine whether the asset balance that is returned from holdings() is representative of all the funds that this adapter maintains
  /// @return True if holdings() is all-inclusive
  function hasAccurateHoldings() external view returns (bool);

  /// @notice Sets the vault ID that this adapter maintains assets for
  /// @param _vault Address of vault
  /// @dev Make sure this is only callable by the vault factory
  function setVault(address _vault) external;

  /// @notice Initializes the adapter
  /// @param id ID of adapter
  /// @param pool Address of Uniswap V3 pool
  /// @param depositTolerance Acceptable tolerance for lower liquidity
  /// @param data Data to pass, adapter implementation dependent
  /// @dev Make sure this is only callable by the vault creator
  function initialize(
    uint256 id,
    address pool,
    uint256 depositTolerance,
    bytes calldata data
  ) external;
}