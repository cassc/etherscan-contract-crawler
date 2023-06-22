// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract TomiDomainPartner is ERC721, Ownable {
    using Counters for Counters.Counter;

    string baseURI;

    Counters.Counter private _tokenIdCounter;

    mapping (uint256 => uint256) public dnsIds;

    constructor() ERC721("Tomi Domain Partner", "TDP") {}

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }
    
    function updateBaseURI(string memory _URI) public onlyOwner{
        baseURI = _URI;
    }

    function safeMint(address to , uint256 dnsId) public onlyOwner returns(uint256) {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
        dnsIds[tokenId] = dnsId;
        return tokenId;
    }

     function getDnsOfNFT(uint256 id) public view returns(uint256) {
        return dnsIds[id];
    }
}