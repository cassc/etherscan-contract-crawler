// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9 <0.9.0;

import '@yearn-mechanics/contract-utils/solidity/contracts/utils/Machinery.sol';
import './Governable.sol';

abstract contract MachineryReady is Machinery, Governable {
  // errors

  /// @notice Throws when a OnlyGovernorOrMechanic function is called from an unknown address
  error OnlyGovernorOrMechanic();

  constructor(address _mechanicsRegistry) Machinery(_mechanicsRegistry) {}

  // methods

  /// @notice Allows governor to set a new MechanicsRegistry contract
  /// @param _mechanicsRegistry Address of the new MechanicsRegistry contract
  function setMechanicsRegistry(address _mechanicsRegistry) external override onlyGovernor {
    _setMechanicsRegistry(_mechanicsRegistry);
  }

  // modifiers

  modifier onlyGovernorOrMechanic() {
    _validateGovernorOrMechanic(msg.sender);
    _;
  }

  // internals

  function _validateGovernorOrMechanic(address _user) internal view {
    if (_user != governor && !isMechanic(_user)) revert OnlyGovernorOrMechanic();
  }
}