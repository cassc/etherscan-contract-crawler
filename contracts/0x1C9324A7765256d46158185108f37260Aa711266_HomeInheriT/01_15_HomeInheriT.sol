// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";


contract HomeInheriT is ERC721URIStorage, ERC2981, Ownable {
  using Counters for Counters.Counter;
  Counters.Counter private _tokenIds;

  address constant HomeInheriTMultiSig = address(0xAD18329e56BB50cDBeD02ff8de77B220E73eB75c);

  constructor() ERC721("HomeInheriT", "HIT") {
    _setDefaultRoyalty(HomeInheriTMultiSig, 0);
  }

  function supportsInterface(bytes4 interfaceId)
    public view virtual override(ERC721, ERC2981)
    returns (bool) {
      return super.supportsInterface(interfaceId);
  }

  function _burn(uint256 tokenId) internal virtual override {
    super._burn(tokenId);
    _resetTokenRoyalty(tokenId);
  }

  function burnNFT(uint256 tokenId)
    public onlyOwner {
      _burn(tokenId);
  }

  function mintNFT(address recipient, string memory tokenURI)
    public onlyOwner
    returns (uint256) {
      _tokenIds.increment();

      uint256 newItemId = _tokenIds.current();
      _safeMint(recipient, newItemId);
      _setTokenURI(newItemId, tokenURI);

      return newItemId;
  }

  function mintNFTWithRoyalty(address recipient, string memory tokenURI, address royaltyReceiver, uint96 feeNumerator)
    public onlyOwner
    returns (uint256) {
      uint256 tokenId = mintNFT(recipient, tokenURI);
      _setTokenRoyalty(tokenId, royaltyReceiver, feeNumerator);

      return tokenId;
  }
}