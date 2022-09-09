// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract NFT is ERC721, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    uint256 public MAX_SUPPLY;
    uint256 public MAX_MINT_PER_WALLET;
    bool public isPublicMitEnabled;
    string internal baseTokenUri;

    constructor() payable ERC721("PixChars", "PXC") {
        MAX_SUPPLY = 222;
        MAX_MINT_PER_WALLET = 1;
        _tokenIdCounter.increment();
    }

    function setIsPublicMintEnabled(bool _isPublicMitEnabled) external onlyOwner {
        isPublicMitEnabled = _isPublicMitEnabled;
    }

    function setBaseTokenUri(string calldata _baseTokenUri) external onlyOwner {
        baseTokenUri = _baseTokenUri;
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), 'Token does not exist!');
        return string(abi.encodePacked(baseTokenUri, Strings.toString(_tokenId),'.json'));
    }

    function totalSupply() external  view returns (uint256) {
      return MAX_SUPPLY;
    }

    function freeMint() public payable {
        require(isPublicMitEnabled, 'Minting is not enabled');
        require(balanceOf(msg.sender) < MAX_MINT_PER_WALLET, "Max Mint per wallet reached");
        require(_tokenIdCounter.current() <= MAX_SUPPLY , "I'm sorry we reached the cap");

        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(msg.sender, tokenId);
    }
}