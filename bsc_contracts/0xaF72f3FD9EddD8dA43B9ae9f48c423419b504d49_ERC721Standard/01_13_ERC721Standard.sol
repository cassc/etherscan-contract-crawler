//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract ERC721Standard is Ownable, ERC721, ERC721URIStorage {
  using Counters for Counters.Counter;

  Counters.Counter private _tokenIdCounter;

  constructor(
    address _owner,
    string memory name,
    string memory symbol,
    string memory metadata
  ) ERC721(name, symbol) {
    require(_owner != address(0), "ERC721: address is not zero");
    transferOwnership(_owner);
    
    if (
      keccak256(abi.encodePacked(metadata)) != keccak256(abi.encodePacked("1"))
    ) {
      _mintToken(_owner, metadata);
    }
  }

  function mint(address owner_, string memory metadataURI)
    public
    onlyOwner
    returns (uint256)
  {
    return _mintToken(owner_, metadataURI);
  }

  function _mintToken(address owner_, string memory metadataURI)
    internal
    returns (uint256)
  {
    _tokenIdCounter.increment();
    uint256 tokenId = _tokenIdCounter.current();
    _safeMint(owner_, tokenId);
    _setTokenURI(tokenId, metadataURI);

    return tokenId;
  }

  function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
    super._burn(tokenId);
  }

  function tokenURI(uint256 tokenId)
    public
    view
    override(ERC721, ERC721URIStorage)
    returns (string memory)
  {
    return super.tokenURI(tokenId);
  }
}