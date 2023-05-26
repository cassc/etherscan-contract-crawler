// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./interfaces/IFoundingFrog.sol";
import "./interfaces/IFrogMinter.sol";

contract FrogMinter is IFrogMinter {
    /// @notice merkle root to submit proofs of ownership of the NFT
    bytes32 public immutable merkleRoot;

    /// @notice founding frogs
    IFoundingFrog public immutable frog;

    constructor(bytes32 _merkleRoot, IFoundingFrog _frog) {
        merkleRoot = _merkleRoot;
        frog = _frog;
    }

    /// @inheritdoc IFrogMinter
    function mint(FrogMeta memory meta, bytes32[] memory proof) external {
        require(_isProofValid(meta, proof), "invalid proof");
        frog.mint(meta.beneficiary, meta.tokenId, meta.imageHash);
    }

    function _isProofValid(FrogMeta memory meta, bytes32[] memory proof)
        internal
        view
        returns (bool)
    {
        bytes32 node = keccak256(abi.encodePacked(msg.sender, meta.tokenId, meta.imageHash));
        uint256 length = proof.length;
        for (uint256 i = 0; i < length; i++) {
            (bytes32 left, bytes32 right) = (node, proof[i]);
            if (left > right) (left, right) = (right, left);
            node = keccak256(abi.encodePacked(left, right));
        }

        return node == merkleRoot;
    }
}