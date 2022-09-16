// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import "./Keep3rParameters.sol";
import "./Keep3rRoles.sol";
import "../../interfaces/peripherals/IKeep3rDisputable.sol";

abstract contract Keep3rDisputable is IKeep3rDisputable, Keep3rAccountance, Keep3rRoles {
    /// @inheritdoc IKeep3rDisputable
    function dispute(address _jobOrKeeper) external override onlyDisputer {
        if (disputes[_jobOrKeeper]) revert AlreadyDisputed();
        disputes[_jobOrKeeper] = true;
        emit Dispute(_jobOrKeeper, msg.sender);
    }

    /// @inheritdoc IKeep3rDisputable
    function resolve(address _jobOrKeeper) external override onlyDisputer {
        if (!disputes[_jobOrKeeper]) revert NotDisputed();
        disputes[_jobOrKeeper] = false;
        emit Resolve(_jobOrKeeper, msg.sender);
    }
}