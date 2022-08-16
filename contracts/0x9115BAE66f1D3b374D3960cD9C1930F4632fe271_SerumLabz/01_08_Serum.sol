// SPDX-License-Identifier: MIT
// Created by [email protected]

pragma solidity ^0.8.11;

import "contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract SerumLabz is ERC721A, Ownable, ReentrancyGuard {
	using Strings for uint256;
	
	uint256 public constant maxSupply = 20000;

	string public baseURI;
    uint256 private mintKey;
    address public theOwner;

    bool public publicMintStarted = false;
	string public baseExtension = ".json";
	uint256 public mintCount = 0;
	uint256 public cost = 0.09 ether;

    address public SLPOOLAddress = payable(0x772CAC9Bbccd07Ef28b1c6da3AEc4E62611C43Ef);
    address public FUTDEVAddress = payable(0xD84E16DC99763A99d4E08c6e267A26E9A4fe7444);
    address public MARKETAddress = payable(0x4A938B9D5b631f26aFBC014f7beB234090350D40);
    address public SERUMAddress = payable(0x8798eDF9dc9A46511D9EFaD6418Ead87f3A6624f);
    
    constructor(string memory _initBaseURI) ERC721A("SerumLabz", "SL") {
        setBaseURI(_initBaseURI);
        theOwner = msg.sender;
    }

    modifier whenPublicMint() {
        require(publicMintStarted, "[Mint Status Error] Public mint not active.");
        _;
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
    function mint(uint8 quantity, uint256 suppliedKey) external payable nonReentrant whenPublicMint {
        require(msg.value >= cost * quantity, "[Value Error] Not enough funds supplied for mint");
        require(totalSupply() + quantity < maxSupply, "[Supply Error] Not enough left for this mint amount");
        require(mintKey == suppliedKey, "[Mint Security] This NFT can only be minted from the dapp");

        _mint(msg.sender, quantity);   

        // track mints
        mintCount += quantity;     

        sendFunds(msg.value);
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

	// ---Helper Functions / Modifiers---
    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

	// sendFunds function
	function sendFunds(uint256 _totalMsgValue) public payable {
		(bool s1,) = payable(SLPOOLAddress).call{value: (_totalMsgValue * 20) / 100}("");
		(bool s2,) = payable(FUTDEVAddress).call{value: (_totalMsgValue * 50) / 100}("");
		(bool s3,) = payable(MARKETAddress).call{value: (_totalMsgValue * 15) / 100}("");
		(bool s4,) = payable(SERUMAddress).call{value: (_totalMsgValue * 15) / 100}("");
		require(s1 && s2 && s3 && s4, "Transfer failed.");
	}

    function toggleMintStatus() external onlyOwner {
        publicMintStarted = !publicMintStarted;
    }

    function startPublicMint() external onlyOwner {
        publicMintStarted = true;
    }

    function setMintPrice(uint256 value) external onlyOwner {
        cost = value;
    }

	// setBaseURI (must be public)
    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

	// withdraw
	function withdraw() external onlyOwner nonReentrant {
		sendFunds(address(this).balance);
	}

	// recieve
	receive() external payable {
		sendFunds(address(this).balance);
	}

	// fallback
	fallback() external payable {
		sendFunds(address(this).balance);
	}

}