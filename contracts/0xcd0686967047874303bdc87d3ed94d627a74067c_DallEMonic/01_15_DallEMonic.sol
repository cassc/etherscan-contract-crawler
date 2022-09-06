// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import '@openzeppelin/contracts/utils/Counters.sol';
import './OwnerWithdrawable.sol';

contract DallEMonic is OwnerWithdrawable, ERC721 {
    using Counters for Counters.Counter;
    Counters.Counter private tokenIdTracker;
    mapping(uint256 => string) public tokenUriById;

    constructor() ERC721('DALL-E-MONIC', 'DEM') {}

    modifier tokenExists(uint256 tokenId) {
        require(_exists(tokenId), 'Token does not exist');
        _;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        return tokenUriById[tokenId];
    }

    function mint(string calldata tokenUri) public onlyOwner returns (uint256) {
        uint256 _tokenId = tokenIdTracker.current();
        _mint(msg.sender, _tokenId);
        tokenIdTracker.increment();
        tokenUriById[_tokenId] = tokenUri;
        return _tokenId;
    }

    function setTokenURI(uint256 tokenId, string calldata tokenUri)
        public
        onlyOwner
        tokenExists(tokenId)
    {
        tokenUriById[tokenId] = tokenUri;
    }
}