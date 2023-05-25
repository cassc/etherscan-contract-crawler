// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import './Keep3rJobOwnership.sol';
import '../Keep3rRoles.sol';
import '../Keep3rParameters.sol';
import '../../../interfaces/peripherals/IKeep3rJobs.sol';

abstract contract Keep3rJobManager is IKeep3rJobManager, Keep3rJobOwnership, Keep3rRoles, Keep3rParameters {
  using EnumerableSet for EnumerableSet.AddressSet;

  /// @inheritdoc IKeep3rJobManager
  function addJob(address _job) external override {
    if (_jobs.contains(_job)) revert JobAlreadyAdded();
    if (hasBonded[_job]) revert AlreadyAKeeper();
    _jobs.add(_job);
    jobOwner[_job] = msg.sender;
    emit JobAddition(msg.sender, _job);
  }
}