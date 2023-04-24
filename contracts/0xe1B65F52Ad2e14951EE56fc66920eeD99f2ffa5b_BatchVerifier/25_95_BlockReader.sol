// SPDX-License-Identifier: Apache-2.0
// Copyright 2017 Loopring Technology Limited.
// Modified by DeGate DAO, 2022
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "../../../thirdparty/BytesUtil.sol";
import "../../iface/ExchangeData.sol";

/// @title BlockReader
/// @author Brecht Devos - <[email protected]>
/// @dev Utility library to read block data.
library BlockReader {
    using BlockReader       for ExchangeData.Block;
    using BytesUtil         for bytes;

    uint public constant OFFSET_TO_TRANSACTIONS = 20 + 32 + 32 + 32 + 32 + 4 + 2 + 4 + 4 + 2 + 2 + 2;


    struct BlockHeader
    {
        address exchange;
        bytes32 merkleRootBefore;
        bytes32 merkleRootAfter;
        bytes32 merkleAssetRootBefore;
        bytes32 merkleAssetRootAfter;
        uint32  timestamp;
        uint16  protocolFeeBips;

        uint32  numConditionalTransactions;
        uint32  operatorAccountID;

        uint16  depositSize;
        uint16  accountUpdateSize;
        uint16  withdrawSize;
    }

    function readHeader(
        bytes memory _blockData
        )
        internal
        pure
        returns (BlockHeader memory header)
    {
        uint offset = 0;
        header.exchange = _blockData.toAddress(offset);
        offset += 20;
        header.merkleRootBefore = _blockData.toBytes32(offset);
        offset += 32;
        header.merkleRootAfter = _blockData.toBytes32(offset);
        offset += 32;
        
        header.merkleAssetRootBefore = _blockData.toBytes32(offset);
        offset += 32;
        header.merkleAssetRootAfter = _blockData.toBytes32(offset);
        offset += 32;

        header.timestamp = _blockData.toUint32(offset);
        offset += 4;

        header.protocolFeeBips = _blockData.toUint16(offset);
        offset += 2;

        header.numConditionalTransactions = _blockData.toUint32(offset);
        offset += 4;
        header.operatorAccountID = _blockData.toUint32(offset);
        offset += 4;

        header.depositSize = _blockData.toUint16(offset);
        offset += 2;
        header.accountUpdateSize = _blockData.toUint16(offset);
        offset += 2;
        header.withdrawSize = _blockData.toUint16(offset);
        offset += 2;


        assert(offset == OFFSET_TO_TRANSACTIONS);
    }

    function readTransactionData(
        bytes memory data,
        uint txIdx,
        uint blockSize,
        bytes memory txData
        )
        internal
        pure
    {
        require(txIdx < blockSize, "INVALID_TX_IDX");

        // The transaction was transformed to make it easier to compress.
        // Transform it back here.
        // Part 1
        uint txDataOffset = OFFSET_TO_TRANSACTIONS +
            txIdx * ExchangeData.TX_DATA_AVAILABILITY_SIZE_PART_1;
        assembly {
            //  first 32 bytes of an Array stores the length of that array.

            // part_1 is 80 bytes, longer than 32 bytes,  80 = 32 + 32 + 16
            mstore(add(txData, 32), mload(add(data, add(txDataOffset, 32))))
            mstore(add(txData, 64), mload(add(data, add(txDataOffset, 64))))
            mstore(add(txData, 80), mload(add(data, add(txDataOffset, 80))))
        }
        // Part 2
        txDataOffset = OFFSET_TO_TRANSACTIONS +
            blockSize * ExchangeData.TX_DATA_AVAILABILITY_SIZE_PART_1 +
            txIdx * ExchangeData.TX_DATA_AVAILABILITY_SIZE_PART_2;
        assembly {
            // part_2 is 3 bytes
            // 112 = 32 + 80(part_1)
            mstore(add(txData, 112 ), mload(add(data, add(txDataOffset, 32))))
        }
    }
}