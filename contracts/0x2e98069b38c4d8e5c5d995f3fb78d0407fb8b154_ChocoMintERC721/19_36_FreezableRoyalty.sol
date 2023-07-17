// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "../interfaces/IERC2981.sol";

import "./RoyaltyLib.sol";

contract FreezableRoyalty is ERC721Upgradeable, IERC2981 {
  mapping(uint256 => RoyaltyLib.RoyaltyData) private _tokenRoyalties;
  mapping(uint256 => bool) private _isTokenRoyaltyFreezed;

  RoyaltyLib.RoyaltyData private _defaultRoyalty;

  bool private _isAllTokenRoyaltyFreezed;
  bool private _isDefaultRoyaltyFreezed;

  event AllTokenRoyaltyFreezed();
  event TokenRoyaltyFreezed(uint256 tokenId);
  event TokenRoyaltyDefrosted(uint256 tokenId);
  event TokenRoyaltySet(uint256 tokenId, address recipient, uint256 bps);
  event DefaultRoyaltyFreezed();
  event DefaultRoyaltySet(address recipient, uint256 bps);

  modifier requireValidRoyalty(RoyaltyLib.RoyaltyData memory royaltyData) {
    (bool isValid, string memory errorMessage) = RoyaltyLib.validate(royaltyData);
    require(isValid, errorMessage);
    _;
  }

  modifier whenNotAllTokenRoyaltyFreezed() {
    require(!_isAllTokenRoyaltyFreezed, "FreezableRoyalty: all token royalty already freezed");
    _;
  }

  modifier whenNotTokenRoyaltyFreezed(uint256 tokenId) {
    require(!_isTokenRoyaltyFreezed[tokenId], "FreezableRoyalty: token royalty already freezed");
    _;
  }

  modifier whenNotDefaultRoyaltyFreezed() {
    require(!_isDefaultRoyaltyFreezed, "FreezableRoyalty: default royalty already freezed");
    _;
  }

  function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
    return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
  }

  function royaltyInfo(uint256 tokenId, uint256 salePrice) public view override returns (address, uint256) {
    require(_exists(tokenId), "FreezableRoyalty: royalty query for nonexistent token");
    if (RoyaltyLib.isNotNull(_tokenRoyalties[tokenId])) {
      return (_tokenRoyalties[tokenId].recipient, RoyaltyLib.calc(salePrice, _tokenRoyalties[tokenId].bps));
    }
    if (RoyaltyLib.isNotNull(_defaultRoyalty)) {
      return (_defaultRoyalty.recipient, RoyaltyLib.calc(salePrice, _defaultRoyalty.bps));
    }
    return (address(0x0), 0);
  }

  function _freezeAllTokenRoyalty() internal whenNotAllTokenRoyaltyFreezed {
    _isAllTokenRoyaltyFreezed = true;
    emit AllTokenRoyaltyFreezed();
  }

  function _freezeTokenRoyalty(uint256 tokenId)
    internal
    whenNotAllTokenRoyaltyFreezed
    whenNotTokenRoyaltyFreezed(tokenId)
  {
    require(_exists(tokenId), "FreezableRoyalty: royalty freeze for nonexistent token");
    _isTokenRoyaltyFreezed[tokenId] = true;
    emit TokenRoyaltyFreezed(tokenId);
  }

  function _freezeDefaultRoyalty() internal whenNotDefaultRoyaltyFreezed {
    _isDefaultRoyaltyFreezed = true;
    emit DefaultRoyaltyFreezed();
  }

  function _setTokenRoyalty(
    uint256 tokenId,
    RoyaltyLib.RoyaltyData memory royaltyData,
    bool freezing
  ) internal whenNotAllTokenRoyaltyFreezed whenNotTokenRoyaltyFreezed(tokenId) requireValidRoyalty(royaltyData) {
    require(_exists(tokenId), "FreezableRoyalty: royalty set for nonexistent token");
    _tokenRoyalties[tokenId] = royaltyData;
    emit TokenRoyaltySet(tokenId, royaltyData.recipient, royaltyData.bps);
    if (freezing) {
      _freezeTokenRoyalty(tokenId);
    }
  }

  function _setDefaultRoyalty(RoyaltyLib.RoyaltyData memory royaltyData, bool freezing)
    internal
    whenNotDefaultRoyaltyFreezed
    requireValidRoyalty(royaltyData)
  {
    _defaultRoyalty = royaltyData;
    emit DefaultRoyaltySet(royaltyData.recipient, royaltyData.bps);
    if (freezing) {
      _freezeDefaultRoyalty();
    }
  }

  function _burn(uint256 tokenId) internal virtual override {
    super._burn(tokenId);
    if (RoyaltyLib.isNotNull(_tokenRoyalties[tokenId])) {
      delete _tokenRoyalties[tokenId];
      emit TokenRoyaltySet(tokenId, address(0x0), 0);
      if (_isTokenRoyaltyFreezed[tokenId]) {
        _isTokenRoyaltyFreezed[tokenId] = false;
        emit TokenRoyaltyDefrosted(tokenId);
      }
    }
  }

  // solhint-disable-next-line ordering
  uint256[50] private __gap;
}