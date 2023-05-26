// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract MetadashPremium is ERC721, Ownable, Pausable, ReentrancyGuard {
    uint256 private _tokenPrice = 0.19 ether;
    uint256 private _maxSupply = 10000;
    uint256 private _tokenIdTracker = 0;

    string private _currentBaseURI;

    constructor() ERC721("MetadashPremium", "MDP") {}

    function setBaseURI(string memory baseURI) public onlyOwner {
        _currentBaseURI = baseURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return _currentBaseURI;
    }

    function setTokenPrice(uint256 newPrice) public onlyOwner {
    _tokenPrice = newPrice;
    }

    function getTokenPrice() public view returns (uint256) {
        return _tokenPrice;
    }

    function mint(address to, uint256 num) public payable nonReentrant whenNotPaused {
        require(_tokenIdTracker + num <= _maxSupply, "Exceeds maximum NFT supply");
        require(msg.value >= _tokenPrice * num, "Ether sent is not correct");

        for(uint256 i; i < num; i++){
            _mint(to, _tokenIdTracker++);
        }
    }

    function airdrop(address[] memory recipients) public onlyOwner whenNotPaused {
        require(_tokenIdTracker + recipients.length <= _maxSupply, "Exceeds maximum NFT supply");

        for(uint256 i = 0; i < recipients.length; i++){
            _mint(recipients[i], _tokenIdTracker++);
        }
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
}