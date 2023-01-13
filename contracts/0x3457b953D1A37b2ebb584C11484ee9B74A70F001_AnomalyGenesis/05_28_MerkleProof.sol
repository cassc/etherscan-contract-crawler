// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./Admins.sol";

// @author: miinded.com

abstract contract MerkleProofVerify is Admins {
    using MerkleProof for bytes32[];

    /**
    @dev hash of the root of the merkle
    */
    bytes32 public merkleRoot;

    /**
    @dev Used for verify the _proof and the _leaf
        The _leaf need to be calculated by the contract itself
        The _proof is calculated by the server, not by the contract
     */
    modifier merkleVerify(bytes32[] memory _proof, bytes32 _leaf){
        merkleCheck(_proof, _leaf);
        _;
    }

    /**
    @notice Verify the proof of the leaf.
    @dev (see @dev merkleVerify)
    */
    function merkleCheck(bytes32[] memory _proof, bytes32 _leaf) public view {
        require(_proof.verify(merkleRoot, _leaf), "MerkleProofVerify: Proof not valid");
    }

    /**
    @dev onlyOwner can change the root of the merkle.this
        Change root need to be done only if there is no pending tx during the mint.
    */
    function setMerkleRoot(bytes32 _merkleRoot) public onlyOwnerOrAdmins {
        merkleRoot = _merkleRoot;
    }
}