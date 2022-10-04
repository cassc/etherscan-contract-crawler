// SPDX-License-Identifier: MIT

pragma solidity =0.8.15;

interface IWhitelistMerkleTree {
    function isRootExists(bytes32 merkleRoot) external view returns (bool status);
    function getLeaf(address account) external view returns (bytes32 leaf);
    function isWhitelisted(bytes32[] calldata merkleProof, bytes32 root, bytes32 leaf) external pure returns (bool);
}