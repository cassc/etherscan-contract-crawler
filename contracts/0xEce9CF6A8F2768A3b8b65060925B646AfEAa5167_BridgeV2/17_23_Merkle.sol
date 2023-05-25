// SPDX-License-Identifier: UNLICENSED
// Copyright (c) Eywa.Fi, 2021-2023 - all rights reserved
pragma solidity 0.8.17;

import "./ZeroCopySource.sol";

library Merkle {
    /** @notice Do hash leaf as the multi-chain does.
     *
     *  @param data_ Data in bytes format;
     *  @return result Hashed value in bytes32 format.
     */
    function hashLeaf(bytes memory data_) internal pure returns (bytes32 result) {
        result = sha256(abi.encodePacked(uint8(0x0), data_));
    }

    /** @notice Do hash children as the multi-chain does.
     *
     *  @param l_ Left node;
     *  @param r_ Right node;
     *  @return result Hashed value in bytes32 format.
     */
    function hashChildren(bytes32 l_, bytes32 r_) internal pure returns (bytes32 result) {
        result = sha256(abi.encodePacked(bytes1(0x01), l_, r_));
    }

    /** @notice Verify merkle proove.
     *
     *  @param auditPath_ Merkle path;
     *  @param root_ Merkle tree root;
     *  @return The verified value included in auditPath_.
     */
    function prove(bytes memory auditPath_, bytes32 root_) internal pure returns (bytes memory) {
        uint256 off = 0;
        bytes memory value;
        (value, off) = ZeroCopySource.NextVarBytes(auditPath_, off);

        bytes32 hash = hashLeaf(value);
        uint256 size = (auditPath_.length - off) / 33; // 33 = sizeof(uint256) + 1
        bytes32 nodeHash;
        uint8 pos;
        for (uint256 i = 0; i < size; i++) {
            (pos, off) = ZeroCopySource.NextUint8(auditPath_, off);
            (nodeHash, off) = ZeroCopySource.NextHash(auditPath_, off);
            if (pos == 0x00) {
                hash = hashChildren(nodeHash, hash);
            } else if (pos == 0x01) {
                hash = hashChildren(hash, nodeHash);
            } else {
                revert("Merkle: prove eod");
            }
        }
        require(hash == root_, "Merkle: prove root");
        return value;
    }
}