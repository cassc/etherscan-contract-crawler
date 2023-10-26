// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract OgWhitelist is Ownable, ReentrancyGuard{
    
    modifier isYouAreOgWhitelisted(bytes32[] calldata _merkleProof) {
        require(checkOgWhitelisted(_merkleProof), "You are not OG");
        _;
    }

    bytes32 public merkleRootOgWhitelist;

    constructor(bytes32 _merkleProof) {
        merkleRootOgWhitelist = _merkleProof;
    }

    function setMerkleOgWhitelist(bytes32 _merkleRoot) external onlyOwner nonReentrant{
        merkleRootOgWhitelist = _merkleRoot;
    }

    function checkOgWhitelisted(bytes32[] calldata _merkleProof) public view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        return MerkleProof.verify(_merkleProof, merkleRootOgWhitelist, leaf);
    }

}