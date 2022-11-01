//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract NFT is ERC721URIStorage {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    // uint256 totalSupply;

    constructor() ERC721("Alakasta", "ALAS") {

    }

    function mintNFT(string memory _tokenURI) public returns (uint256) {
        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();
        _mint(msg.sender, newItemId); 
        _setTokenURI(newItemId, _tokenURI);
        return newItemId;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns(string memory) {
        return super.tokenURI(tokenId);
    }

    function totalSupply() public pure returns (uint256) {
        return 8000;
    }

}