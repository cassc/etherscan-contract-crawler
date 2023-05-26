// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.17;

import {LibBytes} from "../libraries/LibBytes.sol";
import {TransferKey} from "../libraries/LibTransferKey.sol";
import {Transaction} from "./LibTransaction.sol";

enum BridgeType {
    Wormhole,
    Stargate
}

struct BridgeArgs {
    BridgeType bridgeType;
    bytes payload;
}

struct BridgeInArgs {
    uint16 recipientNetworkId;
    BridgeArgs bridgeArgs;
    uint256 amount;
    address toAssetAddress;
    TransferKey transferKey;
}

struct BridgeOutArgs {
    BridgeArgs bridgeArgs;
    Transaction transaction;
    TransferKey transferKey;
}