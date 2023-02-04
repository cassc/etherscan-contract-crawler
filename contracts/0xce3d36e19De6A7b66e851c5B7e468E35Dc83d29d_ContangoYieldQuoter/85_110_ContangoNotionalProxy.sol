//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../../libraries/DataTypes.sol";
import "../../utils/PermissionedProxy.sol";

interface IContangoNotionalProxyDeployer is IPermissionedProxyDeployer {
    function contangoNotionalParameters() external returns (PositionId positionId);
}

contract ContangoNotionalProxy is PermissionedProxy {
    PositionId public immutable positionId;

    constructor() PermissionedProxy() {
        positionId = IContangoNotionalProxyDeployer(msg.sender).contangoNotionalParameters();
    }
}