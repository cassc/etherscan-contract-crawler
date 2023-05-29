// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./ERC721Optimized.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract BoredAIClub is ERC721Optimized, Ownable, ReentrancyGuard {
    using Strings for uint256;

    uint256 public constant MAX_TOKENS = 10000;
    uint256 public freeMintAmount = 2500;
    uint256 public maxTokensPerTx = 10;
    uint256 public maxFreeTokensPerTx = 1;
    uint256 public maxFreeTokensPerWallet = 1;
    uint256 public mintPrice = 0.05 ether;
    string public _baseTokenURI;
    mapping(address => uint256) public balance;
    
    event BAICMinted(address indexed mintAddress, uint256 indexed tokenId);
    event PermanentURI(string _value, uint256 indexed _id);

    constructor(string memory baseURI) ERC721Optimized("BoredAIClub", "BAIC") {
        _baseTokenURI = baseURI;
    }

    function freezeMetadata(uint256 tokenId, string memory ipfsHash) public {
        require(_exists(tokenId), "Token does not exist");
        require(_msgSender() == ERC721Optimized.ownerOf(tokenId), "You are not a token owner");
	    emit PermanentURI(ipfsHash, tokenId);
	}

    function publicMint(uint256 numberOfTokens) public payable nonReentrant {
        uint256 supply = totalSupply();
        if (supply < freeMintAmount) {
            require(numberOfTokens <= maxFreeTokensPerTx, "Too many tokens per transaction");
            require(balance[_msgSender()] + numberOfTokens <= maxFreeTokensPerWallet, "You will exceed max amount per wallet");
        } else {
            require(numberOfTokens <= maxTokensPerTx, "Too many tokens per transaction");
        }
        require((supply + numberOfTokens) <= MAX_TOKENS, "Purchase would exceed max supply");
        require(getTotalMintPrice(numberOfTokens) == msg.value, "Incorrect Ether amount sent");
        
        for (uint256 i = 0; i < numberOfTokens; i++) {
            _mintSingle(_msgSender());
            balance[_msgSender()] += 1;
        }
    }

    function devMint(address to, uint256 numberOfTokens) public onlyOwner {
        for (uint256 i = 0; i < numberOfTokens; i++) {
            _mintSingle(to);
        }
    }

    function getCurrentMintPrice() public view returns (uint256) {
        return totalSupply() >= freeMintAmount ? mintPrice : 0;
    }

    function getMintPriceForToken(uint256 tokenId) public view returns (uint256) {
        return tokenId >= freeMintAmount ? mintPrice : 0;
    }

    function getTotalMintPrice(uint256 numberOfTokens) public view returns (uint256) {
        require(numberOfTokens > 0, "numberOfTokens must be greater than zero");
        uint256 tokenId = totalSupply();
        uint256 end = tokenId + numberOfTokens;
        require(end <= MAX_TOKENS, "Exceeded max supply");
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

    function setMintPrice(uint256 newPrice) public onlyOwner {
        require(newPrice >= 0, "Price must be greater than zero");
        mintPrice = newPrice;
    }

    function setMaxTokensPerTx(uint256 amount) public onlyOwner {
        require(amount > 0, "Amount must be greater than zero");
        maxTokensPerTx = amount;
    }

    function setFreeMintAmount(uint256 amount) public onlyOwner {
        require(amount >= 0, "Amount must be greater than zero");
        freeMintAmount = amount;
    }

    function setMaxFreeTokensPerTx(uint256 amount) public onlyOwner {
        require(amount >= 0, "Amount must be greater than zero");
        maxFreeTokensPerTx = amount;
    }

    function setMaxFreeTokensPerWallet(uint256 amount) public onlyOwner {
        require(amount >= 0, "Amount must be greater than zero");
        maxFreeTokensPerWallet = amount;
    }

    function setBaseURI(string memory newuri) public onlyOwner {
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
        if (mintIndex < MAX_TOKENS) {
            _safeMint(mintAddress, mintIndex);
            emit BAICMinted(mintAddress, mintIndex);
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