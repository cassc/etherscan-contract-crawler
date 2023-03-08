// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.17;

import {TransferKey} from "../data-transfer/LibDataTransfer.sol";
import {LibWormhole} from "./LibWormhole.sol";
import {LibStargate} from "./LibStargate.sol";
import {LibAsset} from "../libraries/LibAsset.sol";
import {LibBytes} from "../libraries/LibBytes.sol";
import {LibTransaction, Transaction, TransactionValidation} from "./LibTransaction.sol";
import "../libraries/LibError.sol";

enum BridgeType {
    Wormhole,
    Stargate
}

struct BridgeArgs {
    BridgeType bridgeType;
    bytes payload;
}

library LibBridge {
    using LibAsset for address;
    using LibBytes for bytes;

    function bridgeIn(
        BridgeArgs memory bridgeArgs,
        TransactionValidation memory transactionValidation,
        uint256 amount,
        address toAssetAddress
    ) internal returns (uint64 tokenSequence) {
        if (bridgeArgs.bridgeType == BridgeType.Wormhole) {
            tokenSequence = LibWormhole.bridgeIn(transactionValidation, bridgeArgs, amount, toAssetAddress);
        } else if (bridgeArgs.bridgeType == BridgeType.Stargate) {
            tokenSequence = LibStargate.bridgeIn(transactionValidation, bridgeArgs, amount, toAssetAddress);
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