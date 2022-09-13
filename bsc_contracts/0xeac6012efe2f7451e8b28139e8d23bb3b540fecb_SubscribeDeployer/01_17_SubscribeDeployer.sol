// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { ISubscribeDeployer } from "../interfaces/ISubscribeDeployer.sol";

import { DataTypes } from "../libraries/DataTypes.sol";

import { SubscribeNFT } from "../core/SubscribeNFT.sol";

contract SubscribeDeployer is ISubscribeDeployer {
    DataTypes.SubscribeDeployParameters public override subParams;

    /// @inheritdoc ISubscribeDeployer
    function deploySubscribe(bytes32 salt, address profileProxy)
        external
        override
        returns (address addr)
    {
        subParams.profileProxy = profileProxy;
        addr = address(new SubscribeNFT{ salt: salt }());
        delete subParams;
    }
}