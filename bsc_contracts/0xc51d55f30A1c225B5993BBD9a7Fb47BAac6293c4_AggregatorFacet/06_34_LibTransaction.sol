// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.17;

import {BridgeType, DataTransferType} from "../libraries/LibMagpieAggregator.sol";

struct TransactionValidation {
    bytes32 fromAssetAddress;
    bytes32 toAssetAddress;
    bytes32 toAddress;
    uint256 amountOutMin;
    uint256 swapOutGasFee;
}

struct Transaction {
    DataTransferType dataTransferType;
    BridgeType bridgeType;
    uint16 recipientNetworkId;
    uint64 tokenSequence;
    bytes32 fromAssetAddress;
    bytes32 toAssetAddress;
    bytes32 toAddress;
    bytes32 recipientAggregatorAddress;
    uint256 amountOutMin;
    uint256 swapOutGasFee;
}

library LibTransaction {
    function encode(Transaction memory transaction) internal pure returns (bytes memory transactionPayload) {
        transactionPayload = new bytes(204);

        assembly {
            mstore(add(transactionPayload, 32), shl(248, mload(transaction))) // dataTransferType
            mstore(add(transactionPayload, 33), shl(248, mload(add(transaction, 32)))) // bridgeType
            mstore(add(transactionPayload, 34), shl(240, mload(add(transaction, 64)))) // recipientNetworkId
            mstore(add(transactionPayload, 36), shl(192, mload(add(transaction, 96)))) // tokenSequence
            mstore(add(transactionPayload, 44), mload(add(transaction, 128))) // fromAssetAddress
            mstore(add(transactionPayload, 76), mload(add(transaction, 160))) // toAssetAddress
            mstore(add(transactionPayload, 108), mload(add(transaction, 192))) // to
            mstore(add(transactionPayload, 140), mload(add(transaction, 224))) // recipientAggregatorAddress
            mstore(add(transactionPayload, 172), mload(add(transaction, 256))) // amountOutMin
            mstore(add(transactionPayload, 204), mload(add(transaction, 288))) // swapOutGasFee
        }
    }

    function decode(bytes memory transactionPayload) internal pure returns (Transaction memory transaction) {
        assembly {
            mstore(transaction, shr(248, mload(add(transactionPayload, 32)))) // dataTransferType
            mstore(add(transaction, 32), shr(248, mload(add(transactionPayload, 33)))) // bridgeType
            mstore(add(transaction, 64), shr(240, mload(add(transactionPayload, 34)))) // recipientNetworkId
            mstore(add(transaction, 96), shr(192, mload(add(transactionPayload, 36)))) // tokenSequence
            mstore(add(transaction, 128), mload(add(transactionPayload, 44))) // fromAssetAddress
            mstore(add(transaction, 160), mload(add(transactionPayload, 76))) // toAssetAddress
            mstore(add(transaction, 192), mload(add(transactionPayload, 108))) // to
            mstore(add(transaction, 224), mload(add(transactionPayload, 140))) // recipientAggregatorAddress
            mstore(add(transaction, 256), mload(add(transactionPayload, 172))) // amountOutMin
            mstore(add(transaction, 288), mload(add(transactionPayload, 204))) // swapOutGasFee
        }
    }
}