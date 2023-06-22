// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

/// @title Saffron Fixed Income Vault Interface
/// @author psykeeper, supafreq, everywherebagel, maze, rx
/// @notice Base interface for vaults
/// @dev When implementing new vault types, extend the abstract contract Vault
interface IVault {
  /// @notice Capacity of the fixed side
  /// @return Total capacity of the fixed side
  function fixedSideCapacity() external view returns (uint256);

  /// @notice Vault initializer, runs upon vault creation
  /// @param _vaultId ID of the vault
  /// @param _duration How long the vault will be locked, once started, in seconds
  /// @param _adapter Address of the vault's corresponding adapter
  /// @param _fixedSideCapacity Maximum capacity of the fixed side
  /// @param _variableSideCapacity Maximum capacity of the variable side
  /// @param _variableAsset Address of the variable base asset
  /// @param _feeBps Protocol fee in basis points
  /// @param _feeReceiver Address that collects the protocol fee
  /// @dev This is called by the parent factory's initializeVault function. Make sure that only the factory can call
  function initialize(
    uint256 _vaultId,
    uint256 _duration,
    address _adapter,
    uint256 _fixedSideCapacity,
    uint256 _variableSideCapacity,
    address _variableAsset,
    uint256 _feeBps,
    address _feeReceiver
  ) external;

  /// @notice Deposit assets into the vault
  /// @param amount Amount of asset to deposit
  /// @param side ID of side to deposit into
  /// @param data Data to pass, vault implementation dependent
  function deposit(
    uint256 amount,
    uint256 side,
    bytes calldata data
  ) external;

  /// @notice Withdraw assets out of the vault
  /// @param side ID of side to withdraw from
  /// @param data Data to pass, vault implementation dependent
  function withdraw(uint256 side, bytes calldata data) external;

  /// @notice Boolean indicating whether or not the vault has settled its earnings
  /// @return True if earnings are settled
  function earningsSettled() external view returns (bool);

  /// @notice Vault started state
  /// @return True if started
  function isStarted() external view returns (bool);
}

interface IUniV3Vault is IVault {}