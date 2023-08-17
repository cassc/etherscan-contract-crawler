// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol"; // Import Counters

contract CryptoNoire is
    ERC721,
    ERC721Enumerable,
    ERC721URIStorage,
    Ownable,
    Pausable
{
    using Counters for Counters.Counter; // Use Counters library

    Counters.Counter private _tokenIdCounter;

    uint256 public maxNFTSupply = 100;
    uint256 public maxPerWallet = 4; // Maximum NFTs per wallet
    mapping(address => uint256) public mintedCount; // Mapping to keep track of mints by each address

    // Set the _currentBaseURI directly here
    string private _currentBaseURI = "ipfs://Qmb8eQG7ZD97EaHuU61A8QAWuQCQzo2Z8LgQtaus4ttrmH/";

    constructor() ERC721("Crypto Noire", "NOIRE") {
    }

    function _baseURI() internal view override returns (string memory) {
        return _currentBaseURI;
    }

    function setBaseURI(string memory newBaseURI) public onlyOwner {
        _currentBaseURI = newBaseURI;
    }

    function setMaxPerWallet(uint256 newMaxPerWallet) public onlyOwner {
        maxPerWallet = newMaxPerWallet;
    }


    function mintNFT() public whenNotPaused {
        require(
            _tokenIdCounter.current() < maxNFTSupply,
            "Maximum NFT supply reached"
        );
        require(
            mintedCount[msg.sender] < maxPerWallet,
            "You've reached the maximum allowed NFTs per wallet"
        );

        uint256 tokenId = _tokenIdCounter.current() + 1; // Start with token ID 1
        _tokenIdCounter.increment();
        _safeMint(msg.sender, tokenId);

        mintedCount[msg.sender]++;
    }

    function setMaxNFTSupply(uint256 newMaxNFTSupply) public onlyOwner {
        maxNFTSupply = newMaxNFTSupply;
    }

    // Pause and Unpause functions from Pausable contract
    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal override(ERC721, ERC721Enumerable) {
        ERC721Enumerable._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function _burn(
        uint256 tokenId
    ) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(
        uint256 tokenId
    ) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return string(abi.encodePacked(super.tokenURI(tokenId), ".json"));
    }

    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        override(ERC721, ERC721Enumerable, ERC721URIStorage)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}