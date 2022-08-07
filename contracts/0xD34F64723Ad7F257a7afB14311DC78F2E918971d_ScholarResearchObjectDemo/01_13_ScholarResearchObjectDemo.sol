// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract ScholarResearchObjectDemo is ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

     // Mapping from token ID to array of token IDs of cited research objects
    mapping(uint256 => uint256[]) private _citations;
    mapping(uint256 => mapping(uint256 => bool)) private _citationExists;
    // Mapping from token ID to array of token IDs that cite this token
    mapping(uint256 => uint256[]) private _citedBy;
    mapping(uint256 => mapping(uint256 => bool)) private _citedByExists;

    string private _baseURIStr = "ipfs://QmNn3hFRbjp3TUzon7pHfb9yY4Ab2QR9aiZ68xyKpjupGJ/";

    constructor() ERC721("Scholar Research Object Demo", "SCHDEMO") {
    }

    function mint(address to, string memory tokenURI) onlyOwner public returns (uint256) {
        uint256 tokenId = _tokenIds.current();
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, tokenURI);

        _tokenIds.increment();
        return tokenId;
    }

    function cite(uint256 tokenId, uint256 citation) onlyOwner public {
        _requireMinted(tokenId);
        _requireMinted(citation);
        require(!_citationExists[tokenId][citation], "Citation already exists");
        require(!_citedByExists[citation][tokenId], "Cited by already exists");

        _citations[tokenId].push(citation);
        _citationExists[tokenId][citation] = true;
        _citedBy[citation].push(tokenId);
        _citedByExists[citation][tokenId] = true;
    }

    function getCitations(uint256 tokenId) public view returns (uint256[] memory) {
        _requireMinted(tokenId);
        return _citations[tokenId];
    }

    function getCitedBy(uint256 tokenId) public view returns (uint256[] memory) {
        _requireMinted(tokenId);
        return _citedBy[tokenId];
    }

    function setBaseURI(string memory baseURI) onlyOwner public {
        _baseURIStr = baseURI;
    }

    function _baseURI() internal override view returns (string memory) {
        return _baseURIStr;
    }
}