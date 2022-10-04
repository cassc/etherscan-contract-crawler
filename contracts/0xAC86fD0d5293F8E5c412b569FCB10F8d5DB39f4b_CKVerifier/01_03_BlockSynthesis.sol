//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

/*
    Describes a Bitcoin block with a single transaction: the concatenation of
    genTx0, extraNonce1, extraNonce2, and genTx1.
*/
struct SingleTxBitcoinBlock {
    bytes genTx0;
    bytes4 extraNonce1;
    bytes extraNonce2;
    bytes genTx1;

    bytes4 nonce;
    bytes4 bits;
    bytes4 nTime;
    bytes32 previousBlockHash;
    bytes4 version;
}

contract BlockSynthesis {
    function reverseUint256(uint256 input) internal pure returns (uint256 v) {
        v = input;

        // swap bytes
        v = ((v & 0xFF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00) >> 8) |
            ((v & 0x00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF) << 8);

        // swap 2-byte long pairs
        v = ((v & 0xFFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000) >> 16) |
            ((v & 0x0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF) << 16);

        // swap 4-byte long pairs
        v = ((v & 0xFFFFFFFF00000000FFFFFFFF00000000FFFFFFFF00000000FFFFFFFF00000000) >> 32) |
            ((v & 0x00000000FFFFFFFF00000000FFFFFFFF00000000FFFFFFFF00000000FFFFFFFF) << 32);

        // swap 8-byte long pairs
        v = ((v & 0xFFFFFFFFFFFFFFFF0000000000000000FFFFFFFFFFFFFFFF0000000000000000) >> 64) |
            ((v & 0x0000000000000000FFFFFFFFFFFFFFFF0000000000000000FFFFFFFFFFFFFFFF) << 64);

        // swap 16-byte long pairs
        v = (v >> 128) | (v << 128);
    }

    function reverseBytes(bytes memory input) internal pure returns (bytes memory) {
        bytes memory newBytes = new bytes(input.length);
        for (uint i = 0; i < input.length; i++) {
            newBytes[input.length - i - 1] = input[i];
        }
        return newBytes;
    }

    function sha256d(bytes memory data) public pure returns (bytes32) {
        return sha256(bytes.concat(sha256(data)));
    }

    function createCoinbaseTx(
        bytes memory genTx0,
        bytes4 extraNonce1,
        bytes memory extraNonce2,
        bytes memory genTx1
    ) public pure returns (bytes memory) {
        return bytes.concat(genTx0, extraNonce1, extraNonce2, genTx1);
    }

    function coinbaseHash(bytes memory coinbaseTx) public pure returns (bytes32) {
        return bytes32(reverseUint256(uint256(sha256d(coinbaseTx))));
    }

    function createBlockHeader(
        bytes4 nonce,
        bytes4 bits,
        bytes4 nTime,
        bytes32 merkleRoot,
        bytes32 previousBlockHash,
        bytes4 version
    ) public pure returns (bytes memory) {
        bytes memory headerPreReverse = bytes.concat(nonce, bits, nTime, merkleRoot, previousBlockHash, version);
        return reverseBytes(headerPreReverse);
    }

    function createSingleTxHeader(SingleTxBitcoinBlock calldata  blockData) public pure returns (bytes memory) {
        bytes memory coinbaseTx = createCoinbaseTx(blockData.genTx0, blockData.extraNonce1, blockData.extraNonce2, blockData.genTx1);
        bytes32 merkleRoot = coinbaseHash(coinbaseTx);
        return createBlockHeader(blockData.nonce, blockData.bits, blockData.nTime,
            merkleRoot, blockData.previousBlockHash, blockData.version);
    }

    function blockHash(bytes memory blockHeader) public pure returns (bytes32) {
        return bytes32(reverseUint256(uint256(sha256d(blockHeader))));
    }

    function blockDifficulty(bytes32 hash) public pure returns (uint256) {
        return 0x00000000ffffffffffffffffffffffffffffffffffffffffffffffffffffffff / uint256(hash);
    }
}
