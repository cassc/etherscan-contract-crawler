// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/common/ERC2981.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

import './TinyERC721.sol';

contract HonoraryCitizens is TinyERC721, ERC2981, Ownable {
  string private _baseTokenURI;
  mapping(uint256 => string) private _tokenURIs;

  constructor() TinyERC721('Honorary Citizens of Tajigen', 'HCOT', 0) {}

  function mint(address to, uint256 quantity) external onlyOwner {
    _mint(to, quantity);
  }

  function tokenURI(uint256 tokenId) public view override returns (string memory) {
    if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

    string memory _tokenURI = _tokenURIs[tokenId];
    if (bytes(_tokenURI).length > 0) {
      return _tokenURI;
    }

    return super.tokenURI(tokenId);
  }

  function setTokenURI(uint256 tokenId, string memory _tokenURI) external onlyOwner {
    _tokenURIs[tokenId] = _tokenURI;
  }

  function setBaseURI(string memory newBaseURI) external onlyOwner {
    _baseTokenURI = newBaseURI;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return _baseTokenURI;
  }

  function setRoyalty(address receiver, uint96 value) external onlyOwner {
    _setDefaultRoyalty(receiver, value);
  }

  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(TinyERC721, ERC2981)
    returns (bool)
  {
    return super.supportsInterface(interfaceId);
  }
}