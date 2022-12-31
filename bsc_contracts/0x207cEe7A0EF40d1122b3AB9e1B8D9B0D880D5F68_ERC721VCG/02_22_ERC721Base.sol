// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v2;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721RoyaltyUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "../HasContractURI.sol";

abstract contract ERC721Base is
  OwnableUpgradeable,
  ERC721RoyaltyUpgradeable,
  ERC721BurnableUpgradeable,
  ERC721EnumerableUpgradeable,
  ERC721URIStorageUpgradeable,
  HasContractURI
{
  using StringsUpgradeable for uint256;

  event BaseUriChanged(string newBaseURI);
  event BaseExtensionChanged(string newBaseExtension);

  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(
      ERC165StorageUpgradeable,
      ERC721RoyaltyUpgradeable,
      ERC721EnumerableUpgradeable,
      ERC721Upgradeable
    )
    returns (bool)
  {
    return super.supportsInterface(interfaceId);
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal virtual override(ERC721EnumerableUpgradeable, ERC721Upgradeable) {
    super._beforeTokenTransfer(from, to, tokenId);
  }

  function _mint(address to, uint256 tokenId)
    internal
    override(ERC721Upgradeable)
  {
    super._mint(to, tokenId);
  }

  function _burn(uint256 tokenId)
    internal
    virtual
    override(
      ERC721Upgradeable,
      ERC721RoyaltyUpgradeable,
      ERC721URIStorageUpgradeable
    )
  {
    super._burn(tokenId);
  }

  function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
    returns (string memory)
  {
    return super.tokenURI(tokenId);
  }

  //Minting
  function mint(string memory _tokenURI) external onlyOwner {
    uint256 tokenId = totalSupply() + 1;
    _minting(_tokenURI, tokenId);
  }

  function _minting(string memory _tokenURI, uint tokenId) internal {
    _mint(msg.sender, tokenId);
    _setTokenURI(tokenId, _tokenURI);
  }

  uint256[50] private __gap;
}