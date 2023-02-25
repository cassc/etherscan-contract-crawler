// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.7;

interface IDecapacitor {
    /**
     * @notice returns if the packed message is the part of a merkle tree or not
     * @param root_ root hash of the merkle tree
     * @param packedMessage_ packed message which needs to be verified
     * @param proof_ proof used to determine the inclusion
     */
    function verifyMessageInclusion(
        bytes32 root_,
        bytes32 packedMessage_,
        bytes calldata proof_
    ) external pure returns (bool);
}