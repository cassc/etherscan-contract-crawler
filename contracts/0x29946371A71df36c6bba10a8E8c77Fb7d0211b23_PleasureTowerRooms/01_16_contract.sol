// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

contract PleasureTowerRooms is ERC721, Ownable, DefaultOperatorFilterer {
    using Counters for Counters.Counter;
    Counters.Counter private currentTokenId;

    string private baseURI =
        "https://ipfs.io/ipfs/bafybeiazhovuftcaekugh6y2iyzr3xd45e6rfw34wi6nh6miwjwt7qmy6u/";

    uint256 public constant maxSupply = 300;
    uint256 public totalSupply = 0;
    uint256 public price = 10 ether;

    constructor() ERC721("PleasureTowerRooms", "PTR") {}

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory baseURI_) public onlyOwner {
        baseURI = baseURI_;
    }

    function setPrice(uint256 _price) public onlyOwner {
        price = _price;
    }

    function mint() public payable {
        require(totalSupply < maxSupply, "All NFTs are minted.");

        require(!_exists(totalSupply), "Token already minted");
        require(price <= msg.value, "Invalid value");

        _safeMint(msg.sender, totalSupply);
        totalSupply++;
    }

    function mintAmount(uint256 amount) public onlyOwner {
        require(totalSupply < maxSupply, "All NFTs are minted.");

        while (totalSupply < maxSupply && amount > 0) {
            _safeMint(msg.sender, totalSupply);
            totalSupply++;

            amount--;
        }
    }

    function withdraw() public onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function mintTo(address recipient) public returns (uint256) {
        currentTokenId.increment();
        uint256 newItemId = currentTokenId.current();
        _safeMint(recipient, newItemId);
        return newItemId;
    }

    function setApprovalForAll(address operator, bool approved)
        public
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId)
        public
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}