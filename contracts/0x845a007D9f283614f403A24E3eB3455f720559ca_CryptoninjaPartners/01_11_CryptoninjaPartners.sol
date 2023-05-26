// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {ERC721A} from 'erc721a/contracts/ERC721A.sol';
import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';

error MintPaused();
error LimitedMintPaused();
error MintReachedMaxSupply();
error MintReachedMaxMintSupply();
error BurnAndLimitedMintCallerNotOwner();

contract CryptoninjaPartners is ERC721A('CryptoNinjaPartners', 'CNP'), Ownable {
    address public constant withdrawAddress = 0x0a2C099044c088A431b78a0D6Bb5A137a5663297;
    uint256 public maxSupply = 22222;
    uint256 public mintCost = 0.001 ether;
    uint256 public limitedMintCost = 0.001 ether;
    uint256 public maxMintSupply = 3;
    bool public paused = true;
    bool public limitedMintPaused = true;

    string public baseURI = 'https://data.cryptoninjapartners.com/json/';
    string public metadataExtentions = '.json';

    constructor() {
        _safeMint(withdrawAddress, 1000);
    }

    function mint(uint256 quantity) external payable {
        if (paused) revert MintPaused();
        if (totalSupply() + quantity > maxSupply) revert MintReachedMaxSupply();
        if (quantity > maxMintSupply) revert MintReachedMaxMintSupply();
        if (msg.sender != owner()) require(msg.value >= mintCost * quantity);

        _safeMint(msg.sender, quantity);
    }

    function burnAndLimitedMint(uint256[] memory burnTokenIds) external payable {
        if (limitedMintPaused) revert LimitedMintPaused();
        if (_currentIndex + burnTokenIds.length > maxSupply) revert MintReachedMaxSupply();
        if (msg.sender != owner()) {
            require(msg.value >= mintCost * burnTokenIds.length);
        }

        for (uint256 i = 0; i < burnTokenIds.length; i++) {
            uint256 tokenId = burnTokenIds[i];
            if (_msgSender() != ownerOf(tokenId)) revert BurnAndLimitedMintCallerNotOwner();

            _burn(tokenId);
        }
        _safeMint(_msgSender(), burnTokenIds.length);
    }

    function pause(bool _state) public onlyOwner {
        paused = _state;
    }

    function limitedMintPause(bool _state) public onlyOwner {
        limitedMintPaused = _state;
    }

    function withdraw() public payable onlyOwner {
        (bool os, ) = payable(withdrawAddress).call{value: address(this).balance}('');
        require(os);
    }

    function setMintCost(uint256 _newCost) public onlyOwner {
        mintCost = _newCost;
    }

    function setMaxSupply(uint256 _newMaxSupply) public onlyOwner {
        maxSupply = _newMaxSupply;
    }

    function setMaxMintSupply(uint256 _newMaxMintSupply) public onlyOwner {
        maxMintSupply = _newMaxMintSupply;
    }

    function setLimitedMintCost(uint256 _newCost) public onlyOwner {
        limitedMintCost = _newCost;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setMetadataExtentions(string memory _newMetadataExtentions) public onlyOwner {
        metadataExtentions = _newMetadataExtentions;
    }

    function exists(uint256 tokenId) public view virtual returns (bool) {
        return _exists(tokenId);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        return string(abi.encodePacked(ERC721A.tokenURI(tokenId), metadataExtentions));
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }
}