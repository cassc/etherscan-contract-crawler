// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9 <0.9.0;

import './Keep3rMeteredJob.sol';
import './Keep3rBondedJob.sol';
import './OnlyEOA.sol';

abstract contract Keep3rMeteredPublicJob is Keep3rMeteredJob, Keep3rBondedJob, OnlyEOA {
  // internals
  function _isValidKeeper(address _keeper) internal override(Keep3rBondedJob, Keep3rJob) {
    if (onlyEOA) _validateEOA(_keeper);
    super._isValidKeeper(_keeper);
  }
}