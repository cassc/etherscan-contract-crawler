// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./Farm.sol";

contract FarmMinter is Ownable, Pausable {
    
    Farm public farm;

    uint256 public mintPrice = 0.075 ether;
    address public salesWallet = 0x99613F187fC3916b1Bd6FaA2267b0ee0b3447D82;
    uint256 public startTimeWhitelist;
    uint256 public startTime;
    bytes32 public merkleRoot;

    constructor(Farm _farm) {
        farm = _farm;
    }

    // views

    function mintingStartedWhitelist() public view returns (bool) {
        return startTimeWhitelist != 0 && block.timestamp >= startTimeWhitelist;
    }

    function mintingStarted() public view returns (bool) {
        return startTime != 0 && block.timestamp >= startTime;
    }

    // mint

    function mintWhitelist(bytes32[] calldata _merkleProof, uint256 qty) external payable whenNotPaused {
        // check basic requirements
        require(merkleRoot != 0, "Missing root configuration");
        require(mintingStartedWhitelist(), "Cannot mint right now");
        require (!mintingStarted(), "Whitelist minting is closed");

        // check if address belongs in whitelist
        bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
        require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), "This address is not on the whitelist");

        // check price
        require(msg.value >= mintPrice * qty, "Not enough ETH");

        // mint
        payable(salesWallet).transfer(msg.value);
        farm.mint(_msgSender(), qty);
    }

    function mint(uint256 qty) external payable whenNotPaused {
        // check basic requirements
        require (mintingStarted(), "Cannot mint right now");

        // check price
        require (msg.value >= mintPrice * qty, "Not enough ETH");

        // mint
        payable(salesWallet).transfer(msg.value);
        farm.mint(_msgSender(), qty);
    }

    // owner

    function setMintPrice(uint256 _mintPrice) external onlyOwner {
        mintPrice = _mintPrice;
    }

    function setSalesWallet(address _salesWallet) external onlyOwner {
        salesWallet = _salesWallet;
    }

    function setStartTimeWhitelist(uint256 _startTimeWhitelist) external onlyOwner {
        startTimeWhitelist = _startTimeWhitelist;
    }

    function setStartTime(uint256 _startTime) external onlyOwner {
        startTime = _startTime;
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }
}