// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Bulldroids is ERC721Enumerable, Ownable 
{
    using Strings for string;

    uint public MAX_TOKENS = 10000;
    uint public constant NUMBER_RESERVED_TOKENS = 250;
    uint256 public PRICE = 50000000000000000; //0.05

    uint public perAddressLimit = 4;
    
    bool public saleIsActive = false;
    bool public revealed = false;

    uint public reservedTokensMinted = 0;
    string private _baseTokenURI;
    string public notRevealedUri;

    constructor() ERC721("Bulldroids", "K9") {}

    function mintToken(uint256 amount) external payable
    {
        require(msg.sender == tx.origin, "No transaction from smart contracts!");
        require(saleIsActive, "Sale must be active to mint");
        require(amount > 0 && amount <= 10, "Max 10 NFTs per transaction");
        require(totalSupply() + amount <= MAX_TOKENS - (NUMBER_RESERVED_TOKENS - reservedTokensMinted), "Purchase would exceed max supply");
        require(msg.value >= PRICE * amount, "Not enough ETH for transaction");
        require(balanceOf(msg.sender) + amount <= perAddressLimit, "Max NFT per address exceeded");

        for (uint i = 0; i < amount; i++) 
        {
            _safeMint(msg.sender, totalSupply() + 1);
        }
    }

    function flipSaleState() external onlyOwner 
    {
        saleIsActive = !saleIsActive;
    }

    function setPrice(uint256 newPrice) external onlyOwner 
    {
        PRICE = newPrice;
    }

    function setMax(uint newLimit) external onlyOwner 
    {
        MAX_TOKENS = newLimit;
    }

    function setPerAddressLimit(uint newLimit) external onlyOwner 
    {
        perAddressLimit = newLimit;
    }

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    function reveal() public onlyOwner {
        revealed = true;
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
        address dev = 0x0F7961EE81B7cB2B859157E9c0D7b1A1D9D35A5D;
        require(msg.sender == dev || msg.sender == owner(), "Invalid sender");

        uint256 value1 = address(this).balance / 100 * 7;
        uint256 value2 = address(this).balance / 100 * 4;
        uint256 value3 = address(this).balance / 100 * 39;
        uint256 value4 = address(this).balance / 100 * 20;
        uint256 value5 = address(this).balance / 100 * 15;
        
        (bool success, ) = dev.call{value: value1}("");
        (bool success2, ) = 0x820c36371d66c0aE54cfED16650c288B7C933c51.call{value: value2}("");
        (bool success3, ) = 0x4a7789B90B4818D68D7D34DfdCcB7469eE2dC04c.call{value: value3}("");
        (bool success4, ) = 0xF8B4d0c5aAb25E565405f992c9817d865F107d38.call{value: value4}("");
        (bool success5, ) = 0x027768383ACEF2162FdE8229180768A122CDFeCa.call{value: value5}("");
        (bool success6, ) = 0xE1506ede240CC82D482B616DBc6af7C374352adb.call{value: address(this).balance}("");

        require(success, "Transfer 1 failed");
        require(success2, "Transfer 2 failed");
        require(success3, "Transfer 3 failed");
        require(success4, "Transfer 4 failed");
        require(success5, "Transfer 5 failed");
        require(success6, "Transfer 6 failed");
    }
    
    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }
    
    function supportsInterface(bytes4 interfaceId) public view
        override(ERC721Enumerable) returns (bool)
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
  
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
        _exists(tokenId),
        "ERC721Metadata: URI query for nonexistent token"
        );
        
        if(revealed == false) {
            return notRevealedUri;
        }

        string memory _tokenURI = super.tokenURI(tokenId);
        return bytes(_tokenURI).length > 0 ? string(abi.encodePacked(_tokenURI, ".json")) : "";
    }
}