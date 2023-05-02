// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.17;

import {AppStorage, BridgeType, LibMagpieAggregator} from "../libraries/LibMagpieAggregator.sol";
import {TransferKey} from "../data-transfer/LibDataTransfer.sol";
import {LibWormhole} from "./LibWormhole.sol";
import {LibStargate} from "./LibStargate.sol";
import {LibAsset} from "../libraries/LibAsset.sol";
import {LibBytes} from "../libraries/LibBytes.sol";
import {LibTransaction, Transaction} from "./LibTransaction.sol";

struct BridgeArgs {
    BridgeType bridgeType;
    bytes payload;
}

error InvalidBridgeType();

library LibBridge {
    using LibAsset for address;
    using LibBytes for bytes;

    function bridgeIn(
        uint16 recipientNetworkId,
        BridgeArgs memory bridgeArgs,
        uint256 amount,
        address toAssetAddress
    ) internal returns (uint64 tokenSequence) {
        AppStorage storage s = LibMagpieAggregator.getStorage();

        s.tokenSequence += 1;
        tokenSequence = s.tokenSequence;
        if (bridgeArgs.bridgeType == BridgeType.Wormhole) {
            LibWormhole.bridgeIn(recipientNetworkId, tokenSequence, bridgeArgs, amount, toAssetAddress);
        } else if (bridgeArgs.bridgeType == BridgeType.Stargate) {
            LibStargate.bridgeIn(recipientNetworkId, tokenSequence, bridgeArgs, amount, toAssetAddress);
        } else {
            revert InvalidBridgeType();
        }
    }

    function bridgeOut(
        BridgeArgs memory bridgeArgs,
        Transaction memory transaction,
        TransferKey memory transferKey
    ) internal returns (uint256 amount) {
        if (bridgeArgs.bridgeType == BridgeType.Wormhole) {
            amount = LibWormhole.bridgeOut(bridgeArgs.payload, transaction);
        } else if (bridgeArgs.bridgeType == BridgeType.Stargate) {
            amount = LibStargate.bridgeOut(bridgeArgs.payload, transaction, transferKey);
        } else {
            revert InvalidBridgeType();
        }
    }
}