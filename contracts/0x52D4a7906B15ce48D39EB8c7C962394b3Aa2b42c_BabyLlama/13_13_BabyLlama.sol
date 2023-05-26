// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract BabyLlama is ERC721Enumerable, Ownable {
    using Strings for uint256;
    
    uint256 public constant GIFT_LLAMA = 77;
    uint256 public constant ADOPT_LLAMA = 7700;
    uint256 public constant MAX_LLAMA = ADOPT_LLAMA + GIFT_LLAMA;

    uint256 private _price = 0.05 ether;
    string private _baseTokenURI;
    uint256 private _adoptTime = 1630339200;
    uint256 private _numberOfGiftSent = 0;
    
    address private newDaddy = 0xc2e7E4bC6De670566DC9847b27f37c33544842A4;

    constructor(string memory name, string memory symbol) ERC721(name, symbol) {
        transferOwnership(newDaddy);
    }

    function airdropForCommunity( address [] memory recipients ) public onlyOwner{
        require(recipients.length + _numberOfGiftSent < GIFT_LLAMA + 1, "gift Only 77");
        uint256 numberOfGift = _numberOfGiftSent;        
        for( uint256 i ; i < recipients.length; i++ ){
            _safeMint(recipients[i], numberOfGift + i );
            _numberOfGiftSent += 1;
        }
    }

    function adopt(uint256 num) public payable {
        uint256 adopted = GIFT_LLAMA - _numberOfGiftSent + totalSupply();
        require(msg.value == _price * num, "invalid value");
        require(_adoptTime <= block.timestamp, "not available for public sale");
        require(adopted + num <= MAX_LLAMA, "you can not exceed over 7777");
        require(num <= 20, "20 is the maximum");

        for (uint256 i; i < num; i++) {
            _safeMint(msg.sender, adopted + i);
        }
        withdraw();
    }

    function numberOfGiftSent() public view returns( uint256 ){
        return _numberOfGiftSent;
    }

    function tokensOfOwner(address owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(owner);
        uint256[] memory tokenIds = new uint256[](tokenCount);
        for (uint256 i = 0; i < tokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(owner, i);
        }
        return tokenIds;
    }

    function price() public view returns (uint256) {
        return _price;
    }

    function updatePrice(uint256 newPrice) public onlyOwner {
        _price = newPrice;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    function baseTokenURI() public view returns (string memory) {
        return _baseTokenURI;
    }

    function withdraw() public payable {
        require(payable(owner()).send(address(this).balance));
    }
    
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        if( bytes(baseURI).length == 0 ){
            return "https://gateway.pinata.cloud/ipfs/QmV5qDukjHBTRAmQ59avhzVEh49TNv7ybZaokD3uDuVfV6";
        }
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }
}