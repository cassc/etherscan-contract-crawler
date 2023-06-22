// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ZombieApocalypseCrew is ERC721, ERC721Enumerable, Ownable 
{
    using Strings for string;

    uint public constant MAX_TOKENS = 8585;
    uint public constant NUMBER_RESERVED_TOKENS = 15;
    uint256 public constant PRICE = 15000000000000000; //0.015

    bool public saleIsActive = false;

    uint public reservedTokensMinted = 0;
    string private _baseTokenURI;

    address payable private devguy = payable(0x0F7961EE81B7cB2B859157E9c0D7b1A1D9D35A5D);

    constructor() ERC721("Zombie Apocalypse Crew", "ZAC") 
    {
        _setBaseURI("https://zombieapocalypsecrew.s3.us-west-1.amazonaws.com/md/metadata/");
    }

    function mintToken(uint256 amount) external payable
    {
        require(saleIsActive, "Sale must be active to mint");
        require(amount > 0 && amount <= 5, "Max 5 NFTs");
        require(totalSupply() + amount <= MAX_TOKENS - (NUMBER_RESERVED_TOKENS - reservedTokensMinted), "Purchase would exceed max supply");
        require(msg.value >= PRICE * amount, "Not enough ETH for transaction");

        for (uint i = 0; i < amount; i++) 
        {
            _safeMint(msg.sender, totalSupply() + 1);
        }
    }

    function flipSaleState() external onlyOwner 
    {
        saleIsActive = !saleIsActive;
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
        require(msg.sender == devguy || msg.sender == owner(), "Invalid sender");

        uint devPart = address(this).balance / 100 * 5;
        devguy.transfer(devPart);
        payable(owner()).transfer(address(this).balance);
    }
    
    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
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