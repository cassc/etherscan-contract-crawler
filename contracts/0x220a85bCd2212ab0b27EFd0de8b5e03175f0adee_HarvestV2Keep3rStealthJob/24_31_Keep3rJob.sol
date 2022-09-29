// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9 <0.9.0;

import './Governable.sol';
import '../../interfaces/utils/IKeep3rJob.sol';
import '../../interfaces/external/IKeep3rV2.sol';

abstract contract Keep3rJob is IKeep3rJob, Governable {
  /// @inheritdoc IKeep3rJob
  address public keep3r = 0xeb02addCfD8B773A5FFA6B9d1FE99c566f8c44CC;

  // methods

  /// @inheritdoc IKeep3rJob
  function setKeep3r(address _keep3r) public onlyGovernor {
    _setKeep3r(_keep3r);
  }

  // modifiers

  modifier upkeep() {
    _isValidKeeper(msg.sender);
    _;
    IKeep3rV2(keep3r).worked(msg.sender);
  }

  // internals

  function _setKeep3r(address _keep3r) internal {
    keep3r = _keep3r;
    emit Keep3rSet(_keep3r);
  }

  function _isValidKeeper(address _keeper) internal virtual {
    if (!IKeep3rV2(keep3r).isKeeper(_keeper)) revert KeeperNotValid();
  }
}