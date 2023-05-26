// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./ERC721Optimized.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract AIMoonbirds is ERC721Optimized, Ownable, ReentrancyGuard {
    using Strings for uint256;

    uint256 public constant MAX_MBAI = 10000;
    uint256 public maxMBAIPurchase = 10;
    uint256 public MBAIPrice = 100 ether;
    string public _baseMBAIURI;
    
    event MBAIMinted(address indexed mintAddress, uint256 indexed tokenId);
    event PermanentURI(string _value, uint256 indexed _id);

    constructor(string memory baseURI) ERC721Optimized("AIMoonbirds", "MBAI") {
        _baseMBAIURI = baseURI;
    }

    function giveAway(address to, uint256 numberOfTokens) public onlyOwner {
        for (uint256 i = 0; i < numberOfTokens; i++) {
            createCollectible(to);
        }
    }

    function withdraw() public onlyOwner {
        require(address(this).balance > 0, "Insufficient balance");
        Address.sendValue(payable(msg.sender), address(this).balance);
    }

    function withdrawTo(uint256 amount, address payable to) public onlyOwner {
        require(address(this).balance > 0, "Insufficient balance");
        Address.sendValue(to, amount);
    }

    function setBaseURI(string memory newuri) public onlyOwner {
        _baseMBAIURI = newuri;
    }

    function setMintPrice(uint256 newPrice) public onlyOwner {
        require(newPrice >= 0, "MBAI price must be greater than zero");
        MBAIPrice = newPrice;
    }

    function mintMBAI(uint256 numberOfTokens) public payable nonReentrant {
        require((MBAIPrice * numberOfTokens) <= msg.value, "Ether value sent is not correct");
        require(numberOfTokens <= maxMBAIPurchase, "You can mint max 10 MBAIs per transaction");
        require((totalSupply() + numberOfTokens) <= MAX_MBAI, "Purchase would exceed max supply of MBAIs");
        
        for (uint256 i = 0; i < numberOfTokens; i++) {
            createCollectible(_msgSender());
        }
    }

    function createCollectible(address mintAddress) private {
        uint256 mintIndex = totalSupply();
        if (mintIndex < MAX_MBAI) {
            _safeMint(mintAddress, mintIndex);
            emit MBAIMinted(mintAddress, mintIndex);
        }
    }

    function freezeMetadata(uint256 tokenId, string memory ipfsHash) public {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        require(_msgSender() == ERC721Optimized.ownerOf(tokenId), "Caller is not a token owner");
	    emit PermanentURI(ipfsHash, tokenId);
	}

    function _baseURI() internal view virtual returns (string memory) {
	    return _baseMBAIURI;
	}

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: Nonexistent token");
        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0	? string(abi.encodePacked(currentBaseURI, tokenId.toString())) : "";
	}
}