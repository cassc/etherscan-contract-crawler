// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4; //Do not change the solidity version as it negativly impacts submission grading

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract YourCollectible is
    ERC721,
    ERC721Enumerable,
    ERC721URIStorage,
    Ownable
{
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    constructor() ERC721("YourCollectible", "YCB") {}

    function _baseURI() internal pure override returns (string memory) {
        return "https://ipfs.io/ipfs/";
    }

    function mintItem(address to, string memory uri) public returns (uint256) {
        _tokenIdCounter.increment();
        uint256 tokenId = _tokenIdCounter.current();
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
        return tokenId;
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId)
        internal
        override(ERC721, ERC721URIStorage)
    {
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
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function punkImageSvg(uint16) public pure returns (string memory) {
        return
            'data:image/svg+xml;utf8,<svg xmlns="http://www.w3.org/2000/svg" version="1.2" viewBox="0 0 24 24"><rect x="8" y="5" width="1" height="1" shape-rendering="crispEdges" fill="#1637a4ff"/><rect x="9" y="5" width="1" height="1" shape-rendering="crispEdges" fill="#1637a4ff"/><rect x="10" y="5" width="1" height="1" shape-rendering="crispEdges" fill="#1637a4ff"/><rect x="11" y="5" width="1" height="1" shape-rendering="crispEdges" fill="#1637a4ff"/><rect x="12" y="5" width="1" height="1" shape-rendering="crispEdges" fill="#1637a4ff"/><rect x="13" y="5" width="1" height="1" shape-rendering="crispEdges" fill="#1637a4ff"/><rect x="14" y="5" width="1" height="1" shape-rendering="crispEdges" fill="#1637a4ff"/><rect x="15" y="5" width="1" height="1" shape-rendering="crispEdges" fill="#1637a4ff"/><rect x="7" y="6" width="1" height="1" shape-rendering="crispEdges" fill="#1637a4ff"/><rect x="8" y="6" width="1" height="1" shape-rendering="crispEdges" fill="#1a43c8ff"/><rect x="9" y="6" width="1" height="1" shape-rendering="crispEdges" fill="#1a43c8ff"/><rect x="10" y="6" width="1" height="1" shape-rendering="crispEdges" fill="#1a43c8ff"/><rect x="11" y="6" width="1" height="1" shape-rendering="crispEdges" fill="#1a43c8ff"/><rect x="12" y="6" width="1" height="1" shape-rendering="crispEdges" fill="#1a43c8ff"/><rect x="13" y="6" width="1" height="1" shape-rendering="crispEdges" fill="#1a43c8ff"/></svg>';
    }
}