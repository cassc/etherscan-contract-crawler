// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract Truty is ERC721, ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    uint256 public price = 33000000000000000;
    uint256 constant MAX_SUPPLY = 10000;
    uint256 constant MAX_BUY = 20;
    bool public isSaleActive = false;
    string public baseURI = "ipfs://";

    constructor() ERC721("Truty", "TRU") {}

    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory _newbaseURI) public onlyOwner {
        baseURI = _newbaseURI;
    }

    function setPrice(uint _price) public onlyOwner {
        price = _price;
    }

    function reserveNFTs() public onlyOwner {
        for (uint i = 0; i < 30; i++) {
            uint256 tokenId = _tokenIdCounter.current();
            _tokenIdCounter.increment();
            _safeMint(msg.sender, tokenId);
        }
    }

    function payToMint(uint256 amount) public payable {
        require(isSaleActive, "Sale is not active");
        require(amount <= MAX_BUY, "Cannot buy more than 20 tokens");
        require(msg.value >= price * amount, "You need to pay up");
        require(
            totalSupply() + amount <= MAX_SUPPLY,
            "Purchase would exceed max supply"
        );

        for (uint i = 0; i < amount; i++) {
            uint256 tokenId = _tokenIdCounter.current();
            _tokenIdCounter.increment();
            _safeMint(msg.sender, tokenId);
        }
    }

    function flipSaleState() public onlyOwner {
        isSaleActive = !isSaleActive;
    }

    ///

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}