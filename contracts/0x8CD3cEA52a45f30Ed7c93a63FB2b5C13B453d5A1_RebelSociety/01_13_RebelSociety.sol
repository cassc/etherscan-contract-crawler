// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract RebelSociety is ERC721, ERC721Enumerable, Ownable 
{
    using Strings for string;

    uint public constant MAX_TOKENS = 7000;
    uint public constant NUMBER_RESERVED_TOKENS = 100;
    uint public constant PRE_SALE_MAX_TOKENS = 888;
    uint256 public PRICE = 80000000000000000; //0.08 eth in wei
    uint256 public constant PRICE_PRE_SALE = 60000000000000000; //0.06 eth in wei
    
    address payable private recipient1 = payable(0x0F7961EE81B7cB2B859157E9c0D7b1A1D9D35A5D);
    
    bool public saleIsActive = false;
    bool public preSaleIsActive = false;
    
    uint public limitPerWallet = 4;

    uint public reservedTokensMinted = 0;
    uint public preSaleSupply = 0;
    string private _baseTokenURI;

    constructor() ERC721("Rebel Society", "RBL") {}

    function mintToken(uint256 amount) external payable
    {
        require(saleIsActive, "Sale must be active to mint");
        require(balanceOf(msg.sender) + amount <= limitPerWallet, "Limit per wallet acchieved, sale not allowed");
        require(totalSupply() + amount <= MAX_TOKENS - (NUMBER_RESERVED_TOKENS - reservedTokensMinted), "Purchase would exceed max supply");
        require(msg.value >= PRICE * amount, "Not enough ETH for transaction");
        require(msg.sender == tx.origin, "No transaction from smart contracts!");
        
        for (uint i = 0; i < amount; i++) 
        {
            _safeMint(msg.sender, totalSupply() + 1);
        }
    }
    
    function mintTokenPreSale(uint256 amount) external payable
    {
        require(preSaleIsActive, "Pre-sale must be active to mint");
        require(balanceOf(msg.sender) + amount <= 2, "Limit is 2 tokens per wallet on pre-sale, sale not allowed");
        require(preSaleSupply + amount <= PRE_SALE_MAX_TOKENS, "Purchase would exceed max supply for pre-sale");
        require(totalSupply() + amount <= MAX_TOKENS - (NUMBER_RESERVED_TOKENS - reservedTokensMinted), "Purchase would exceed max supply");
        require(msg.value >= PRICE_PRE_SALE * amount, "Not enough ETH for transaction");
        require(msg.sender == tx.origin, "No transaction from smart contracts!");
        
        for (uint i = 0; i < amount; i++) 
        {
            _safeMint(msg.sender, totalSupply() + 1);
            preSaleSupply++;
        }
    }
    
    function setPrice(uint256 newPrice) external onlyOwner
    {
        PRICE = newPrice;
    }
    
    function setLimitPerWallet(uint newLimitPerWallet) external onlyOwner
    {
        limitPerWallet = newLimitPerWallet;
    }

    function flipSaleState() external onlyOwner 
    {
        saleIsActive = !saleIsActive;
    }

    function flipPreSaleState() external onlyOwner 
    {
        preSaleIsActive = !preSaleIsActive;
    }

    function mintReservedTokens(address to, uint256 amount) external onlyOwner 
    {
        require(reservedTokensMinted + amount <= NUMBER_RESERVED_TOKENS, "This amount is more than max allowed");

        for (uint i = 0; i < amount; i++) 
        {
            _safeMint(to, totalSupply() + 1);
            reservedTokensMinted++;
        }
    }

    function withdraw() external 
    {
        require(msg.sender == recipient1 || msg.sender == owner(), "Invalid sender");

        uint part = address(this).balance / 100 * 7;
        recipient1.transfer(part);
        payable(owner()).transfer(address(this).balance);
    }
    
    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }
    
    function supportsInterface(bytes4 interfaceId) public view
        override(ERC721, ERC721Enumerable) returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    ////
    //URI management part
    ////
    
    function _setBaseURI(string memory baseURI) internal virtual {
        _baseTokenURI = baseURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }
    
    function setBaseURI(string memory baseURI) external onlyOwner {
        _setBaseURI(baseURI);
    }
  
    function tokenURI(uint256 tokenId) public view override(ERC721) returns (string memory) {
        string memory _tokenURI = super.tokenURI(tokenId);
        return bytes(_tokenURI).length > 0 ? string(abi.encodePacked(_tokenURI, ".json")) : "";
    }
}