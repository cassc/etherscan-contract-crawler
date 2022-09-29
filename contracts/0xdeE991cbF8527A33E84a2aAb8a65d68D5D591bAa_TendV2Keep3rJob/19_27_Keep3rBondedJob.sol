// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9 <0.9.0;

import './Keep3rJob.sol';
import '../../interfaces/utils/IKeep3rBondedJob.sol';

abstract contract Keep3rBondedJob is IKeep3rBondedJob, Keep3rJob {
  /// @inheritdoc IKeep3rBondedJob
  address public requiredBond = 0x1cEB5cB57C4D4E2b2433641b95Dd330A33185A44;
  /// @inheritdoc IKeep3rBondedJob
  uint256 public requiredMinBond = 50 ether;
  /// @inheritdoc IKeep3rBondedJob
  uint256 public requiredEarnings;
  /// @inheritdoc IKeep3rBondedJob
  uint256 public requiredAge;

  // methods

  /// @inheritdoc IKeep3rBondedJob
  function setKeep3rRequirements(
    address _bond,
    uint256 _minBond,
    uint256 _earned,
    uint256 _age
  ) public onlyGovernor {
    _setKeep3rRequirements(_bond, _minBond, _earned, _age);
  }

  // internals

  function _setKeep3rRequirements(
    address _bond,
    uint256 _minBond,
    uint256 _earned,
    uint256 _age
  ) internal {
    requiredBond = _bond;
    requiredMinBond = _minBond;
    requiredEarnings = _earned;
    requiredAge = _age;
    emit Keep3rRequirementsSet(_bond, _minBond, _earned, _age);
  }

  function _isValidKeeper(address _keeper) internal virtual override {
    if (!IKeep3rV2(keep3r).isBondedKeeper(_keeper, requiredBond, requiredMinBond, requiredEarnings, requiredAge)) revert KeeperNotValid();
  }
}