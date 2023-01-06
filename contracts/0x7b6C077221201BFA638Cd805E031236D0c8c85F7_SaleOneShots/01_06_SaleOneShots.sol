// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./lib/ISarugamiOneShots.sol";

contract SaleOneShots is Ownable, ReentrancyGuard {
    bytes32 public merkleRoot = "0x";
    bool public isMintActive = false;

    mapping(address => uint256) public walletCount;

    ISarugamiOneShots public sarugamiOneShots;

    constructor(
        address sarugamiOneShotAddress
    ) {
        sarugamiOneShots = ISarugamiOneShots(sarugamiOneShotAddress);
    }

    function mint(bytes32[] calldata merkleProof) public nonReentrant {
        require(isMintActive == true, "Mint not open");
        require(isWalletListed(merkleProof, msg.sender) == true, "Invalid proof, your wallet isn't white listed");
        require(walletCount[msg.sender] < 1, "You already minted yours");

        walletCount[msg.sender] += 1;
        sarugamiOneShots.mint(msg.sender, 1);
    }

    function isWalletListed(
        bytes32[] calldata merkleProof,
        address wallet
    ) private view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(wallet));
        return MerkleProof.verify(merkleProof, merkleRoot, leaf);
    }

    function changeMintStatus() external onlyOwner {
        isMintActive = !isMintActive;
    }

    function setMerkleTreeRoot(bytes32 newMerkleRoot) external onlyOwner {
        merkleRoot = newMerkleRoot;
    }

    function removeDustFunds(address treasury) external onlyOwner {
        (bool success,) = treasury.call{value : address(this).balance}("");
        require(success, "funds were not sent properly to treasury");
    }
}