// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "./ERC721Optimized.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract AINightbirdsRaffle is ERC721Optimized, Ownable, ReentrancyGuard {
    uint256 public constant MAX_TOKENS = 10000;
    uint256 public mintPrice = 0.01 ether;
    string public tokenMetaURI;
    bool isSaleActive = false;
    
    event RaffleTicketMinted(address indexed mintAddress, uint256 indexed tokenId);

    constructor(string memory _tokenURI) ERC721Optimized("AINightbirdsRaffle", "AINBR") {
        tokenMetaURI = _tokenURI;
    }

    function publicMint(uint256 numberOfTokens) public payable nonReentrant {
        require(isSaleActive, "Sale is not active");
        require((mintPrice * numberOfTokens) <= msg.value, "Ether value sent is not correct");
        require((totalSupply() + numberOfTokens) <= MAX_TOKENS, "Purchase would exceed max supply of tokens");
        for (uint256 i = 0; i < numberOfTokens; i++) {
            _mintSingle(_msgSender());
        }
    }

    function devMint(address to, uint256 numberOfTokens) public onlyOwner {
        for (uint256 i = 0; i < numberOfTokens; i++) {
            _mintSingle(to);
        }
    }

    function setMintPrice(uint256 newPrice) public onlyOwner {
        mintPrice = newPrice;
    }

    function setTokenURI(string memory newUri) public onlyOwner {
        tokenMetaURI = newUri;
    }

     function flipSaleState() public onlyOwner {
        isSaleActive = !isSaleActive;
    }

    function withdrawTo(uint256 amount, address payable to) public onlyOwner {
        require(address(this).balance > 0, "Insufficient balance");
        Address.sendValue(to, amount);
    }
    
    function _mintSingle(address mintAddress) private {
        uint256 mintIndex = totalSupply();
        if (mintIndex < MAX_TOKENS) {
            _safeMint(mintAddress, mintIndex);
            emit RaffleTicketMinted(mintAddress, mintIndex);
        }
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "Token does not exist");
        return tokenMetaURI;
	}
}