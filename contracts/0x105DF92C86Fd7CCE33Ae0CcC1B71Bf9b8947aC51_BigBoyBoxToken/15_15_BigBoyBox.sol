// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

// Errors
error BigBoyBoxToken__AllTokensAreMinted();
error BigBoyBoxToken__CannotMintLegendaryNFT();
error BigBoyBoxToken__InsufficientETHAmount();

contract BigBoyBoxToken is ERC721, Pausable, Ownable, ERC721Burnable {
    using Counters for Counters.Counter;

    Counters.Counter private s_tokenIdCounter;
    uint256 private s_supply = 50;
    // The id of the legendary token
    uint256 private s_legendaryTokenId = 1000;
    // The id of the legendary companion token
    uint256 private s_legendaryCompanionTokenId = 999;
    uint256 private s_mintPrice = 0.11 ether;
    string private s_baseTokenURI;

    event NftMinted(uint256 indexed tokenId, address minter);

    constructor(string memory baseURI) ERC721("BigBoyBox", "BBB") {
        setBaseURI(baseURI);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return s_baseTokenURI;
    }

    function setBaseURI(string memory _baseTokenURI) public onlyOwner {
        s_baseTokenURI = _baseTokenURI;
    }

    function addSupply(uint256 _amount) public onlyOwner {
        s_supply += _amount;
    }

    function setMintPrice(uint256 _newMintPrice) public onlyOwner {
        s_mintPrice = _newMintPrice;
    }

    function mint(address to) public payable {
        if (s_tokenIdCounter.current() >= s_supply) {
            revert BigBoyBoxToken__AllTokensAreMinted();
        }

        if (msg.value < s_mintPrice) {
            revert BigBoyBoxToken__InsufficientETHAmount();
        }

        uint256 tokenId = s_tokenIdCounter.current();
        s_tokenIdCounter.increment();

        // If the token id is equal to the legendary token id, return error
        if (tokenId == s_legendaryTokenId) {
            revert BigBoyBoxToken__CannotMintLegendaryNFT();
        }

        // If the token id is equal to the legendary companion token id,
        // mint both the legendary companion token and the legendary token
        if (tokenId == s_legendaryCompanionTokenId) {
            s_tokenIdCounter.increment();
            _safeMint(to, tokenId);
            _safeMint(to, s_legendaryTokenId);
        } else {
            _safeMint(to, tokenId);
        }
        emit NftMinted(tokenId, msg.sender);
    }

    function mintAmount(uint256 _amount) public payable {
        if (msg.value < s_mintPrice * _amount) {
            revert BigBoyBoxToken__InsufficientETHAmount();
        }
        for (uint256 i = 0; i < _amount; i++) {
            mint(msg.sender);
        }
    }

    function mintOwner(address to) public payable onlyOwner {
        if (s_tokenIdCounter.current() >= s_supply) {
            revert BigBoyBoxToken__AllTokensAreMinted();
        }

        uint256 tokenId = s_tokenIdCounter.current();
        s_tokenIdCounter.increment();

        // If the token id is equal to the legendary companion token id,
        // mint both the legendary companion token and the legendary token
        if (tokenId == s_legendaryCompanionTokenId) {
            s_tokenIdCounter.increment();
            _safeMint(to, tokenId);
            _safeMint(to, s_legendaryTokenId);
        } else {
            _safeMint(to, tokenId);
        }
        emit NftMinted(tokenId, msg.sender);
    }

    function mintAmountOwner(uint256 _amount) public payable onlyOwner {
        for (uint256 i = 0; i < _amount; i++) {
            mintOwner(msg.sender);
        }
    }

    function withdraw() public payable onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No ether left to withdraw");

        (bool success, ) = (msg.sender).call{value: balance}("");
        require(success, "Transfer failed.");
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    // An override that disables the transfer of NFTs if the smartcontract is paused
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal override whenNotPaused {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function setLegendaryTokenId(uint256 _legendaryTokenId) public onlyOwner {
        s_legendaryTokenId = _legendaryTokenId;
    }

    function setLegendaryCompanionTokenId(uint256 _legendaryCompanionTokenId) public onlyOwner {
        s_legendaryCompanionTokenId = _legendaryCompanionTokenId;
    }

    function getSupply() public view returns (uint256) {
        return s_supply;
    }

    function getLegendaryId() public view returns (uint256) {
        return s_legendaryTokenId;
    }

    function getLegendaryCompanionId() public view returns (uint256) {
        return s_legendaryCompanionTokenId;
    }

    function getPrice() public view returns (uint256) {
        return s_mintPrice;
    }

    function getBaseURI() public view returns (string memory) {
        return s_baseTokenURI;
    }
}