// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

/// @title Keep3rKeeperFundable contract
/// @notice Handles the actions required to become a keeper
interface IKeep3rKeeperFundable {
  // Events

  /// @notice Emitted when Keep3rKeeperFundable#activate is called
  /// @param _keeper The keeper that has been activated
  /// @param _bond The asset the keeper has bonded
  /// @param _amount The amount of the asset the keeper has bonded
  event Activation(address indexed _keeper, address indexed _bond, uint256 _amount);

  /// @notice Emitted when Keep3rKeeperFundable#withdraw is called
  /// @param _keeper The caller of Keep3rKeeperFundable#withdraw function
  /// @param _bond The asset to withdraw from the bonding pool
  /// @param _amount The amount of funds withdrawn
  event Withdrawal(address indexed _keeper, address indexed _bond, uint256 _amount);

  // Errors

  /// @notice Throws when the address that is trying to register as a job is already a job
  error AlreadyAJob();

  // Methods

  /// @notice Beginning of the bonding process
  /// @param _bonding The asset being bound
  /// @param _amount The amount of bonding asset being bound
  function bond(address _bonding, uint256 _amount) external;

  /// @notice Beginning of the unbonding process
  /// @param _bonding The asset being unbound
  /// @param _amount Allows for partial unbonding
  function unbond(address _bonding, uint256 _amount) external;

  /// @notice End of the bonding process after bonding time has passed
  /// @param _bonding The asset being activated as bond collateral
  function activate(address _bonding) external;

  /// @notice Withdraw funds after unbonding has finished
  /// @param _bonding The asset to withdraw from the bonding pool
  function withdraw(address _bonding) external;
}

/// @title Keep3rKeeperDisputable contract
/// @notice Handles the actions that can be taken on a disputed keeper
interface IKeep3rKeeperDisputable {
  // Events

  /// @notice Emitted when Keep3rKeeperDisputable#slash is called
  /// @param _keeper The slashed keeper
  /// @param _slasher The user that called Keep3rKeeperDisputable#slash
  /// @param _amount The amount of credits slashed from the keeper
  event KeeperSlash(address indexed _keeper, address indexed _slasher, uint256 _amount);

  /// @notice Emitted when Keep3rKeeperDisputable#revoke is called
  /// @param _keeper The revoked keeper
  /// @param _slasher The user that called Keep3rKeeperDisputable#revoke
  event KeeperRevoke(address indexed _keeper, address indexed _slasher);

  /// @notice Keeper revoked

  // Methods

  /// @notice Allows governance to slash a keeper based on a dispute
  /// @param _keeper The address being slashed
  /// @param _bonded The asset being slashed
  /// @param _amount The amount being slashed
  function slash(
    address _keeper,
    address _bonded,
    uint256 _amount
  ) external;

  /// @notice Blacklists a keeper from participating in the network
  /// @param _keeper The address being slashed
  function revoke(address _keeper) external;
}

// solhint-disable-next-line no-empty-blocks

/// @title Keep3rKeepers contract
interface IKeep3rKeepers is IKeep3rKeeperDisputable {

}