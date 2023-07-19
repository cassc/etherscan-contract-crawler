/// SPDX-License-Identifier: UNLICENSED
/// (c) Theori, Inc. 2022
/// All rights reserved

pragma solidity >=0.8.0;

import "./BytesCalldata.sol";
import "./RLP.sol";

/**
 * @title CoreTypes
 * @author Theori, Inc.
 * @notice Data types and parsing functions for core types, including block headers
 *         and account data.
 */
library CoreTypes {
    using BytesCalldataOps for bytes;
    struct BlockHeaderData {
        bytes32 ParentHash;
        address Coinbase;
        bytes32 Root;
        bytes32 TxHash;
        bytes32 ReceiptHash;
        uint256 Number;
        uint256 GasLimit;
        uint256 GasUsed;
        uint256 Time;
        bytes32 MixHash;
        uint256 BaseFee;
        bytes32 WithdrawalsHash;
    }

    struct AccountData {
        uint256 Nonce;
        uint256 Balance;
        bytes32 StorageRoot;
        bytes32 CodeHash;
    }

    struct LogData {
        address Address;
        bytes32[] Topics;
        bytes Data;
    }

    struct WithdrawalData {
        uint256 Index;
        uint256 ValidatorIndex;
        address Address;
        uint256 AmountInGwei;
    }

    function parseHash(bytes calldata buf) internal pure returns (bytes32 result, uint256 offset) {
        uint256 value;
        (value, offset) = RLP.parseUint(buf);
        result = bytes32(value);
    }

    function parseAddress(bytes calldata buf)
        internal
        pure
        returns (address result, uint256 offset)
    {
        uint256 value;
        (value, offset) = RLP.parseUint(buf);
        result = address(uint160(value));
    }

    function parseBlockHeader(bytes calldata header)
        internal
        pure
        returns (BlockHeaderData memory data)
    {
        (uint256 listSize, uint256 offset) = RLP.parseList(header);
        header = header.slice(offset, listSize);

        (data.ParentHash, offset) = parseHash(header); // ParentHash
        header = header.suffix(offset);
        header = RLP.skip(header); // UncleHash
        (data.Coinbase, offset) = parseAddress(header); // Coinbase
        header = header.suffix(offset);
        (data.Root, offset) = parseHash(header); // Root
        header = header.suffix(offset);
        (data.TxHash, offset) = parseHash(header); // TxHash
        header = header.suffix(offset);
        (data.ReceiptHash, offset) = parseHash(header); // ReceiptHash
        header = header.suffix(offset);
        header = RLP.skip(header); // Bloom
        header = RLP.skip(header); // Difficulty
        (data.Number, offset) = RLP.parseUint(header); // Number
        header = header.suffix(offset);
        (data.GasLimit, offset) = RLP.parseUint(header); // GasLimit
        header = header.suffix(offset);
        (data.GasUsed, offset) = RLP.parseUint(header); // GasUsed
        header = header.suffix(offset);
        (data.Time, offset) = RLP.parseUint(header); // Time
        header = header.suffix(offset);
        header = RLP.skip(header); // Extra
        (data.MixHash, offset) = parseHash(header); // MixHash
        header = header.suffix(offset);
        header = RLP.skip(header); // Nonce

        if (header.length > 0) {
            (data.BaseFee, offset) = RLP.parseUint(header); // BaseFee
            header = header.suffix(offset);
        }

        if (header.length > 0) {
            (data.WithdrawalsHash, offset) = parseHash(header); // WithdrawalsHash
        }
    }

    function getBlockHeaderHashAndSize(bytes calldata header)
        internal
        pure
        returns (bytes32 blockHash, uint256 headerSize)
    {
        (uint256 listSize, uint256 offset) = RLP.parseList(header);
        unchecked {
            headerSize = offset + listSize;
        }
        blockHash = keccak256(header.prefix(headerSize));
    }

    function parseAccount(bytes calldata account) internal pure returns (AccountData memory data) {
        (, uint256 offset) = RLP.parseList(account);
        account = account.suffix(offset);

        (data.Nonce, offset) = RLP.parseUint(account); // Nonce
        account = account.suffix(offset);
        (data.Balance, offset) = RLP.parseUint(account); // Balance
        account = account.suffix(offset);
        (data.StorageRoot, offset) = parseHash(account); // StorageRoot
        account = account.suffix(offset);
        (data.CodeHash, offset) = parseHash(account); // CodeHash
        account = account.suffix(offset);
    }

    function parseLog(bytes calldata log) internal pure returns (LogData memory data) {
        (, uint256 offset) = RLP.parseList(log);
        log = log.suffix(offset);

        uint256 tmp;
        (tmp, offset) = RLP.parseUint(log); // Address
        data.Address = address(uint160(tmp));
        log = log.suffix(offset);

        (tmp, offset) = RLP.parseList(log); // Topics
        bytes calldata topics = log.slice(offset, tmp);
        log = log.suffix(offset + tmp);

        require(topics.length % 33 == 0);
        data.Topics = new bytes32[](tmp / 33);
        uint256 i = 0;
        while (topics.length > 0) {
            (data.Topics[i], offset) = parseHash(topics);
            topics = topics.suffix(offset);
            unchecked {
                i++;
            }
        }

        (data.Data, ) = RLP.splitBytes(log);
    }

    function extractLog(bytes calldata receiptValue, uint256 logIdx)
        internal
        pure
        returns (LogData memory)
    {
        // support EIP-2718: Currently all transaction types have the same
        // receipt RLP format, so we can just skip the receipt type byte
        if (receiptValue[0] < 0x80) {
            receiptValue = receiptValue.suffix(1);
        }

        (, uint256 offset) = RLP.parseList(receiptValue);
        receiptValue = receiptValue.suffix(offset);

        // pre EIP-658, receipts stored an intermediate state root in this field
        // post EIP-658, the field is a tx status (0 for failure, 1 for success)
        uint256 statusOrIntermediateRoot;
        (statusOrIntermediateRoot, offset) = RLP.parseUint(receiptValue);
        require(statusOrIntermediateRoot != 0, "tx did not succeed");
        receiptValue = receiptValue.suffix(offset);

        receiptValue = RLP.skip(receiptValue); // GasUsed
        receiptValue = RLP.skip(receiptValue); // LogsBloom

        uint256 length;
        (length, offset) = RLP.parseList(receiptValue); // Logs
        receiptValue = receiptValue.slice(offset, length);

        // skip the earlier logs
        for (uint256 i = 0; i < logIdx; i++) {
            require(receiptValue.length > 0, "log index does not exist");
            receiptValue = RLP.skip(receiptValue);
        }

        return parseLog(receiptValue);
    }

    function parseWithdrawal(bytes calldata withdrawal)
        internal
        pure
        returns (WithdrawalData memory data)
    {
        (, uint256 offset) = RLP.parseList(withdrawal);
        withdrawal = withdrawal.suffix(offset);

        (data.Index, offset) = RLP.parseUint(withdrawal); // Index
        withdrawal = withdrawal.suffix(offset);
        (data.ValidatorIndex, offset) = RLP.parseUint(withdrawal); // ValidatorIndex
        withdrawal = withdrawal.suffix(offset);
        (data.Address, offset) = parseAddress(withdrawal); // Address
        withdrawal = withdrawal.suffix(offset);
        (data.AmountInGwei, offset) = RLP.parseUint(withdrawal); // Amount
    }
}