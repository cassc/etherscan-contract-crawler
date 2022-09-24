// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "../lib/TaggrBase721.sol";

contract TaggrLazy721 is
  TaggrBase721,
  ERC721Enumerable
{
  /***********************************|
  |          Initialization           |
  |__________________________________*/

  constructor() TaggrBase721("TaggrLazy721", "TL721") {}

  /***********************************|
  |         Public Functions          |
  |__________________________________*/

  function name() public view virtual override(ERC721, TaggrBase721) returns (string memory tokenName) {
    tokenName = super.name();
  }

  function symbol() public view virtual override(ERC721, TaggrBase721) returns (string memory tokenSymbol) {
    tokenSymbol = super.symbol();
  }

  function tokenURI(uint256 tokenId)
    public
    view
    override(ERC721, TaggrBase721)
    returns (string memory)
  {
    return super.tokenURI(tokenId);
  }

  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(TaggrBase721, ERC721Enumerable)
    returns (bool)
  {
    return super.supportsInterface(interfaceId);
  }


  /***********************************|
  |          Contract Hooks           |
  |__________________________________*/

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  )
    internal
    virtual
    override(TaggrBase721, ERC721Enumerable)
  {
    super._beforeTokenTransfer(from, to, tokenId);
  }




  function _baseURI() internal view virtual override(ERC721, TaggrBase721) returns (string memory) {
    return super._baseURI();
  }

  function _burn(uint256 tokenId) internal override(ERC721, TaggrBase721) {
    super._burn(tokenId);
  }
}