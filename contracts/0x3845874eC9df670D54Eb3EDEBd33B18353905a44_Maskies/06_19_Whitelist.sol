// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
pragma abicoder v2;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';

/**
    To use this contract all you have to do is implement the virtual funcs  
    The gist of those implementations is already done in internal funcs
    All you have to do is use these, and set the required access-control :)
 */

interface IWhiteList {
    event MerkleRootSet(bytes32 newMerkeRoot);
    event FlipWhitelistState(bool newState);

    // Virtual so you can set an onlyOwner
    function flipWhitelistState() external;

    // Be sure to lock access!
    function setMerkleRoot(bytes32 newMerkleRoot) external;

    /**
     * proof: an array of leafs (hashed with keccak256(abi.encode(<your>, <data>)))
     * leaf: the leaf to verify which is hashed using keccak256(abi.encode(<your>, <data>))
     *
     * abi.encode() is used rather than abi.encodePacked() because it allows for
     * deterministic handling when using using dynamic types in the leaf.
     */
    function verifyMerkleProof(bytes32[] memory proof, bytes32 leaf)
        external
        view
        returns (bool);
}

abstract contract WhiteList is IWhiteList {
    bytes32 public merkleRoot = keccak256(abi.encode(uint256(0)));
    bool public whitelistIsActive = true;

    // Virtual so you can set an onlyOwner
    function _flipWhitelistState() internal {
        whitelistIsActive = !whitelistIsActive;
        emit FlipWhitelistState(whitelistIsActive);
    }

    // Be sure to lock access!
    function _setMerkleRoot(bytes32 newMerkleRoot) internal {
        require(
            newMerkleRoot != keccak256(abi.encode(uint256(0))),
            'Merkle root cannot be 0'
        );
        merkleRoot = newMerkleRoot;
        emit MerkleRootSet(newMerkleRoot);
    }

    function verifyMerkleProof(bytes32[] memory proof, bytes32 leaf)
        public
        view
        override
        returns (bool)
    {
        require(
            merkleRoot != keccak256(abi.encode(uint256(0))),
            'Merkle root not set'
        );
        return MerkleProof.verify(proof, merkleRoot, leaf);
    }
}