/// SPDX-License-Identifier: UNLICENSED
/// (c) Theori, Inc. 2022
/// All rights reserved

/*
 * @author Theori, Inc.
 */

pragma solidity >=0.8.0;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

uint256 constant BASE_PROOF_SIZE = 34;
uint256 constant SUBPROOF_LIMBS_SIZE = 16;

struct RecursiveProof {
    uint256[BASE_PROOF_SIZE] base;
    uint256[SUBPROOF_LIMBS_SIZE] subproofLimbs;
    uint256[] inputs;
}

struct SignedRecursiveProof {
    RecursiveProof inner;
    bytes signature;
}

/**
 * @notice recover the signer of the proof
 * @param proof the SignedRecursiveProof
 * @return the address of the signer
 */
function getProofSigner(SignedRecursiveProof calldata proof) pure returns (address) {
    bytes32 msgHash = keccak256(
        abi.encodePacked("\x19Ethereum Signed Message:\n", "32", hashProof(proof.inner))
    );
    return ECDSA.recover(msgHash, proof.signature);
}

/**
 * @notice hash the contents of a RecursiveProof
 * @param proof the RecursiveProof
 * @return result a 32-byte digest of the proof
 */
function hashProof(RecursiveProof calldata proof) pure returns (bytes32 result) {
    uint256[] calldata inputs = proof.inputs;
    assembly {
        let ptr := mload(0x40)
        let contigLen := mul(0x20, add(BASE_PROOF_SIZE, SUBPROOF_LIMBS_SIZE))
        let inputsLen := mul(0x20, inputs.length)
        calldatacopy(ptr, proof, contigLen)
        calldatacopy(add(ptr, contigLen), inputs.offset, inputsLen)
        result := keccak256(ptr, add(contigLen, inputsLen))
    }
}

/**
 * @notice reverse the byte order of a uint256
 * @param input the input value
 * @return v the byte-order reversed value
 */
function byteReverse(uint256 input) pure returns (uint256 v) {
    v = input;

    uint256 MASK08 = 0xFF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00;
    uint256 MASK16 = 0xFFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000;
    uint256 MASK32 = 0xFFFFFFFF00000000FFFFFFFF00000000FFFFFFFF00000000FFFFFFFF00000000;
    uint256 MASK64 = 0xFFFFFFFFFFFFFFFF0000000000000000FFFFFFFFFFFFFFFF0000000000000000;

    // swap bytes
    v = ((v & MASK08) >> 8) | ((v & (~MASK08)) << 8);

    // swap 2-byte long pairs
    v = ((v & MASK16) >> 16) | ((v & (~MASK16)) << 16);

    // swap 4-byte long pairs
    v = ((v & MASK32) >> 32) | ((v & (~MASK32)) << 32);

    // swap 8-byte long pairs
    v = ((v & MASK64) >> 64) | ((v & (~MASK64)) << 64);

    // swap 16-byte long pairs
    v = (v >> 128) | (v << 128);
}

/**
 * @notice reads a 32-byte hash from its little-endian word-encoded form
 * @param words the hash words
 * @return the hash
 */
function readHashWords(uint256[] calldata words) pure returns (bytes32) {
    uint256 mask = 0xffffffffffffffff;
    uint256 result = (words[0] & mask);
    result |= (words[1] & mask) << 0x40;
    result |= (words[2] & mask) << 0x80;
    result |= (words[3] & mask) << 0xc0;
    return bytes32(byteReverse(result));
}