// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract DIM is Ownable, ERC721A {
    constructor() ERC721A("Drink In Mansion", "DIM") {
        maxCollectionSize = 3650;
        maxMintBatchSize = 50;
        publicSaleMintPrice = 100 ether;
        allowlistMintPrice = 0 ether;
        baseTokenURI = "";
    }

    string public provenanceHash;
    uint256 public immutable maxCollectionSize;
    uint256 public maxMintBatchSize;
    uint256 public publicSaleMintPrice;
    uint256 public allowlistMintPrice;
    string public baseTokenURI;

    function setBaseTokenURI(string calldata _baseTokenURI) external onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function setMaxMintBatchSize(uint256 _maxMintBatchSize) external onlyOwner {
        maxMintBatchSize = _maxMintBatchSize;
    }

    function setPublicSaleMintPrice(uint256 _publicSaleMintPrice) external onlyOwner {
        publicSaleMintPrice = _publicSaleMintPrice;
    }

    function setAllowlistMintPrice(uint256 _allowlistMintPrice) external onlyOwner {
        allowlistMintPrice = _allowlistMintPrice;
    }

    mapping(address => uint256) public allowlist;

    function addAllowlistMembers(address[] memory addresses, uint256[] memory numSlots) external onlyOwner {
        require(addresses.length == numSlots.length, "params length not match");
        for (uint256 i = 0; i < addresses.length; i++) allowlist[addresses[i]] = numSlots[i];
    }

    function removeAllowlistMembers(address[] memory addresses) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) delete allowlist[addresses[i]];
    }

    function setProvenanceHash(string memory _provenanceHash) public onlyOwner {
        provenanceHash = _provenanceHash;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function totalMinted() public view returns (uint256) {
        return _totalMinted();
    }

    function exists(uint256 tokenId) public view returns (bool) {
        return _exists(tokenId);
    }

    function publicSaleMint(uint256 quantity) external payable {
        checkMint(quantity, publicSaleMintPrice);
        _safeMint(msg.sender, quantity);
    }

    function allowlistMint(uint256 quantity) external payable {
        require(allowlist[msg.sender] > 0, "not eligible for allowlist mint");
        require(allowlist[msg.sender] >= quantity, "allowlist quantity exceed");
        checkMint(quantity, allowlistMintPrice);
        allowlist[msg.sender] -= quantity;
        _safeMint(msg.sender, quantity);
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function checkMint(uint256 quantity, uint256 price) private {
        require(quantity <= maxMintBatchSize, "quantity exceed max batch size");
        require(msg.value >= price * quantity, "need to send more ETH");
        require(totalMinted() + quantity <= maxCollectionSize, "nft reached max supply");
    }
}