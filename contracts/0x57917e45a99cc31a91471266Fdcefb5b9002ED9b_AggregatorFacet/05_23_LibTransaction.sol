// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.17;

import {BridgeType} from "../bridge/LibCommon.sol";
import {DataTransferType} from "../data-transfer/LibCommon.sol";

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
            mstore(add(transactionPayload, 36), mload(add(transaction, 96))) // fromAssetAddress
            mstore(add(transactionPayload, 68), mload(add(transaction, 128))) // toAssetAddress
            mstore(add(transactionPayload, 100), mload(add(transaction, 160))) // to
            mstore(add(transactionPayload, 132), mload(add(transaction, 192))) // recipientAggregatorAddress
            mstore(add(transactionPayload, 164), mload(add(transaction, 224))) // amountOutMin
            mstore(add(transactionPayload, 196), mload(add(transaction, 256))) // swapOutGasFee
        }
    }

    function decode(bytes memory transactionPayload) internal pure returns (Transaction memory transaction) {
        assembly {
            mstore(transaction, shr(248, mload(add(transactionPayload, 32)))) // dataTransferType
            mstore(add(transaction, 32), shr(248, mload(add(transactionPayload, 33)))) // bridgeType
            mstore(add(transaction, 64), shr(240, mload(add(transactionPayload, 34)))) // recipientNetworkId
            mstore(add(transaction, 96), mload(add(transactionPayload, 36))) // fromAssetAddress
            mstore(add(transaction, 128), mload(add(transactionPayload, 68))) // toAssetAddress
            mstore(add(transaction, 160), mload(add(transactionPayload, 100))) // to
            mstore(add(transaction, 192), mload(add(transactionPayload, 132))) // recipientAggregatorAddress
            mstore(add(transaction, 224), mload(add(transactionPayload, 164))) // amountOutMin
            mstore(add(transaction, 256), mload(add(transactionPayload, 196))) // swapOutGasFee
        }
    }
}