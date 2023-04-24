// SPDX-License-Identifier: Apache-2.0
// Copyright 2017 Loopring Technology Limited.
// Modified by DeGate DAO, 2022
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "../../../lib/AddressUtil.sol";
import "../../../lib/MathUint.sol";
import "../../../thirdparty/BytesUtil.sol";
import "../../iface/ExchangeData.sol";
import "../../iface/IBlockVerifier.sol";
import "../libtransactions/BlockReader.sol";
import "../libtransactions/AccountUpdateTransaction.sol";
import "../libtransactions/DepositTransaction.sol";
import "../libtransactions/WithdrawTransaction.sol";
import "./ExchangeMode.sol";
import "./ExchangeWithdrawals.sol";


/// @title ExchangeBlocks.
/// @author Brecht Devos - <[email protected]>
/// @author Daniel Wang  - <[email protected]>
library ExchangeBlocks
{
    using AddressUtil          for address;
    using AddressUtil          for address payable;
    using BlockReader          for bytes;
    using BytesUtil            for bytes;
    using MathUint             for uint;
    using ExchangeMode         for ExchangeData.State;
    using ExchangeWithdrawals  for ExchangeData.State;
    using SignatureUtil        for bytes32;

    event BlockSubmitted(
        uint    indexed blockIdx,
        bytes32         merkleRoot,
        bytes32         publicDataHash
    );

    event ProtocolFeesUpdated(
        uint16 protocolFeeBips,
        uint16 previousProtocolFeeBips
    );

    function submitBlocks(
        ExchangeData.State   storage S,
        ExchangeData.Block[] memory  blocks
        )
        public
    {
        // Exchange cannot be in withdrawal mode
        require(!S.isInWithdrawalMode(), "INVALID_MODE");

        // Commit the blocks
        bytes32[] memory publicDataHashes = new bytes32[](blocks.length);
        for (uint i = 0; i < blocks.length; i++) {
            // Hash all the public data to a single value which is used as the input for the circuit
            publicDataHashes[i] = blocks[i].data.fastSHA256();
            // Commit the block
            commitBlock(S, blocks[i], publicDataHashes[i]);
        }

        // Verify the blocks - blocks are verified in a batch to save gas.
        verifyBlocks(S, blocks, publicDataHashes);
    }

    // == Internal Functions ==

    function commitBlock(
        ExchangeData.State storage S,
        ExchangeData.Block memory  _block,
        bytes32                    _publicDataHash
        )
        private
    {
        // Read the block header
        BlockReader.BlockHeader memory header = _block.data.readHeader();

        // Validate the exchange
        require(header.exchange == address(this), "INVALID_EXCHANGE");
        // Validate the Merkle roots
        require(header.merkleRootBefore == S.merkleRoot, "INVALID_MERKLE_ROOT");
        require(header.merkleRootAfter != header.merkleRootBefore, "EMPTY_BLOCK_DISABLED");
        require(header.merkleAssetRootBefore == S.merkleAssetRoot, "INVALID_MERKLE_ASSET_ROOT");
        require(header.merkleAssetRootAfter != header.merkleAssetRootBefore, "EMPTY_BLOCK_DISABLED");

        require(uint(header.merkleRootAfter) < ExchangeData.SNARK_SCALAR_FIELD, "INVALID_MERKLE_ROOT");
        require(uint(header.merkleAssetRootAfter) < ExchangeData.SNARK_SCALAR_FIELD, "INVALID_ASSERT_MERKLE_ROOT");
        // Validate the timestamp
        require(
            header.timestamp > block.timestamp - ExchangeData.TIMESTAMP_HALF_WINDOW_SIZE_IN_SECONDS &&
            header.timestamp < block.timestamp + ExchangeData.TIMESTAMP_HALF_WINDOW_SIZE_IN_SECONDS,
            "INVALID_TIMESTAMP"
        );
        // Validate the protocol fee values
        require(
            validateAndSyncProtocolFees(S, header.protocolFeeBips),
            "INVALID_PROTOCOL_FEES"
        );

        // Process conditional transactions
        processConditionalTransactions(
            S,
            _block,
            header
        );

        // Emit an event
        uint numBlocks = S.numBlocks;
        emit BlockSubmitted(numBlocks, header.merkleRootAfter, _publicDataHash);

        S.merkleRoot = header.merkleRootAfter;
        S.merkleAssetRoot = header.merkleAssetRootAfter;

        if (_block.storeBlockInfoOnchain) {
            S.blocks[numBlocks] = ExchangeData.BlockInfo(
                uint32(block.timestamp),
                bytes28(_publicDataHash)
            );
        }

        S.numBlocks = numBlocks + 1;
    }

    function verifyBlocks(
        ExchangeData.State   storage S,
        ExchangeData.Block[] memory  blocks,
        bytes32[]            memory  publicDataHashes
        )
        private
        view
    {
        IBlockVerifier blockVerifier = S.blockVerifier;
        uint numBlocksVerified = 0;
        bool[] memory blockVerified = new bool[](blocks.length);
        ExchangeData.Block memory firstBlock;
        uint[] memory batch = new uint[](blocks.length);

        while (numBlocksVerified < blocks.length) {
            // Find all blocks of the same type
            uint batchLength = 0;
            for (uint i = 0; i < blocks.length; i++) {
                if (blockVerified[i] == false) {
                    if (batchLength == 0) {
                        firstBlock = blocks[i];
                        batch[batchLength++] = i;
                    } else {
                        ExchangeData.Block memory _block = blocks[i];
                        if (_block.blockType == firstBlock.blockType &&
                            _block.blockSize == firstBlock.blockSize &&
                            _block.blockVersion == firstBlock.blockVersion) {
                            batch[batchLength++] = i;
                        }
                    }
                }
            }

            // Prepare the data for batch verification
            uint[] memory publicInputs = new uint[](batchLength);
            uint[] memory proofs = new uint[](batchLength * 8);

            for (uint i = 0; i < batchLength; i++) {
                uint blockIdx = batch[i];
                // Mark the block as verified
                blockVerified[blockIdx] = true;
                // Strip the 3 least significant bits of the public data hash
                // so we don't have any overflow in the snark field
                publicInputs[i] = uint(publicDataHashes[blockIdx]) >> 3;
                // Copy proof
                ExchangeData.Block memory _block = blocks[blockIdx];
                for (uint j = 0; j < 8; j++) {
                    proofs[i*8 + j] = _block.proof[j];
                }
            }

            // Verify the proofs
            require(
                blockVerifier.verifyProofs(
                    uint8(firstBlock.blockType),
                    firstBlock.blockSize,
                    firstBlock.blockVersion,
                    publicInputs,
                    proofs
                ),
                "INVALID_PROOF"
            );

            numBlocksVerified += batchLength;
        }
    }

    function processConditionalTransactions(
        ExchangeData.State      storage S,
        ExchangeData.Block      memory _block,
        BlockReader.BlockHeader memory header
        )
        private
    {
        if (header.numConditionalTransactions > 0) {
            // Cache the domain seperator to save on SLOADs each time it is accessed.
            ExchangeData.BlockContext memory ctx = ExchangeData.BlockContext({
                DOMAIN_SEPARATOR: S.DOMAIN_SEPARATOR,
                timestamp: header.timestamp
            });

            ExchangeData.AuxiliaryData[] memory block_auxiliaryData;
            bytes memory blockAuxData = _block.auxiliaryData;
            assembly {
                block_auxiliaryData := add(blockAuxData, 64)
            }

            require(
                block_auxiliaryData.length == header.numConditionalTransactions,
                "AUXILIARYDATA_INVALID_LENGTH"
            );

            require(
                header.numConditionalTransactions == (header.depositSize + header.accountUpdateSize + header.withdrawSize),
                "invalid number of conditional transactions"
            );

            // Run over all conditional transactions
            uint minTxIndex = 0;
            bytes memory txData = new bytes(ExchangeData.TX_DATA_AVAILABILITY_SIZE);
            for (uint i = 0; i < block_auxiliaryData.length; i++) {
                uint txIndex;
                ExchangeData.TransactionType txType;
                if (i < header.depositSize) {
                    txType = ExchangeData.TransactionType.DEPOSIT;
                    txIndex = i; 
                }else if(i < header.depositSize + header.accountUpdateSize) {
                    txType = ExchangeData.TransactionType.ACCOUNT_UPDATE;
                    txIndex = i;
                }else {
                    txType = ExchangeData.TransactionType.WITHDRAWAL;
                    txIndex = i + _block.blockSize - header.depositSize - header.accountUpdateSize - header.withdrawSize; 
                }

                // Load the data from auxiliaryData, which is still encoded as calldata



                bytes memory auxData;
                assembly {
                    // Offset to block_auxiliaryData[i]
                    let auxOffset := mload(add(block_auxiliaryData, add(32, mul(32, i))))

                    // Load `data` (pos 0)
                    let auxDataOffset := mload(add(add(32, block_auxiliaryData), auxOffset))
                    auxData := add(add(32, block_auxiliaryData), add(auxOffset, auxDataOffset))
                }

                // Each conditional transaction needs to be processed from left to right
                require(txIndex >= minTxIndex, "AUXILIARYDATA_INVALID_ORDER");

                minTxIndex = txIndex + 1;


                // Get the transaction data
                _block.data.readTransactionData(txIndex, _block.blockSize, txData);

                // Process the transaction
                uint txDataOffset = 0;

                if (txType == ExchangeData.TransactionType.DEPOSIT) {
                    DepositTransaction.process(
                        S,
                        ctx,
                        txData,
                        txDataOffset,
                        auxData
                    );
                } else if (txType == ExchangeData.TransactionType.WITHDRAWAL) {
                    WithdrawTransaction.process(
                        S,
                        ctx,
                        txData,
                        txDataOffset,
                        auxData
                    );
                } else if (txType == ExchangeData.TransactionType.ACCOUNT_UPDATE) {
                    AccountUpdateTransaction.process(
                        S,
                        ctx,
                        txData,
                        txDataOffset,
                        auxData
                    );
                } else {
                    // ExchangeData.TransactionType.NOOP,
                    // ExchangeData.TransactionType.TRANSFER and
                    // ExchangeData.TransactionType.SPOT_TRADE and
                    // ExchangeData.TransactionType.ORDER_CANCEL and
                    // ExchangeData.TransactionType.BATCH_SPOT_TRADE 
                    // ExchangeData.TransactionType.APPKEY_UPDATE 
                    // are not supported
                    revert("UNSUPPORTED_TX_TYPE");
                }
            }
        }
    }

    function validateAndSyncProtocolFees(
        ExchangeData.State storage S,
        uint16 protocolFeeBips
        )
        private
        returns (bool)
    {
        ExchangeData.ProtocolFeeData memory data = S.protocolFeeData;

        uint16 protocolFeeBipsInLoopring = S.loopring.getProtocolFeeValues();
        if (data.nextProtocolFeeBips != protocolFeeBipsInLoopring ) {
            data.executeTimeOfNextProtocolFeeBips = uint32(block.timestamp + ExchangeData.MIN_AGE_PROTOCOL_FEES_UNTIL_UPDATED);
            data.nextProtocolFeeBips = protocolFeeBipsInLoopring;

            // Update the data in storage
            S.protocolFeeData = data;
        }

        if ((data.executeTimeOfNextProtocolFeeBips !=0) && (block.timestamp > data.executeTimeOfNextProtocolFeeBips)) {
            // Store the current protocol fees in the previous protocol fees
            data.previousProtocolFeeBips = data.protocolFeeBips;
            // Get the latest protocol fees for this exchange
            data.protocolFeeBips = data.nextProtocolFeeBips;
            data.syncedAt = uint32(block.timestamp);

            data.executeTimeOfNextProtocolFeeBips = 0;

            if (data.protocolFeeBips != data.previousProtocolFeeBips ) {
                emit ProtocolFeesUpdated(
                    data.protocolFeeBips,
                    data.previousProtocolFeeBips
                );
            }

            // Update the data in storage
            S.protocolFeeData = data;
        }

        // The given fee values are valid if they are the current or previous protocol fee values
        return (protocolFeeBips == data.protocolFeeBips) ||
            (protocolFeeBips == data.previousProtocolFeeBips );
    }
}