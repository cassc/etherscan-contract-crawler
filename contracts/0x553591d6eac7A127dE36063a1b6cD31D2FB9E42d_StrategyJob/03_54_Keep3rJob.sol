//SPDX-License-Identifier: MIT
pragma solidity >=0.8.8 <0.9.0;

import {Governable} from './Governable.sol';
import {IKeep3rJob, IKeep3r} from '../../interfaces/peripherals/IKeep3rJob.sol';

abstract contract Keep3rJob is IKeep3rJob, Governable {
  /// @inheritdoc IKeep3rJob
  IKeep3r public keep3r = IKeep3r(0xeb02addCfD8B773A5FFA6B9d1FE99c566f8c44CC);

  /// @inheritdoc IKeep3rJob
  function setKeep3r(IKeep3r _keep3r) public onlyGovernor {
    _setKeep3r(_keep3r);
  }

  function _setKeep3r(IKeep3r _keep3r) internal {
    keep3r = _keep3r;
    emit Keep3rSet(_keep3r);
  }

  function _isValidKeeper(address _keeper) internal virtual {
    if (!keep3r.isKeeper(_keeper)) revert KeeperNotValid();
  }

  modifier upkeep() {
    _isValidKeeper(msg.sender);
    _;
    keep3r.worked(msg.sender);
  }
}