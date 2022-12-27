// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import '@openzeppelin/contracts/access/Ownable.sol';
import {MerkleProof} from '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';

contract MerkleDistributor is Ownable {
    bytes32 internal whiteListMerkleRoot = '';

    function setWhitelistMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        whiteListMerkleRoot = _merkleRoot;
    }

    function _isValidWhitelistProof(bytes32[] calldata merkleProof) internal view returns (bool) {
        bytes32 node = keccak256(abi.encodePacked(msg.sender));
        return MerkleProof.verify(merkleProof, whiteListMerkleRoot, node);
    }
}