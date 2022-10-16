// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "./Child.sol";
contract template is ERC721, Ownable {
    using Strings for uint256;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    mapping (uint256 => string) private _tokenURIs;

    constructor() ERC721("testctdd", "desc") {
    }

    function tokenURI(uint256 tokenId) public view virtual override returns  (string memory)  {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return  _tokenURIs[tokenId];
    }

    function createToken(address user,string memory tokenuriss) public returns (uint) {
        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();

        _mint(user, newItemId);
        _tokenURIs[newItemId] = tokenuriss;
        return newItemId;
    }
}