// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author Nathan Grimaud

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Circles is ERC721Enumerable, Ownable, ReentrancyGuard {

    using Counters for Counters.Counter;
    using Strings for uint256;

    Counters.Counter private _nftIdCounter;

    uint public constant MAX_SUPPLY = 2499;

    string public baseURI;

    bool public isMintOpen = false;

    address private _owner;

    mapping(address => bool) private isMinted;

    constructor() ERC721("1000 Circles", "CIRCLE") {
        transferOwnership(msg.sender);
    }

    function openMint(bool _isMintOpen) external onlyOwner {
        isMintOpen = _isMintOpen;
    }

    function setBaseUri(string memory _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
    }

    function mint(uint numberOfTokens) external nonReentrant {
        require(isMintOpen, 'The mint is not open.');
        require(totalSupply() + numberOfTokens <= MAX_SUPPLY, 'Purchase would exceed max tokens.');
        require(isMinted[msg.sender] == false, 'You have already minted.');
        for (uint i = 0; i < numberOfTokens; i++) {
            _nftIdCounter.increment();
            _safeMint(msg.sender, _nftIdCounter.current());
        }
        isMinted[msg.sender] = true;
    }

    function tokenURI(uint _nftId) public view override(ERC721) returns (string memory) {
        require(_exists(_nftId), "This NFT doesn't exist.");

        return string(abi.encodePacked(baseURI, _nftId.toString(), ".json"));
    }

    function reserve(uint n) external onlyOwner {
        require(totalSupply() + n <= MAX_SUPPLY, 'Purchase would exceed max tokens.');
        for (uint i = 0; i < n; i++) {
            _nftIdCounter.increment();
            _safeMint(msg.sender, _nftIdCounter.current());
        }
    }
}