// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.17;

import {DataTransferType} from "../data-transfer/LibDataTransfer.sol";
import {BridgeType} from "./LibBridge.sol";

struct TransactionValidation {
    bytes32 fromAssetAddress;
    bytes32 toAssetAddress;
    bytes32 toAddress;
    bytes32 recipientAggregatorAddress;
    uint256 amountOutMin;
    uint256 swapOutGasFee;
}

struct Transaction {
    BridgeType bridgeType;
    bytes32 fromAssetAddress;
    bytes32 toAssetAddress;
    bytes32 toAddress;
    bytes32 recipientAggregatorAddress;
    uint256 amountOutMin;
    uint256 swapOutGasFee;
    uint64 tokenSequence;
}

library LibTransaction {
    function encode(Transaction memory transaction) internal pure returns (bytes memory transactionPayload) {
        transactionPayload = new bytes(201);

        assembly {
            mstore(add(transactionPayload, 32), shl(248, mload(transaction))) // bridgeType
            mstore(add(transactionPayload, 33), mload(add(transaction, 32))) // fromAssetAddress
            mstore(add(transactionPayload, 65), mload(add(transaction, 64))) // toAssetAddress
            mstore(add(transactionPayload, 97), mload(add(transaction, 96))) // to
            mstore(add(transactionPayload, 129), mload(add(transaction, 128))) // recipientAggregatorAddress
            mstore(add(transactionPayload, 161), mload(add(transaction, 160))) // amountOutMin
            mstore(add(transactionPayload, 193), mload(add(transaction, 192))) // swapOutGasFee
            mstore(add(transactionPayload, 225), shl(192, mload(add(transaction, 224)))) // tokenSequence
        }
    }

    function decode(bytes memory transactionPayload) internal pure returns (Transaction memory transaction) {
        assembly {
            mstore(transaction, shr(248, mload(add(transactionPayload, 32)))) // bridgeType
            mstore(add(transaction, 32), mload(add(transactionPayload, 33))) // fromAssetAddress
            mstore(add(transaction, 64), mload(add(transactionPayload, 65))) // toAssetAddress
            mstore(add(transaction, 96), mload(add(transactionPayload, 97))) // to
            mstore(add(transaction, 128), mload(add(transactionPayload, 129))) // recipientAggregatorAddress
            mstore(add(transaction, 160), mload(add(transactionPayload, 161))) // amountOutMin
            mstore(add(transaction, 192), mload(add(transactionPayload, 193))) // swapOutGasFee
            mstore(add(transaction, 224), shr(192, mload(add(transactionPayload, 225)))) // tokenSequence
        }
    }
}