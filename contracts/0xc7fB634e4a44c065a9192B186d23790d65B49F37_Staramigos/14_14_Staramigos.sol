// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./ERC721Op.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract Staramigos is ERC721Op, Ownable, ReentrancyGuard {
    using Strings for uint256;

    uint256 public constant MAX_STRMGS = 20000;
    uint256 public freeMintAmount = 1;
    uint256 public maxTokensPerTx = 1;
    uint256 public maxFreeTokensPerWallet = 3;
    uint256 public mintPrice = 1 ether;
    bool public isAllMetadataFrozen = false;
    string public _baseTokenURI;
    mapping(address => uint256) public balance;
    
    event PermanentURI(string _value, uint256 indexed _id);

    constructor(string memory baseURI) ERC721Op("Staramigos", "STRMGS") {
        _baseTokenURI = baseURI;
    }

    function freezeMetadata(uint256 tokenId, string memory ipfsHash) public {
        require(_exists(tokenId), "Token does not exist");
        require(_msgSender() == ERC721Op.ownerOf(tokenId), "You are not a token owner");
	    emit PermanentURI(ipfsHash, tokenId);
	}

    function freezeAllMetadata() public onlyOwner() {
        isAllMetadataFrozen = true;
    }

    function publicMint(uint256 numberOfTokens) public payable nonReentrant {
        uint256 supply = totalSupply();
        if (supply < 5000) {
            require(balance[_msgSender()] + numberOfTokens <= maxFreeTokensPerWallet, "You will exceed max amount per wallet");
            require(numberOfTokens <= maxTokensPerTx, "Too many tokens per transaction");
        }
        require((supply + numberOfTokens) <= MAX_STRMGS, "Purchase would exceed max supply");
        require(getTotalMintPrice(numberOfTokens) == msg.value, "Incorrect ETH amount sent");
        
        for (uint256 i = 0; i < numberOfTokens; i++) {
            _mintSingle(_msgSender());
            balance[_msgSender()] += 1;
        }
    }

    function getMintPrice() public view returns (uint256) {
        return totalSupply() >= freeMintAmount ? mintPrice : 0;
    }

    function getMintPriceForToken(uint256 tokenId) public view returns (uint256) {
        return tokenId >= freeMintAmount ? mintPrice : 0;
    }

    function getTotalMintPrice(uint256 numberOfTokens) public view returns (uint256) {
        require(numberOfTokens > 0, "numberOfTokens must be greater than zero");
        uint256 tokenId = totalSupply();
        uint256 end = tokenId + numberOfTokens;
        if (end <= freeMintAmount) {
            return 0;
        } else {
            uint256 totalPrice = 0;
            for (; tokenId < end; ++tokenId) {
                totalPrice = totalPrice + getMintPriceForToken(tokenId);
            }
            return totalPrice;
        }
    }

    function setSettings(uint256 newPrice, uint256 freeAmount, uint256 tokensPerTxAmount, uint256 tokensPerWalletAmount) public onlyOwner() {
        require(newPrice >= 0, "Price must be greater than or equal to zero");
        require(freeAmount >= 0, "Free tokens amount must be greater than or equal to zero");
        require(tokensPerTxAmount > 0, "Max tokens per Tx amount must be greater than zero");
        require(tokensPerWalletAmount > 0, "Max tokens per wallet amount must be greater than zero");
        mintPrice = newPrice;
        freeMintAmount = freeAmount;
        maxTokensPerTx = tokensPerTxAmount;
        maxFreeTokensPerWallet = tokensPerWalletAmount;
    }

    function setBaseURI(string memory newuri) public onlyOwner {
        require(!isAllMetadataFrozen, "Metadata has been frozen.");
        _baseTokenURI = newuri;
    }

    function withdraw() public onlyOwner {
        require(address(this).balance > 0, "Insufficient balance");
        Address.sendValue(payable(msg.sender), address(this).balance);
    }

    function withdrawTo(uint256 amount, address payable to) public onlyOwner {
        require(address(this).balance > 0, "Insufficient balance");
        Address.sendValue(to, amount);
    }
    
    function _mintSingle(address mintAddress) private {
        uint256 mintIndex = totalSupply();
        if (mintIndex < MAX_STRMGS) {
            _safeMint(mintAddress, mintIndex);
        }
    }

    function _baseURI() internal view virtual returns (string memory) {
	    return _baseTokenURI;
	}

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "Token does not exist");
        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0	? string(abi.encodePacked(currentBaseURI, tokenId.toString())) : "";
	}
}