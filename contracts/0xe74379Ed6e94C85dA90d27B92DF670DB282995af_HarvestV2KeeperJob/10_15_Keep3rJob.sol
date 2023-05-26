// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

import "./Governable.sol";
import "../interfaces/IKeep3rJob.sol";
import "../interfaces/IKeep3rV2.sol";

abstract contract Keep3rJob is IKeep3rJob, Governable {
    address public override keep3r = 0xeb02addCfD8B773A5FFA6B9d1FE99c566f8c44CC;

    function setKeep3r(address _keep3r) public override onlyGovernor {
        keep3r = _keep3r;
        emit Keep3rSet(_keep3r);
    }

    function _isValidKeeper(address _keeper) internal virtual {
        if (!IKeep3rV2(keep3r).isKeeper(_keeper)) revert KeeperNotValid();
    }

    modifier upkeep() {
        _isValidKeeper(msg.sender);
        _;
        IKeep3rV2(keep3r).worked(msg.sender);
    }
}