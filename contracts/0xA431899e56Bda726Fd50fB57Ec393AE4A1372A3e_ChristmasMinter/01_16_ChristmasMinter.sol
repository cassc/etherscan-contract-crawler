// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./KumaleonDepot.sol";

contract ChristmasMinter is ReentrancyGuard, Ownable {

    bool public isMintActive;
    uint256 public nextTokenId = 1_000_000;
    bytes32 public merkleRoot;
    mapping(address => bool) public mintedMap;
    address public depot;

    constructor(address depot_) {
        depot = depot_;
    }

    function mint(uint256 quantity, bytes32[] memory proof) external nonReentrant {
        require(isMintActive, "ChristmasMinter: Mint is not active");
        require(!mintedMap[msg.sender], "ChristmasMinter: Already claimed");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, quantity));
        require(MerkleProof.verify(proof, merkleRoot, leaf), "ChristmasMinter: Invalid proof");

        mintedMap[msg.sender] = true;

        uint256[] memory ids = new uint256[](quantity);

        for (uint256 i; i < quantity; i++) {
            ids[i] = nextTokenId++;
        }

        KumaleonDepot(depot).mint(ids);
        
        for (uint256 i; i < quantity; i++) {
            KumaleonDepot(depot).transferFrom(address(this), msg.sender, ids[i]);
        }
    }

    function setDepot(address depot_) external onlyOwner {
        depot = depot_;
    }

    function transferDepotOwnership(address owner_) external onlyOwner {
        Ownable(depot).transferOwnership(owner_);
    }

    function setMerkleRoot(bytes32 merkleRoot_) external onlyOwner {
        merkleRoot = merkleRoot_;
    }

    function setIsMintActive(bool isMintActive_) external onlyOwner {
        require(merkleRoot != 0, "ChristmasMinter: Merkle root is not set");
        isMintActive = isMintActive_;
    }
}