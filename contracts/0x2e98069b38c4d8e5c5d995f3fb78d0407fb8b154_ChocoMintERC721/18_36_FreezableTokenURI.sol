// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";

abstract contract FreezableTokenURI is ERC721Upgradeable {
  mapping(uint256 => string) private _tokenStaticURIs;
  mapping(uint256 => bool) private _isTokenStaticURIFreezed;
  bool private _isAllTokenStaticURIFreezed;
  bool private _isTokenURIBaseFreezed;
  string private _tokenURIBase;

  event AllTokenStaticURIFreezed();
  event TokenStaticURIFreezed(uint256 tokenId);
  event TokenStaticURIDefrosted(uint256 tokenId);
  event TokenStaticURISet(uint256 indexed tokenId, string tokenStaticURI);
  event TokenURIBaseFreezed();
  event TokenURIBaseSet(string tokenURIBase);

  modifier whenNotAllTokenStaticURIFreezed() {
    require(!_isAllTokenStaticURIFreezed, "FreezableTokenURI: all token static URI already freezed");
    _;
  }

  modifier whenNotTokenStaticURIFreezed(uint256 tokenId) {
    require(!_isTokenStaticURIFreezed[tokenId], "FreezableTokenURI: token static URI already freezed");
    _;
  }

  modifier whenNotTokenURIBaseFreezed() {
    require(!_isTokenURIBaseFreezed, "FreezableTokenURI: token URI base already freezed");
    _;
  }

  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    require(_exists(tokenId), "FreezableTokenURI: URI query for nonexistent token");
    string memory _tokenStaticURI = _tokenStaticURIs[tokenId];
    if (bytes(_tokenStaticURI).length > 0) {
      return _tokenStaticURI;
    }
    return super.tokenURI(tokenId);
  }

  function _freezeAllTokenStaticURI() internal whenNotAllTokenStaticURIFreezed {
    _isAllTokenStaticURIFreezed = true;
    emit AllTokenStaticURIFreezed();
  }

  function _freezeTokenStaticURI(uint256 tokenId)
    internal
    whenNotAllTokenStaticURIFreezed
    whenNotTokenStaticURIFreezed(tokenId)
  {
    require(_exists(tokenId), "FreezableTokenURI: URI freeze for nonexistent token");
    _isTokenStaticURIFreezed[tokenId] = true;
    emit TokenStaticURIFreezed(tokenId);
  }

  function _setTokenStaticURI(
    uint256 tokenId,
    string memory _tokenStaticURI,
    bool freezing
  ) internal whenNotAllTokenStaticURIFreezed whenNotTokenStaticURIFreezed(tokenId) {
    require(_exists(tokenId), "FreezableTokenURI: URI set for nonexistent token");
    _tokenStaticURIs[tokenId] = _tokenStaticURI;
    emit TokenStaticURISet(tokenId, string(_tokenStaticURI));
    if (freezing) {
      _freezeTokenStaticURI(tokenId);
    }
  }

  function _freezeTokenURIBase() internal whenNotTokenURIBaseFreezed {
    _isTokenURIBaseFreezed = true;
    emit TokenURIBaseFreezed();
  }

  function _setTokenURIBase(string memory tokenURIBase, bool freezing) internal whenNotTokenURIBaseFreezed {
    _tokenURIBase = tokenURIBase;
    emit TokenURIBaseSet(tokenURIBase);
    if (freezing) {
      _freezeTokenURIBase();
    }
  }

  function _burn(uint256 tokenId) internal virtual override {
    super._burn(tokenId);
    if (bytes(_tokenStaticURIs[tokenId]).length > 0) {
      delete _tokenStaticURIs[tokenId];
      emit TokenStaticURISet(tokenId, "");
      if (_isTokenStaticURIFreezed[tokenId]) {
        _isTokenStaticURIFreezed[tokenId] = false;
        emit TokenStaticURIDefrosted(tokenId);
      }
    }
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return _tokenURIBase;
  }

  // solhint-disable-next-line ordering
  uint256[50] private __gap;
}