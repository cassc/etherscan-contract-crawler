// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IHubFacet} from "../interfaces/IHubFacet.sol";
import {IMeTokenRegistryFacet} from "../interfaces/IMeTokenRegistryFacet.sol";
import {IMigrationRegistry} from "../interfaces/IMigrationRegistry.sol";
import {ISingleAssetVault} from "../interfaces/ISingleAssetVault.sol";
import {HubInfo} from "../libs/LibHub.sol";
import {MeTokenInfo} from "../libs/LibMeToken.sol";
import {Vault} from "./Vault.sol";

/// @title Single-Asset Vault
/// @author Carter Carlson (@cartercarlson), Parv Garg (@parv3213), @zgorizzo69
/// @notice Vault which manages basic erc20-like collateral assets for MeTokens
contract SingleAssetVault is Vault, ISingleAssetVault {
    using SafeERC20 for IERC20;

    constructor(address _dao, address _diamond) Vault(_dao, _diamond) {}

    /// @inheritdoc ISingleAssetVault
    function startMigration(address meToken) external override {
        MeTokenInfo memory meTokenInfo = IMeTokenRegistryFacet(diamond)
            .getMeTokenInfo(meToken);
        HubInfo memory hubInfo = IHubFacet(diamond).getHubInfo(
            meTokenInfo.hubId
        );

        require(msg.sender == meTokenInfo.migration, "!migration");
        uint256 balance = meTokenInfo.balancePooled + meTokenInfo.balanceLocked;
        IERC20(hubInfo.asset).safeTransfer(meTokenInfo.migration, balance);
        emit StartMigration(meToken);
    }

    /// @inheritdoc Vault
    function isValid(
        bytes memory /*encodedArgs */
    ) external pure override returns (bool) {
        return true;
    }
}