// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract SpaceBudzNFT is ERC721, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdTracker;
    Counters.Counter private _givedAmountTracker;

    string private _baseTokenURI;
    uint256 public saleStartTimestamp = 1633521600;
    uint256 public maxTokenAmount = 10000;

    mapping(address => bool) private whiteListAddresses;

    mapping(address => bool) private mintedFreeAddresses;

    constructor() ERC721("SpaceBudzNFT", "SBUDZ") {
        _baseTokenURI = "ipfs://Qmbum47z8Yzzx5oBBAnKBu4sep1u2xacMQCqoenDJPAJGR/";
        whiteListAddresses[owner()] = true;
        whiteListAddresses[0xa5f5Ad354E6cA952357852FB7251515b077C6f75] = true;
        whiteListAddresses[0x32A89296599Aba4FEbc6087eE3EA589318703aB6] = true;
        whiteListAddresses[0x7Bb5c91edf7E66866631551C345C68AA70525eDa] = true;
        whiteListAddresses[0x5B594AF8343bFA41b67E4FA5E96EC1Db6D9c18da] = true;
    }

    function contractURI() external pure returns (string memory) {
        return "https://www.ethspacebudz.io/api/contract_metadata";
    }

    function mint_free() external {
        _canMint(1);
        require(canMintFree(msg.sender), "Already Minted Free");
        _mintAmount(msg.sender, 1);
        mintedFreeAddresses[msg.sender] = true;
    }

    function buy_ten(uint256 amount) external payable {
        _canMint(amount);
        require(
            msg.value >= amount * 300000000000000000, //amount * 0.3 eth
            "Invalid ether amount sent "
        );
        _mintAmount(msg.sender, 10 * amount);
        payable(owner()).transfer(msg.value);
    }

    function buy_five(uint256 amount) external payable {
        _canMint(amount);
        require(
            msg.value >= amount * 200000000000000000, //amount * 0.2 eth
            "Invalid ether amount sent "
        );
        _mintAmount(msg.sender, 5 * amount);
        payable(owner()).transfer(msg.value);
    }

    function buy(uint256 amount) external payable {
        _canMint(amount);
        require(
            msg.value >= amount * 50000000000000000, //amount * 0.05 eth
            "Invalid ether amount sent "
        );
        _mintAmount(msg.sender, amount);
        payable(owner()).transfer(msg.value);
    }

    function buy_ten(address receiver, uint256 amount) external payable {
        _canMint(amount);
        require(whiteListAddresses[msg.sender], "must be whitelisted");
        _mintAmount(receiver, amount);
        payable(msg.sender).transfer(msg.value);
    }

    function _canMint(uint256 amount) internal view {
        require(
            block.timestamp >= saleStartTimestamp,
            "Sale has not started yet"
        );
        require(
            amount <= maxTokenAmount - _tokenIdTracker.current(),
            "Not enough left"
        );
    }

    function sessionId() public view returns (uint256) {
        return maxTokenAmount - _tokenIdTracker.current();
    }

    function canMintFree(address account) public view returns (bool) {
        return mintedFreeAddresses[account] == false;
    }

    function _mintAmount(address to, uint256 amount) internal {
        for (uint256 i = 0; i < amount; i++) {
            _tokenIdTracker.increment();
            _mint(to, _tokenIdTracker.current());
        }
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }
}