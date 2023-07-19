// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19;

import { MerkleProof } from "openzeppelin-contracts/contracts/utils/cryptography/MerkleProof.sol";
import { Ownable } from "openzeppelin-contracts/contracts/access/Ownable.sol";

abstract contract MerkleAllow is Ownable {
    error NotOnList();

    bytes32 public merkleRoot;
    bool public openMint;

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function setOpenMint(bool _openMint) external onlyOwner {
        openMint = _openMint;
    }

    function _verifyAddress(bytes32[] calldata _merkleProof) public view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        return MerkleProof.verify(_merkleProof, merkleRoot, leaf);
    }

    modifier onlyAllowList(bytes32[] calldata _merkleProof) {
        if (!openMint && !_verifyAddress(_merkleProof)) {
            revert NotOnList();
        }
        _;
    }
}