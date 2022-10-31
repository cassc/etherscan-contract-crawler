// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract KoreaWeb3Documentary is ERC721, ERC721URIStorage, Ownable {
  event Attest(address indexed to, uint256 indexed tokenId);
  event Revoke(address indexed to, uint256 indexed tokenId);

  using Counters for Counters.Counter;

  Counters.Counter private _tokenId;

  constructor() ERC721("Korea Web3.0 Documentary", "KWD") {}

  function safeMint(address to, string memory uri) public onlyOwner {
    uint256 tokenId = _tokenId.current();
    _tokenId.increment();
    _safeMint(to, tokenId);
    _setTokenURI(tokenId, uri);
  }

  function safeMints(address[] memory to, string[] memory uri) public onlyOwner {
    require(to.length == uri.length, "KWD: to and uri length mismatch");

    for (uint256 i = 0; i < to.length; i++) {
      safeMint(to[i], uri[i]);
    }
  }

  function setTokenURIByTokenId(uint256 tokenId, string memory uri) public onlyOwner {
    _setTokenURI(tokenId, uri);
  }

  function revoke(uint256 tokenId) external onlyOwner {
    _burn(tokenId);
  }

  function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override virtual {
    require(from == address(0) || to == address(0), "You can't transfer this token");
  }

  function _afterTokenTransfer(address from, address to, uint256 tokenId) internal override virtual {
    if (from == address(0)) {
      emit Attest(to, tokenId);

    } else if (to == address(0)) {
      emit Revoke(from, tokenId);
    }
  }

  function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
    super._burn(tokenId);
  }

  function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
    return super.tokenURI(tokenId);
  }
}