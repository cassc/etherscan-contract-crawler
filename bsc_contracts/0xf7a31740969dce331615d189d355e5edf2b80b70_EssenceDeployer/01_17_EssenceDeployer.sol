// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { IEssenceDeployer } from "../interfaces/IEssenceDeployer.sol";

import { DataTypes } from "../libraries/DataTypes.sol";

import { EssenceNFT } from "../core/EssenceNFT.sol";

contract EssenceDeployer is IEssenceDeployer {
    DataTypes.EssenceDeployParameters public override essParams;

    /// @inheritdoc IEssenceDeployer
    function deployEssence(bytes32 salt, address profileProxy)
        external
        override
        returns (address addr)
    {
        essParams.profileProxy = profileProxy;
        addr = address(new EssenceNFT{ salt: salt }());
        delete essParams;
    }
}