/// SPDX-License-Identifier: UNLICENSED
/// (c) Theori, Inc. 2022
/// All rights reserved

pragma solidity >=0.8.0;

import "./RLP.sol";

/**
 * @title CoreTypes
 * @author Theori, Inc.
 * @notice Data types and parsing functions for core types, including block headers
 *         and account data.
 */
library CoreTypes {
    struct BlockHeaderData {
        bytes32 ParentHash;
        bytes32 Root;
        bytes32 TxHash;
        bytes32 ReceiptHash;
        uint256 Number;
        uint256 Time;
        uint256 BaseFee;
    }

    struct AccountData {
        uint256 Nonce;
        uint256 Balance;
        bytes32 StorageRoot;
        bytes32 CodeHash;
    }

    function parseHash(bytes calldata buf) internal pure returns (bytes32 result, uint256 offset) {
        uint256 value;
        (value, offset) = RLP.parseUint(buf);
        result = bytes32(value);
    }

    function parseBlockHeader(bytes calldata header)
        internal
        pure
        returns (BlockHeaderData memory data)
    {
        (uint256 listSize, uint256 offset) = RLP.parseList(header);
        header = header[offset:offset + listSize];

        (data.ParentHash, offset) = parseHash(header); // ParentHash
        header = header[offset:];
        offset = RLP.skip(header); // UncleHash
        header = header[offset:];
        offset = RLP.skip(header); // Coinbase
        header = header[offset:];
        (data.Root, offset) = parseHash(header); // Root
        header = header[offset:];
        (data.TxHash, offset) = parseHash(header); // TxHash
        header = header[offset:];
        (data.ReceiptHash, offset) = parseHash(header); // ReceiptHash
        header = header[offset:];
        offset = RLP.skip(header); // Bloom
        header = header[offset:];
        offset = RLP.skip(header); // Difficulty
        header = header[offset:];
        (data.Number, offset) = RLP.parseUint(header); // Number
        header = header[offset:];
        offset = RLP.skip(header); // GasLimit
        header = header[offset:];
        offset = RLP.skip(header); // GasUsed
        header = header[offset:];
        (data.Time, offset) = RLP.parseUint(header); // Time
        header = header[offset:];
        offset = RLP.skip(header); // Extra
        header = header[offset:];
        offset = RLP.skip(header); // MixDigest
        header = header[offset:];
        offset = RLP.skip(header); // Nonce
        header = header[offset:];

        if (header.length > 0) {
            (data.BaseFee, offset) = RLP.parseUint(header); // BaseFee
            header = header[offset:];
        }
    }

    function getBlockHeaderHashAndSize(bytes calldata header)
        internal
        pure
        returns (bytes32 blockHash, uint256 headerSize)
    {
        (uint256 listSize, uint256 offset) = RLP.parseList(header);
        headerSize = offset + listSize;
        blockHash = keccak256(header[0:headerSize]);
    }

    function parseAccount(bytes calldata account) internal pure returns (AccountData memory data) {
        (, uint256 offset) = RLP.parseList(account);
        account = account[offset:];

        (data.Nonce, offset) = RLP.parseUint(account); // Nonce
        account = account[offset:];
        (data.Balance, offset) = RLP.parseUint(account); // Balance
        account = account[offset:];
        (data.StorageRoot, offset) = parseHash(account); // StorageRoot
        account = account[offset:];
        (data.CodeHash, offset) = parseHash(account); // CodeHash
        account = account[offset:];
    }
}