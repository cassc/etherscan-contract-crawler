// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract QueenOfBokNFT is ERC721, ERC721URIStorage {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    uint256 public constant maxSupply = 101;
    uint256 public constant mintPrice = 1 ether;

    event NewNFTMinted(address sender, uint256 tokenId);

    constructor() ERC721("QueenOfBokNFT", "QOB") {}

    function _baseURI() internal pure override returns (string memory) {
        return "https://storage.googleapis.com/queen-of-bok/round1/metadata.json";
    }

    function mintNFT() public payable {
        address devFund = address(0x16d2E836DFd8b362B7791C38238c9256CA9154E0);

        require(msg.value == mintPrice, "WRONG_PRICE");
        (bool sent, ) = payable(devFund).call{value: msg.value}("");
        require(sent, "Failed to send Ether");
        
        safeMint(msg.sender, _baseURI());
    }

    function safeMint(address to, string memory uri) internal {
        uint256 tokenId = _tokenIdCounter.current();
        require (_tokenIdCounter.current() < maxSupply);
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);

        emit NewNFTMinted(msg.sender, tokenId);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }
}