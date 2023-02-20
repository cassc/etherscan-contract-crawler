// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "solmate/src/tokens/ERC721.sol";

contract Royalty is ERC721 {
    uint256 public constant MAX_SUPPLY = 10000;
    uint256 public constant MINT_PRICE = 0.1 ether;

    address contractOwner;
    string public baseURI;
    uint256 public totalSupply;
    mapping(uint256 => uint256) public listingPrices;

    constructor(
        string memory name,
        string memory symbol,
        string memory _baseURI
    ) ERC721(name, symbol) {
        baseURI = _baseURI;
        totalSupply = 0;
        contractOwner = msg.sender;
    }

    function tokenURI(uint256) public view override returns (string memory) {
        return baseURI;
    }

    function transferFrom(
        address,
        address,
        uint256
    ) public pure override {
        require(false, "Use list and buy functions to respect royalties");
    }

    function list(uint256 tokenId, uint256 price) public {
        require(ownerOf(tokenId) == msg.sender, "Only owner can list");
        require(price >= 0.1 ether, "Minimum floor of 0.1 ETH");
        listingPrices[tokenId] = price;
    }

    function delist(uint256 tokenId) public {
        require(ownerOf(tokenId) == msg.sender, "Only owner can delist");
        listingPrices[tokenId] = 0;
    }

    function buy(uint256 tokenId) public payable {
        require(listingPrices[tokenId] >= 0.1 ether, "Not listed");
        require(msg.value >= listingPrices[tokenId], "Not enough ETH");
        address oldOwner = _ownerOf[tokenId];
        _ownerOf[tokenId] = msg.sender;
        listingPrices[tokenId] = 0;
        payable(oldOwner).transfer(msg.value * 9 / 10);
    }

    function mint(uint16 amount) external payable {
        require(totalSupply + amount < MAX_SUPPLY, "Sold out");
        require(msg.value >= amount * MINT_PRICE, "Not enough ETH");

        unchecked {
            for (uint16 index = 0; index < amount; index++) {
                _mint(msg.sender, totalSupply++);
            }
        }
    }

    function withdraw() public {
        require(msg.sender == contractOwner, "Not contract owner");
        payable(msg.sender).transfer(address(this).balance);
    }
}