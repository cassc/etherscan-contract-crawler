// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract Kungfungus is ERC721, Pausable, Ownable, ERC721Burnable {
    using Counters for Counters.Counter;

    enum State {
        Closed,
        Presale,
        PresaleTwo,
        PublicSale
    }

    Counters.Counter private _tokenIdCounter;

    string private _metadataEndpoint = "https://api.kungfungus.com/tokens/";

    uint256 private _supplyTotal = 10101;

    uint256 private _mintCost = 0.0 ether;

    uint256 private _maxTokensPerAddress = 2;

    mapping(address => uint256) public mintsPerAddress;

    constructor() ERC721("Kung Fungus", "KUNGFUNGUS") {
        _tokenIdCounter.increment();
    }

    function _baseURI() internal view override returns (string memory) {
        return _metadataEndpoint;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function safeMint(address to) internal {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
        mintsPerAddress[to] += 1;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override whenNotPaused {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function setMetadataEndpoint(string memory endpoint) public onlyOwner {
        _metadataEndpoint = endpoint;
    }

    function setMintCost(uint256 cost) public onlyOwner {
        _mintCost = cost;
    }

    function setMaxTokensPerAddress(uint256 value) public onlyOwner {
        _maxTokensPerAddress = value;
    }

    function reservedMint(address to, uint256 quantity) public onlyOwner {
        require(
            _tokenIdCounter.current() + quantity <= _supplyTotal,
            "Not enough NFTs left to mint"
        );

        for (uint256 i = 0; i < quantity; i++) {
            safeMint(to);
        }
    }

    function withdraw(address recipient, uint256 amount) public onlyOwner {
        require(amount <= address(this).balance, "Incorrect amount");

        payable(recipient).transfer(amount);
    }

    function mint(uint256 quantity) public payable {
        require(
            _tokenIdCounter.current() - 1 + quantity <= _supplyTotal,
            "Not enough NFTs left to mint"
        );

        require(
            mintsPerAddress[msg.sender] + quantity <= _maxTokensPerAddress,
            "This address cannot mint more NFTs"
        );

        for (uint256 i = 0; i < quantity; i++) {
            safeMint(msg.sender);
        }
    }

    function mintCost() public view returns (uint256) {
        return _mintCost;
    }

    function getMintedTotal() public view returns (uint256) {
        return _tokenIdCounter.current() - 1;
    }

    function getMaxTokensPerAddress() public view returns (uint256) {
        return _maxTokensPerAddress;
    }

    function totalSupply() public view returns (uint256) {
        return _supplyTotal;
    }
}