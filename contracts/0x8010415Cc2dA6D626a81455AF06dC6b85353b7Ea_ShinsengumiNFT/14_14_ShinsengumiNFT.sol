// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

contract ShinsengumiNFT is ERC721URIStorage, Ownable {
    string public baseURI;

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    constructor() ERC721("EDOCOLLECTIONNFT", "EDOCOLLECTION") {
        baseURI = "ipfs://";
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function mint(address to, string memory tokenURI) public onlyOwner returns (uint256) {
        uint256 newItemId = _tokenIds.current();
        _mint(to, newItemId);
        _setTokenURI(newItemId, tokenURI);
        _tokenIds.increment();

        return newItemId;
    }
}