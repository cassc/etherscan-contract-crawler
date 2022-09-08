// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract PlaNFT is ERC721, Ownable {
    using SafeMath for uint256;
    using Strings for uint256;
    using Counters for Counters.Counter;
    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    // Current token Id
    Counters.Counter private _tokenIds;

    // Base uri
    string private _baseUri;

    event SetBaseURI(address indexed owner, string baseURI);
    event SetTokenURI(uint256 tokenId, string tokenURI);

    constructor(string memory name_, string memory symbol_)
        ERC721(name_, symbol_)
    {}

    function totalSupply() public view returns (uint256) {
        return _tokenIds.current();
    }

    function setBaseURI(string memory baseURI_) public onlyOwner {
        _baseUri = baseURI_;
        emit SetBaseURI(msg.sender, _baseUri);
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseUri;
    }

    function baseURI() public view returns (string memory) {
        return _baseURI();
    }

    function setTokenURI(uint256 tokenId, string memory tokenURI_) internal {
        _tokenURIs[tokenId] = tokenURI_;
        emit SetTokenURI(tokenId, tokenURI(tokenId));
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(tokenId), "Hash_NFT: token nonexistent");
        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }

        return base;
    }

    function mint(address to_, string memory tokenURI_) public {
        uint256 tokenId = _tokenIds.current();
        _tokenIds.increment();
        _safeMint(to_, tokenId);
        setTokenURI(tokenId, tokenURI_);
    }
}