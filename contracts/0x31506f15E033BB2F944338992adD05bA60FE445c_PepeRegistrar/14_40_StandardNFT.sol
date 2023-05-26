// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC721HexURI.sol";
import "./EIP712MetaTransaction.sol";

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

abstract contract StandardNFT is
  ERC721HexURI,
  ERC721Burnable,
  ERC721Enumerable,
  ERC721URIStorage,
  EIP712MetaTransaction
{
  using Strings for uint256;
  using SafeMath for uint256;

  // Context Overrides
  function _msgSender() internal view virtual override returns (address sender) {
    return EIP712MetaTransaction.msgSender();
  }

  // ERC721URIStorage Overrides
  function _burn(uint256 tokenId) internal virtual override(ERC721, ERC721URIStorage) {
    super._burn(tokenId);
  }

  // ERC721Enumerable Overrides
  function supportsInterface(
    bytes4 interfaceId
  ) public view virtual override(ERC721, ERC721Enumerable) returns (bool) {
    return super.supportsInterface(interfaceId);
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal virtual override(ERC721, ERC721Enumerable) {
    super._beforeTokenTransfer(from, to, tokenId);
  }

  function tokenURI(uint256 tokenId)
    public view virtual override(ERC721, ERC721HexURI, ERC721URIStorage)
    returns (string memory)
  {
    return super.tokenURI(tokenId);
  }
}