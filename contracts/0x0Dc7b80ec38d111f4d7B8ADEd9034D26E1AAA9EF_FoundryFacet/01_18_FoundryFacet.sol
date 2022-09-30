// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

import {IFoundryFacet} from "../interfaces/IFoundryFacet.sol";
import {LibMeToken, MeTokenInfo} from "../libs/LibMeToken.sol";
import {LibMeta} from "../libs/LibMeta.sol";
import {Modifiers} from "../libs/LibAppStorage.sol";
import {LibFoundry} from "../libs/LibFoundry.sol";
import {LibHub, HubInfo} from "../libs/LibHub.sol";
import {IVault} from "../interfaces/IVault.sol";

/// @title meTokens Foundry Facet
/// @author @cartercarlson, @parv3213
/// @notice This contract manages all minting / burning for meTokens Protocol
contract FoundryFacet is IFoundryFacet, Modifiers {
    /// @inheritdoc IFoundryFacet
    function mint(
        address meToken,
        uint256 assetsDeposited,
        address recipient
    ) external override returns (uint256 meTokensMinted) {
        meTokensMinted = LibFoundry.mint(meToken, assetsDeposited, recipient);
    }

    /// @inheritdoc IFoundryFacet
    function mintWithPermit(
        address meToken,
        uint256 assetsDeposited,
        address recipient,
        uint256 deadline,
        uint8 vSig,
        bytes32 rSig,
        bytes32 sSig
    ) external override returns (uint256 meTokensMinted) {
        meTokensMinted = LibFoundry.mintWithPermit(
            meToken,
            assetsDeposited,
            recipient,
            deadline,
            vSig,
            rSig,
            sSig
        );
    }

    /// @inheritdoc IFoundryFacet
    function burn(
        address meToken,
        uint256 meTokensBurned,
        address recipient
    ) external override returns (uint256 assetsReturned) {
        assetsReturned = LibFoundry.burn(meToken, meTokensBurned, recipient);
    }

    /// @inheritdoc IFoundryFacet
    function donate(address meToken, uint256 assetsDeposited)
        external
        override
    {
        address sender = LibMeta.msgSender();
        MeTokenInfo memory meTokenInfo = s.meTokens[meToken];
        HubInfo memory hubInfo = s.hubs[meTokenInfo.hubId];
        require(meTokenInfo.migration == address(0), "meToken resubscribing");

        IVault vault = IVault(hubInfo.vault);
        address asset = hubInfo.asset;

        vault.handleDeposit(sender, asset, assetsDeposited, 0);

        LibMeToken.updateBalanceLocked(true, meToken, assetsDeposited);

        emit Donate(meToken, asset, sender, assetsDeposited);
    }

    /// @inheritdoc IFoundryFacet
    function calculateMeTokensMinted(address meToken, uint256 assetsDeposited)
        external
        view
        override
        returns (uint256 meTokensMinted)
    {
        meTokensMinted = LibFoundry.calculateMeTokensMinted(
            meToken,
            assetsDeposited
        );
    }

    /// @inheritdoc IFoundryFacet
    function calculateAssetsReturned(
        address meToken,
        uint256 meTokensBurned,
        address sender
    ) external view override returns (uint256 assetsReturned) {
        uint256 rawAssetsReturned = LibFoundry.calculateRawAssetsReturned(
            meToken,
            meTokensBurned
        );
        if (sender == address(0)) sender = LibMeta.msgSender();
        assetsReturned = LibFoundry.calculateActualAssetsReturned(
            sender,
            meToken,
            meTokensBurned,
            rawAssetsReturned
        );
    }
}