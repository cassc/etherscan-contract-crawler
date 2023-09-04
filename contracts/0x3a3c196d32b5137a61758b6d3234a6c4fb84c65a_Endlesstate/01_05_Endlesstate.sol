// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;


import "@openzeppelin/contracts/access/Ownable.sol";
import "erc721a/contracts/ERC721A.sol";

// Author: @sssobeit
contract Endlesstate is ERC721A, Ownable {

    uint PRICE = 0 ether;

    // MAX_AMOUNT
    uint maxSupply;
    uint maxBatchSize;


    constructor(uint _price, address to) ERC721A("Endlesstate", "E-State") {

        maxBatchSize = 150;
        maxSupply = 10000;
        PRICE = _price;
        mint(150, to);
        transferOwnership(0xaa81a993EF8Aa3eE4EF4a20426126f2F6A3cF9d8);
    }

    function mint(uint _count, address _to) public payable {

        require(_count > 0, "mint at least one token");
        require(_totalMinted() + _count <= maxSupply, "not enough tokens left");
        require(_count <= maxBatchSize, "MAX BATCH SIZE");
        require(msg.value == _count * PRICE || msg.sender == owner(), "PRICE");

        _mint(_to, _count);
    }

    function setBaseURI(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    function setPrice(uint _price) external onlyOwner {
        PRICE = _price;
    }

    function withdraw() public onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
}