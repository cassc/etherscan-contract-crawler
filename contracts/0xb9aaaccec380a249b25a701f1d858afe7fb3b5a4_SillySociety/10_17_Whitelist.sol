// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Whitelist is Ownable , ReentrancyGuard{
    
    modifier isYouAreWhitelisted(bytes32[] calldata _merkleProof) {
        require(checkWhitelisted(_merkleProof), "You are not whitelisted");
        _;
    }

    bytes32 public merkleRootWhitelist;

    constructor(bytes32 _merkleProof) {
        merkleRootWhitelist = _merkleProof;
    }

    function setMerkleWhitelist(bytes32 _merkleRoot) external onlyOwner nonReentrant{
        merkleRootWhitelist = _merkleRoot;
    }

    function checkWhitelisted(bytes32[] calldata _merkleProof) public view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        return MerkleProof.verify(_merkleProof, merkleRootWhitelist, leaf);
    }

}