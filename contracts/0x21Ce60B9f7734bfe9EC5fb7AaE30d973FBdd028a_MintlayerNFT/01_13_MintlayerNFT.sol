// SPDX-License-Identifier: MIT

pragma solidity 0.8.1;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

contract MintlayerNFT is ERC721URIStorage, Ownable {
  using Counters for Counters.Counter;
  Counters.Counter private _tokenIds;

  constructor(string memory name_, string memory symbol_) ERC721(name_, symbol_) {}

  function mintNFT(address recipient_, string memory tokenURI_)
    public onlyOwner
    returns (uint256)
  {
    _tokenIds.increment();

    uint256 newItemId = _tokenIds.current();
    _safeMint(recipient_, newItemId);
    _setTokenURI(newItemId, tokenURI_);

    return newItemId;
  }

  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public override onlyOwner {
    _transfer(from, to, tokenId);
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public override onlyOwner {
    safeTransferFrom(from, to, tokenId, "");
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes memory _data
  ) public override onlyOwner {
    _safeTransfer(from, to, tokenId, _data);
  }
}