// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

import {IVault} from "../interfaces/IVault.sol";
import {LibAppStorage, AppStorage} from "./LibAppStorage.sol";
import {IMeToken} from "../interfaces/IMeToken.sol";
import {LibMeToken, MeTokenInfo} from "../libs/LibMeToken.sol";
import {IMigration} from "../interfaces/IMigration.sol";
import {LibMeta} from "../libs/LibMeta.sol";
import {LibHub, HubInfo} from "../libs/LibHub.sol";
import {LibCurve} from "../libs/LibCurve.sol";
import {LibWeightedAverage} from "../libs/LibWeightedAverage.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

library LibFoundry {
    event Mint(
        address meToken,
        address asset,
        address depositor,
        address recipient,
        uint256 assetsDeposited,
        uint256 meTokensMinted
    );

    event Burn(
        address meToken,
        address asset,
        address burner,
        address recipient,
        uint256 meTokensBurned,
        uint256 assetsReturned
    );

    // MINT FLOW CHART
    /****************************************************************************
    //                                                                         //
    //                                                 mint()                  //
    //                                                   |                     //
    //                                             CALCULATE MINT              //
    //                                                 /    \                  //
    // is hub updating or meToken migrating? -{      (Y)     (N)               //
    //                                               /         \               //
    //                                          CALCULATE       |              //
    //                                         TARGET MINT      |              //
    //                                             |            |              //
    //                                        TIME-WEIGHTED     |              //
    //                                           AVERAGE        |              //
    //                                               \         /               //
    //                                               MINT RETURN               //
    //                                                   |                     //
    //                                              .sub(fees)                 //
    //                                                                         //
    ****************************************************************************/
    function mint(
        address meToken,
        uint256 assetsDeposited,
        address recipient
    ) internal returns (uint256) {
        require(assetsDeposited > 0, "assetsDeposited==0");
        (address asset, address sender, uint256 meTokensMinted) = _handleMint(
            meToken,
            assetsDeposited
        );

        // Mint meToken to user
        IMeToken(meToken).mint(recipient, meTokensMinted);
        emit Mint(
            meToken,
            asset,
            sender,
            recipient,
            assetsDeposited,
            meTokensMinted
        );
        return meTokensMinted;
    }

    function mintWithPermit(
        address meToken,
        uint256 assetsDeposited,
        address recipient,
        uint256 deadline,
        uint8 vSig,
        bytes32 rSig,
        bytes32 sSig
    ) internal returns (uint256) {
        require(assetsDeposited > 0, "assetsDeposited==0");
        (
            address asset,
            uint256[2] memory amounts // 0-meTokensMinted 1-assetsDepositedAfterFees
        ) = _handleMintWithPermit(
                meToken,
                assetsDeposited,
                deadline,
                vSig,
                rSig,
                sSig
            );

        LibMeToken.updateBalancePooled(true, meToken, amounts[1]);
        // Mint meToken to user
        IMeToken(meToken).mint(recipient, amounts[0]);
        emit Mint(
            meToken,
            asset,
            LibMeta.msgSender(),
            recipient,
            assetsDeposited,
            amounts[0]
        );
        return amounts[0];
    }

    // BURN FLOW CHART
    /****************************************************************************
    //                                                                         //
    //                                                 burn()                  //
    //                                                   |                     //
    //                                             CALCULATE BURN              //
    //                                                /     \                  //
    // is hub updating or meToken migrating? -{     (Y)     (N)                //
    //                                              /         \                //
    //                                         CALCULATE       \               //
    //                                        TARGET BURN       \              //
    //                                           /               \             //
    //                                  TIME-WEIGHTED             \            //
    //                                     AVERAGE                 \           //
    //                                        |                     \          //
    //                              WEIGHTED BURN RETURN       BURN RETURN     //
    //                                     /     \               /    \        //
    // is msg.sender the -{              (N)     (Y)           (Y)    (N)      //
    // owner? (vs buyer)                 /         \           /        \      //
    //                                 GET           CALCULATE         GET     //
    //                            TIME-WEIGHTED    BALANCE LOCKED     REFUND   //
    //                            REFUND RATIO        RETURNED        RATIO    //
    //                                  |                |              |      //
    //                              .mul(wRR)        .add(BLR)      .mul(RR)   //
    //                                  \                |             /       //
    //                                     ACTUAL (WEIGHTED) BURN RETURN       //
    //                                                   |                     //
    //                                               .sub(fees)                //
    //                                                                         //
    ****************************************************************************/
    function burn(
        address meToken,
        uint256 meTokensBurned,
        address recipient
    ) internal returns (uint256) {
        require(meTokensBurned > 0, "meTokensBurned==0");
        AppStorage storage s = LibAppStorage.diamondStorage();
        address sender = LibMeta.msgSender();
        MeTokenInfo memory meTokenInfo = s.meTokens[meToken];
        HubInfo memory hubInfo = s.hubs[meTokenInfo.hubId];

        // Handling changes
        if (meTokenInfo.targetHubId != 0) {
            if (block.timestamp > meTokenInfo.endTime) {
                hubInfo = s.hubs[meTokenInfo.targetHubId];
                meTokenInfo = LibMeToken.finishResubscribe(meToken);
            } else if (block.timestamp > meTokenInfo.startTime) {
                // Handle migration actions if needed
                IMigration(meTokenInfo.migration).poke(meToken);
            }
        }
        if (hubInfo.updating && block.timestamp > hubInfo.endTime) {
            LibHub.finishUpdate(meTokenInfo.hubId);
        }
        // Calculate how many tokens are returned
        uint256 rawAssetsReturned = calculateRawAssetsReturned(
            meToken,
            meTokensBurned
        );
        uint256 assetsReturned = calculateActualAssetsReturned(
            sender,
            meToken,
            meTokensBurned,
            rawAssetsReturned
        );
        // Subtract tokens returned from balance pooled
        LibMeToken.updateBalancePooled(false, meToken, rawAssetsReturned);

        if (sender == meTokenInfo.owner) {
            // Is owner, subtract from balance locked
            LibMeToken.updateBalanceLocked(
                false,
                meToken,
                assetsReturned - rawAssetsReturned
            );
        } else {
            // Is buyer, add to balance locked using refund ratio
            LibMeToken.updateBalanceLocked(
                true,
                meToken,
                rawAssetsReturned - assetsReturned
            );
        }
        // Burn metoken from user
        IMeToken(meToken).burn(sender, meTokensBurned);

        _vaultWithdrawal(
            sender,
            recipient,
            meToken,
            meTokenInfo,
            hubInfo,
            meTokensBurned,
            assetsReturned
        );
        return assetsReturned;
    }

    function calculateMeTokensMinted(address meToken, uint256 assetsDeposited)
        internal
        view
        returns (uint256 meTokensMinted)
    {
        AppStorage storage s = LibAppStorage.diamondStorage();
        MeTokenInfo memory meTokenInfo = s.meTokens[meToken];
        HubInfo memory hubInfo = s.hubs[meTokenInfo.hubId];
        // gas savings
        uint256 totalSupply = IERC20(meToken).totalSupply();
        // Calculate return assuming update/resubscribe is not happening
        meTokensMinted = LibCurve.viewMeTokensMinted(
            assetsDeposited,
            meTokenInfo.hubId,
            totalSupply,
            meTokenInfo.balancePooled
        );

        if (meTokenInfo.targetHubId != 0) {
            // Calculate return for a resubscribing meToken
            uint256 targetMeTokensMinted = LibCurve.viewMeTokensMinted(
                assetsDeposited,
                meTokenInfo.targetHubId,
                totalSupply,
                meTokenInfo.balancePooled
            );
            meTokensMinted = LibWeightedAverage.calculate(
                meTokensMinted,
                targetMeTokensMinted,
                meTokenInfo.startTime,
                meTokenInfo.endTime
            );
        } else if (hubInfo.reconfigure) {
            // Calculate return for a hub which is updating its' curveInfo
            uint256 targetMeTokensMinted = LibCurve.viewTargetMeTokensMinted(
                assetsDeposited,
                meTokenInfo.hubId,
                totalSupply,
                meTokenInfo.balancePooled
            );
            meTokensMinted = LibWeightedAverage.calculate(
                meTokensMinted,
                targetMeTokensMinted,
                hubInfo.startTime,
                hubInfo.endTime
            );
        }
    }

    function calculateRawAssetsReturned(address meToken, uint256 meTokensBurned)
        internal
        view
        returns (uint256 rawAssetsReturned)
    {
        AppStorage storage s = LibAppStorage.diamondStorage();
        MeTokenInfo memory meTokenInfo = s.meTokens[meToken];
        HubInfo memory hubInfo = s.hubs[meTokenInfo.hubId];

        uint256 totalSupply = IERC20(meToken).totalSupply(); // gas savings

        // Calculate return assuming update is not happening
        rawAssetsReturned = LibCurve.viewAssetsReturned(
            meTokensBurned,
            meTokenInfo.hubId,
            totalSupply,
            meTokenInfo.balancePooled
        );

        if (meTokenInfo.targetHubId != 0) {
            // Calculate return for a resubscribing meToken
            uint256 targetAssetsReturned = LibCurve.viewAssetsReturned(
                meTokensBurned,
                meTokenInfo.targetHubId,
                totalSupply,
                meTokenInfo.balancePooled
            );
            rawAssetsReturned = LibWeightedAverage.calculate(
                rawAssetsReturned,
                targetAssetsReturned,
                meTokenInfo.startTime,
                meTokenInfo.endTime
            );
        } else if (hubInfo.reconfigure) {
            // Calculate return for a hub which is updating its' curveInfo
            uint256 targetAssetsReturned = LibCurve.viewTargetAssetsReturned(
                meTokensBurned,
                meTokenInfo.hubId,
                totalSupply,
                meTokenInfo.balancePooled
            );
            rawAssetsReturned = LibWeightedAverage.calculate(
                rawAssetsReturned,
                targetAssetsReturned,
                hubInfo.startTime,
                hubInfo.endTime
            );
        }
    }

    /// @dev applies refundRatio
    function calculateActualAssetsReturned(
        address sender,
        address meToken,
        uint256 meTokensBurned,
        uint256 rawAssetsReturned
    ) internal view returns (uint256 actualAssetsReturned) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        MeTokenInfo memory meTokenInfo = s.meTokens[meToken];
        HubInfo memory hubInfo = s.hubs[meTokenInfo.hubId];
        // If msg.sender == owner, give owner the sell rate. - all of tokens returned plus a %
        //      of balancePooled based on how much % of supply will be burned
        // If msg.sender != owner, give msg.sender the burn rate
        if (sender == meTokenInfo.owner) {
            actualAssetsReturned =
                rawAssetsReturned +
                (((s.PRECISION * meTokensBurned) /
                    IERC20(meToken).totalSupply()) *
                    meTokenInfo.balanceLocked) /
                s.PRECISION;
        } else {
            if (
                hubInfo.targetRefundRatio == 0 && meTokenInfo.targetHubId == 0
            ) {
                // Not updating targetRefundRatio or resubscribing
                actualAssetsReturned =
                    (rawAssetsReturned * hubInfo.refundRatio) /
                    s.MAX_REFUND_RATIO;
            } else {
                if (meTokenInfo.targetHubId != 0) {
                    // meToken is resubscribing
                    actualAssetsReturned =
                        (rawAssetsReturned *
                            LibWeightedAverage.calculate(
                                hubInfo.refundRatio,
                                s.hubs[meTokenInfo.targetHubId].refundRatio,
                                meTokenInfo.startTime,
                                meTokenInfo.endTime
                            )) /
                        s.MAX_REFUND_RATIO;
                } else {
                    // Hub is updating
                    actualAssetsReturned =
                        (rawAssetsReturned *
                            LibWeightedAverage.calculate(
                                hubInfo.refundRatio,
                                hubInfo.targetRefundRatio,
                                hubInfo.startTime,
                                hubInfo.endTime
                            )) /
                        s.MAX_REFUND_RATIO;
                }
            }
        }
    }

    function _handleMint(address meToken, uint256 assetsDeposited)
        private
        returns (
            address,
            address,
            uint256
        )
    {
        AppStorage storage s = LibAppStorage.diamondStorage();
        // 0-meTokensMinted 1-fee 2-assetsDepositedAfterFees
        address sender = LibMeta.msgSender();
        MeTokenInfo memory meTokenInfo = s.meTokens[meToken];
        HubInfo memory hubInfo = s.hubs[meTokenInfo.hubId];
        uint256[3] memory amounts;
        amounts[1] = (assetsDeposited * s.mintFee) / s.PRECISION; // fee
        amounts[2] = assetsDeposited - amounts[1]; //assetsDepositedAfterFees

        amounts[0] = calculateMeTokensMinted(meToken, amounts[2]); // meTokensMinted
        IVault vault = IVault(hubInfo.vault);
        address asset = hubInfo.asset;

        // Check if meToken is using a migration vault and in the active stage of resubscribing.
        // Sometimes a meToken may be resubscribing to a hub w/ the same asset,
        // in which case a migration vault isn't needed
        if (
            meTokenInfo.migration != address(0) &&
            block.timestamp > meTokenInfo.startTime &&
            IMigration(meTokenInfo.migration).isStarted(meToken)
        ) {
            // Use meToken address to get the asset address from the migration vault
            vault = IVault(meTokenInfo.migration);
            asset = s.hubs[meTokenInfo.targetHubId].asset;
        }
        vault.handleDeposit(sender, asset, assetsDeposited, amounts[1]);
        LibMeToken.updateBalancePooled(true, meToken, amounts[2]);

        // Handling changes
        if (meTokenInfo.targetHubId != 0) {
            if (block.timestamp > meTokenInfo.endTime) {
                hubInfo = s.hubs[meTokenInfo.targetHubId];
                meTokenInfo = LibMeToken.finishResubscribe(meToken);
            } else if (block.timestamp > meTokenInfo.startTime) {
                // Handle migration actions if needed
                IMigration(meTokenInfo.migration).poke(meToken);
            }
        }
        if (hubInfo.updating && block.timestamp > hubInfo.endTime) {
            LibHub.finishUpdate(meTokenInfo.hubId);
        }

        return (asset, sender, amounts[0]);
    }

    function _handleMintWithPermit(
        address meToken,
        uint256 assetsDeposited,
        uint256 deadline,
        uint8 vSig,
        bytes32 rSig,
        bytes32 sSig
    ) private returns (address asset, uint256[2] memory amounts) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        // 0-meTokensMinted 1-fee 2-assetsDepositedAfterFees

        MeTokenInfo memory meTokenInfo = s.meTokens[meToken];
        HubInfo memory hubInfo = s.hubs[meTokenInfo.hubId];

        amounts[1] =
            assetsDeposited -
            ((assetsDeposited * s.mintFee) / s.PRECISION); //assetsDepositedAfterFees

        amounts[0] = calculateMeTokensMinted(meToken, amounts[1]); // meTokensMinted

        asset = _handlingChangesWithPermit(
            amounts[1],
            meToken,
            meTokenInfo,
            hubInfo,
            assetsDeposited,
            deadline,
            vSig,
            rSig,
            sSig
        );
        return (asset, amounts);
    }

    function _handlingChangesWithPermit(
        uint256 assetsDepositedAfterFees,
        address meToken,
        MeTokenInfo memory meTokenInfo,
        HubInfo memory hubInfo,
        uint256 assetsDeposited,
        uint256 deadline,
        uint8 vSig,
        bytes32 rSig,
        bytes32 sSig
    ) private returns (address asset) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        IVault vault = IVault(hubInfo.vault);
        asset = hubInfo.asset;

        if (
            meTokenInfo.migration != address(0) &&
            block.timestamp > meTokenInfo.startTime &&
            IMigration(meTokenInfo.migration).isStarted(meToken)
        ) {
            // Use meToken address to get the asset address from the migration vault
            vault = IVault(meTokenInfo.migration);
            asset = s.hubs[meTokenInfo.targetHubId].asset;
        }
        vault.handleDepositWithPermit(
            LibMeta.msgSender(),
            asset,
            assetsDeposited,
            (assetsDeposited * s.mintFee) / s.PRECISION,
            deadline,
            vSig,
            rSig,
            sSig
        );
        LibMeToken.updateBalancePooled(true, meToken, assetsDepositedAfterFees);

        // Handling changes
        if (meTokenInfo.targetHubId != 0) {
            if (block.timestamp > meTokenInfo.endTime) {
                hubInfo = s.hubs[meTokenInfo.targetHubId];
                meTokenInfo = LibMeToken.finishResubscribe(meToken);
            } else if (block.timestamp > meTokenInfo.startTime) {
                // Handle migration actions if needed
                IMigration(meTokenInfo.migration).poke(meToken);
            }
        }
        if (hubInfo.updating && block.timestamp > hubInfo.endTime) {
            LibHub.finishUpdate(meTokenInfo.hubId);
        }
    }

    function _vaultWithdrawal(
        address sender,
        address recipient,
        address meToken,
        MeTokenInfo memory meTokenInfo,
        HubInfo memory hubInfo,
        uint256 meTokensBurned,
        uint256 assetsReturned
    ) private {
        AppStorage storage s = LibAppStorage.diamondStorage();

        uint256 fee;
        // If msg.sender == owner, give owner the sell rate. - all of tokens returned plus a %
        //      of balancePooled based on how much % of supply will be burned
        // If msg.sender != owner, give msg.sender the burn rate
        if (sender == meTokenInfo.owner) {
            fee = (s.burnOwnerFee * assetsReturned) / s.PRECISION;
        } else {
            fee = (s.burnBuyerFee * assetsReturned) / s.PRECISION;
        }

        assetsReturned = assetsReturned - fee;
        address asset;
        if (
            meTokenInfo.migration != address(0) &&
            block.timestamp > meTokenInfo.startTime
        ) {
            // meToken is in a live state of resubscription
            asset = s.hubs[meTokenInfo.targetHubId].asset;
            IVault(meTokenInfo.migration).handleWithdrawal(
                recipient,
                asset,
                assetsReturned,
                fee
            );
        } else {
            // meToken is *not* resubscribing
            asset = hubInfo.asset;
            IVault(hubInfo.vault).handleWithdrawal(
                recipient,
                asset,
                assetsReturned,
                fee
            );
        }

        emit Burn(
            meToken,
            asset,
            sender,
            recipient,
            meTokensBurned,
            assetsReturned
        );
    }
}