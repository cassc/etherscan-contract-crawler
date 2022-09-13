// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { IProfileDeployer } from "../interfaces/IProfileDeployer.sol";

import { DataTypes } from "../libraries/DataTypes.sol";

import { ProfileNFT } from "../core/ProfileNFT.sol";

contract ProfileDeployer is IProfileDeployer {
    DataTypes.ProfileDeployParameters public override profileParams;

    /// @inheritdoc IProfileDeployer
    function deployProfile(
        bytes32 salt,
        address engine,
        address subscribeBeacon,
        address essenceBeacon
    ) external override returns (address addr) {
        profileParams.engine = engine;
        profileParams.essenceBeacon = essenceBeacon;
        profileParams.subBeacon = subscribeBeacon;
        addr = address(new ProfileNFT{ salt: salt }());
        delete profileParams;
    }
}