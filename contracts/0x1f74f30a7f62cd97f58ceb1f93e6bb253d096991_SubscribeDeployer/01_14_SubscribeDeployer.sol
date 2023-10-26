// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { ISubscribeDeployer } from "../interfaces/ISubscribeDeployer.sol";

import { DataTypes } from "../libraries/DataTypes.sol";

import { Subscribe } from "../core/Subscribe.sol";

contract SubscribeDeployer is ISubscribeDeployer {
    DataTypes.DeployParameters public override params;

    /// @inheritdoc ISubscribeDeployer
    function deploySubscribe(
        bytes32 salt,
        address engine
    ) external override returns (address addr) {
        params.engine = engine;
        addr = address(new Subscribe{ salt: salt }());
        delete params;
    }
}