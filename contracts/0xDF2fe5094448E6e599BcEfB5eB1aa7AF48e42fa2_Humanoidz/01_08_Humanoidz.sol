// SPDX-License-Identifier: MIT
// Created by [email protected]

pragma solidity ^0.8.12;

import "contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Humanoidz is ERC721A, Ownable, ReentrancyGuard {
	using Strings for uint256;

	uint256 public constant maxSupply = 20000;

	string public baseURI;
    uint256 private mintKey;
    address public theOwner;

	string public baseExtension = ".json";
	uint256 public mintCount = 0;
	uint256 public cost = 0.09 ether;
    
    constructor(string memory _initBaseURI) ERC721A("Serum Labz - Humanoidz", "SLHZ") {
        setBaseURI(_initBaseURI);
        theOwner = msg.sender;
    }

    function setPrivateKey(uint256 mintKeyIn) external onlyOwner {
        mintKey = mintKeyIn;
    }

    function getPrivateKey() external view onlyOwner returns (uint256) {
        return mintKey;
    }

     // ===== Dev mint =====
    function devMint(uint8 quantity) external onlyOwner {
        require(totalSupply() + quantity < maxSupply, "[Supply Error] Not enough left for this mint amount");

        _mint(msg.sender, quantity);        
    }

    // ===== Public mint =====
    function mint(uint8 quantity, uint256 suppliedKey) external payable nonReentrant {
        require(totalSupply() + quantity < maxSupply, "[Supply Error] Not enough left for this mint amount");
        require(mintKey == suppliedKey, "[Mint Security] This NFT can only be minted from the dapp");

        _mint(msg.sender, quantity);   

        // track mints
        mintCount += quantity; 
            
		(bool s1, ) = payable(theOwner).call{value: address(this).balance}("");
		require(s1, "Transfer failed.");
    }

	// override _startTokenId() function ~ line 100 of ERC721A
	function _startTokenId() internal view virtual override returns (uint256) {
		return 1;
	}

	// override _baseURI() function  ~ line 240 of ERC721A
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

	// override tokenURI() function ~ line 228 of ERC721A
	function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
		return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString(), baseExtension)) : "";
	}

	// setBaseURI (must be public)
    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

	// withdraw
	function withdraw() external onlyOwner nonReentrant {
		(bool s1, ) = payable(theOwner).call{value: address(this).balance}("");
		require(s1, "Transfer failed.");
    }

	// recieve
	receive() external payable {
		(bool s1, ) = payable(theOwner).call{value: address(this).balance}("");
		require(s1, "Transfer failed.");
	}

	// fallback
	fallback() external payable {
		(bool s1, ) = payable(theOwner).call{value: address(this).balance}("");
		require(s1, "Transfer failed.");
	}

}