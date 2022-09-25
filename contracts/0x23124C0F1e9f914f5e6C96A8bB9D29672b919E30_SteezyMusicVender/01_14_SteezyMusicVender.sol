// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract SteezyMusicVender is ERC1155Holder, ReentrancyGuard, Ownable {

    bytes32 public merkleRoot;
    mapping(bytes32 => bool) public claimed;
    mapping(uint256 => uint256) public tokenMapping;
    address tokenContract;

    function claimTrack(uint tokenId, uint total, bytes32[] memory proof) external nonReentrant {
        require(merkleRoot != bytes32(0), "Merkle root not set"); 
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, total, tokenId));
        require(!claimed[leaf], "Already claimed");
        require(MerkleProof.verify(proof, merkleRoot, leaf), "Invalid proof");
        claimed[leaf] = true;
        uint realTokenId = tokenMapping[tokenId];
        IERC1155(tokenContract).safeTransferFrom(address(this), msg.sender, realTokenId, total, "");
    }

    function withdraw(address contractAddress, address to, uint tokenId, uint quantity) external onlyOwner {
        IERC1155(contractAddress).safeTransferFrom(address(this), to, tokenId, quantity, "");
    }

    function clearClaimed(address addr, uint tokenId) external onlyOwner {
        bytes32 leaf = keccak256(abi.encodePacked(addr, tokenId));
        claimed[leaf] = false;
    }

    function setMerkleRoot(bytes32 root) external onlyOwner {
        merkleRoot = root;
    }

    function setTokenContract(address addr) external onlyOwner {
        tokenContract = addr;
    }

    function setTokenMapping(uint256 tokenId, uint256 realTokenId) external onlyOwner {
        tokenMapping[tokenId] = realTokenId;
    }
}