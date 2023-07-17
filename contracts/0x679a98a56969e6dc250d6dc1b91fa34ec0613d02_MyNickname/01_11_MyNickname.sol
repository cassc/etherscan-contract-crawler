// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MyNickname is ERC721, Ownable {

  string public baseTokenURI;

  constructor() ERC721("MyNickname", "NICK") {
    baseTokenURI = "https://mynickname.com/nft-metadata/";
  }

  function checkBeforeMint(uint256 tokenId) public onlyOwner view returns (bool) {
    return _exists(tokenId);
  }

  function mintTo(address recipient, uint256 tokenId) public onlyOwner returns (uint256) {
    _safeMint(recipient, tokenId);

    return tokenId;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return baseTokenURI;
  }

  function setBaseTokenURI(string memory _baseTokenURI) public onlyOwner {
    baseTokenURI = _baseTokenURI;
  }
}