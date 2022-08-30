// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

/// @title Keep3rHelperParameters contract
/// @notice Contains all the helper functions used throughout the different files.
interface IKeep3rHelperParameters {
  // Structs

  /// @dev KP3R-WETH Pool address and isKP3RToken0
  /// @dev Created in order to save gas by avoiding calls to pool's token0 method
  struct Kp3rWethPool {
    address poolAddress;
    bool isKP3RToken0;
  }

  // Errors

  /// @notice Throws when pool does not have KP3R as token0 nor token1
  error InvalidKp3rPool();

  // Events

  /// @notice Emitted when the kp3r weth pool is changed
  /// @param _address Address of the new kp3r weth pool
  /// @param _isKP3RToken0 True if calling the token0 method of the pool returns the KP3R token address
  event Kp3rWethPoolChange(address _address, bool _isKP3RToken0);

  /// @notice Emitted when the minimum boost multiplier is changed
  /// @param _minBoost The minimum boost multiplier
  event MinBoostChange(uint256 _minBoost);

  /// @notice Emitted when the maximum boost multiplier is changed
  /// @param _maxBoost The maximum boost multiplier
  event MaxBoostChange(uint256 _maxBoost);

  /// @notice Emitted when the target bond amount is changed
  /// @param _targetBond The target bond amount
  event TargetBondChange(uint256 _targetBond);

  /// @notice Emitted when the Keep3r V2 address is changed
  /// @param _keep3rV2 The address of Keep3r V2
  event Keep3rV2Change(address _keep3rV2);

  /// @notice Emitted when the work extra gas amount is changed
  /// @param _workExtraGas The work extra gas
  event WorkExtraGasChange(uint256 _workExtraGas);

  /// @notice Emitted when the quote twap time is changed
  /// @param _quoteTwapTime The twap time for quoting
  event QuoteTwapTimeChange(uint32 _quoteTwapTime);

  /// @notice Emitted when minimum rewarded gas fee is changed
  /// @param _minBaseFee The minimum rewarded gas fee
  event MinBaseFeeChange(uint256 _minBaseFee);

  /// @notice Emitted when minimum rewarded priority fee is changed
  /// @param _minPriorityFee The minimum expected fee that the keeper should pay
  event MinPriorityFeeChange(uint256 _minPriorityFee);

  // Variables

  /// @notice Address of KP3R token
  /// @return _kp3r Address of KP3R token
  // solhint-disable func-name-mixedcase
  function KP3R() external view returns (address _kp3r);

  /// @notice The boost base used to calculate the boost rewards for the keeper
  /// @return _base The boost base number
  function BOOST_BASE() external view returns (uint256 _base);

  /// @notice KP3R-WETH pool that is being used as oracle
  /// @return poolAddress Address of the pool
  /// @return isKP3RToken0 True if calling the token0 method of the pool returns the KP3R token address
  function kp3rWethPool() external view returns (address poolAddress, bool isKP3RToken0);

  /// @notice The minimum multiplier used to calculate the amount of gas paid to the Keeper for the gas used to perform a job
  ///         For example: if the quoted gas used is 1000, then the minimum amount to be paid will be 1000 * minBoost / BOOST_BASE
  /// @return _multiplier The minimum boost multiplier
  function minBoost() external view returns (uint256 _multiplier);

  /// @notice The maximum multiplier used to calculate the amount of gas paid to the Keeper for the gas used to perform a job
  ///         For example: if the quoted gas used is 1000, then the maximum amount to be paid will be 1000 * maxBoost / BOOST_BASE
  /// @return _multiplier The maximum boost multiplier
  function maxBoost() external view returns (uint256 _multiplier);

  /// @notice The targeted amount of bonded KP3Rs to max-up reward multiplier
  ///         For example: if the amount of KP3R the keeper has bonded is targetBond or more, then the keeper will get
  ///                      the maximum boost possible in his rewards, if it's less, the reward boost will be proportional
  /// @return _target The amount of KP3R that comforms the targetBond
  function targetBond() external view returns (uint256 _target);

  /// @notice The amount of unaccounted gas that is going to be added to keeper payments
  /// @return _workExtraGas The work unaccounted gas amount
  function workExtraGas() external view returns (uint256 _workExtraGas);

  /// @notice The twap time for quoting
  /// @return _quoteTwapTime The twap time
  function quoteTwapTime() external view returns (uint32 _quoteTwapTime);

  /// @notice The minimum base fee that is used to calculate keeper rewards
  /// @return _minBaseFee The minimum rewarded gas fee
  function minBaseFee() external view returns (uint256 _minBaseFee);

  /// @notice The minimum priority fee that is also rewarded for keepers
  /// @return _minPriorityFee The minimum rewarded priority fee
  function minPriorityFee() external view returns (uint256 _minPriorityFee);

  /// @notice Address of Keep3r V2
  /// @return _keep3rV2 Address of Keep3r V2
  function keep3rV2() external view returns (address _keep3rV2);

  // Methods

  /// @notice Sets KP3R-WETH pool
  /// @param _poolAddress The address of the KP3R-WETH pool
  function setKp3rWethPool(address _poolAddress) external;

  /// @notice Sets the minimum boost multiplier
  /// @param _minBoost The minimum boost multiplier
  function setMinBoost(uint256 _minBoost) external;

  /// @notice Sets the maximum boost multiplier
  /// @param _maxBoost The maximum boost multiplier
  function setMaxBoost(uint256 _maxBoost) external;

  /// @notice Sets the target bond amount
  /// @param _targetBond The target bond amount
  function setTargetBond(uint256 _targetBond) external;

  /// @notice Sets the Keep3r V2 address
  /// @param _keep3rV2 The address of Keep3r V2
  function setKeep3rV2(address _keep3rV2) external;

  /// @notice Sets the work extra gas amount
  /// @param _workExtraGas The work extra gas
  function setWorkExtraGas(uint256 _workExtraGas) external;

  /// @notice Sets the quote twap time
  /// @param _quoteTwapTime The twap time for quoting
  function setQuoteTwapTime(uint32 _quoteTwapTime) external;

  /// @notice Sets the minimum rewarded gas fee
  /// @param _minBaseFee The minimum rewarded gas fee
  function setMinBaseFee(uint256 _minBaseFee) external;

  /// @notice Sets the minimum rewarded gas priority fee
  /// @param _minPriorityFee The minimum rewarded priority fee
  function setMinPriorityFee(uint256 _minPriorityFee) external;
}