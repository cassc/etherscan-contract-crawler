// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.17;

import {TransferKey} from "../libraries/LibTransferKey.sol";

enum DataTransferType {
    Wormhole,
    LayerZero
}

struct DataTransferInProtocol {
    uint16 networkId;
    DataTransferType dataTransferType;
    bytes payload;
}

struct DataTransferInArgs {
    DataTransferInProtocol protocol;
    TransferKey transferKey;
    bytes payload;
}

struct DataTransferOutArgs {
    DataTransferType dataTransferType;
    bytes payload;
}