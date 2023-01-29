// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Verifier is Ownable {
    bytes32 private root;

    constructor(bytes32 _root) {
        // (1)
        root = _root;
    }

    function verify(
        bytes32[] memory proof,
        string memory imageIpfs,
        uint256 tokenId,
        string memory color
    ) public view {
        // (2)
        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(imageIpfs, tokenId, color))));
        // (3)
        require(MerkleProof.verify(proof, root, leaf), "Invalid proof");
        // (4)
        // ...
    }

    function setRoot(bytes32 _root) external onlyOwner {
        root = _root;
    }

    function getRoot() external view returns (bytes32) {
        return root;
    }
}