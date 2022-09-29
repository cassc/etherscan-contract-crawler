// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import './IKeep3rJob.sol';

interface IKeep3rMeteredJob is IKeep3rJob {
  // events

  /// @notice Emitted when a new Keep3rHelper contract is set
  /// @param _keep3rHelper Address of the new Keep3rHelper contract
  event Keep3rHelperSet(address _keep3rHelper);

  /// @notice Emitted when a new gas bonus amount is set
  /// @param _gasBonus Amount of gas to add to cover unaccounted gas
  event GasBonusSet(uint256 _gasBonus);

  /// @notice Emitted when a new gas bonus multiplier is set
  /// @param _gasMultiplier Multiplier that boosts gas record to calculate the keeper reward
  event GasMultiplierSet(uint256 _gasMultiplier);

  /// @notice Emitted when a new gas bonus multiplier maximum is set
  /// @param _maxMultiplier Maximum acceptable gasMultiplier to be set
  event MaxMultiplierSet(uint256 _maxMultiplier);

  /// @notice Emitted when a metered job is worked
  /// @param _initialGas First gas record registered
  /// @param _gasAfterWork Gas record registered after work
  /// @param _bonus Fixed amount of gas added to the accountance
  event GasMetered(uint256 _initialGas, uint256 _gasAfterWork, uint256 _bonus);

  // errors
  error MaxMultiplier();

  // views

  /// @return _keep3rHelper Address of the Keep3rHelper contract
  function keep3rHelper() external view returns (address _keep3rHelper);

  /// @return _gasBonus Amount of gas to add to cover unaccounted gas
  function gasBonus() external view returns (uint256 _gasBonus);

  /// @return _gasMultiplier Multiplier that boosts gas record to calculate the keeper reward
  function gasMultiplier() external view returns (uint256 _gasMultiplier);

  /// @return _maxMultiplier Maximum acceptable gasMultiplier to be set
  function maxMultiplier() external view returns (uint256 _maxMultiplier);

  // solhint-disable-next-line func-name-mixedcase, var-name-mixedcase
  function BASE() external view returns (uint32 _BASE);

  // methods

  /// @notice Allows governor to set a new Keep3rHelper contract
  /// @param _keep3rHelper Address of the new Keep3rHelper contract
  function setKeep3rHelper(address _keep3rHelper) external;

  /// @notice Allows governor to set a new gas bonus amount
  /// @param _gasBonus New amount of gas to add to cover unaccounted gas
  function setGasBonus(uint256 _gasBonus) external;

  /// @notice Allows governor to set a new gas multiplier
  /// @param _gasMultiplier New multiplier that boosts gas record to calculate the keeper reward
  function setGasMultiplier(uint256 _gasMultiplier) external;

  /// @notice Allows governor to set a new gas multiplier maximum
  /// @param _maxMultiplier New maximum acceptable gasMultiplier to be set
  function setMaxMultiplier(uint256 _maxMultiplier) external;
}