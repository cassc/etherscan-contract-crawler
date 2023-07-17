// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract HyakkiToken is ERC721, ERC721Enumerable, ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;
    string private _currentBaseURI;
    bool public metadataLocked = false;
    address public mintvial;

    constructor(
        string memory name,
        string memory symbol,
        string memory baseURI,
        address mintvial_
    ) ERC721(name, symbol) {
        _currentBaseURI = baseURI;
        mintvial = mintvial_;
    }

    function safeMint(address to) public {
        require(msg.sender == mintvial, "Not authorized to mint");
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
    }

    function setMintvial(address mintvial_) public onlyOwner {
        mintvial = mintvial_;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        require(!metadataLocked, "Metadata locked");
        _currentBaseURI = baseURI;
    }

    function lockMetadata() public onlyOwner {
        metadataLocked = true;
    }

    // The following functions are overrides required by Solidity.

    function _baseURI() internal view override(ERC721) returns (string memory) {
        return _currentBaseURI;
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
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

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable, ERC721URIStorage)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}