pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract RingsGenesis is Ownable, ERC721Enumerable, ERC721Burnable, ERC721URIStorage  {

  mapping (uint => string) private tokenIdToArweave;
  string private _baseTokenURI;
  uint256 private _tokenIdTracker;

  constructor() ERC721("Rings Genesis by Nick Kuder", "RGNK") {
    _baseTokenURI = "ipfs://";
  }

  function _baseURI() internal view virtual override returns (string memory) {
      return _baseTokenURI;
  }

  function changeBaseURI(string calldata baseURI) public onlyOwner {
    _baseTokenURI = baseURI;
  }

  function mint(string memory ipfs, string memory arweave) public onlyOwner {
      uint currentTokenId = _tokenIdTracker++;
      _mint(owner(), currentTokenId);
      tokenIdToArweave[currentTokenId] = arweave;
      _setTokenURI(currentTokenId, ipfs);
  }

  function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
    return super.tokenURI(tokenId);
  }

  function getArweave(uint256 tokenId) public view returns (string memory) {
    return string(abi.encodePacked("https://arweave.net/", tokenIdToArweave[tokenId]));
  }

  function _burn(uint256 tokenId) internal virtual override(ERC721, ERC721URIStorage) {
      delete tokenIdToArweave[tokenId];
      super._burn(tokenId);
  }

  function supportsInterface(bytes4 interfaceId)
      public
      view
      virtual
      override(ERC721, ERC721Enumerable)
      returns (bool)
  {
      return super.supportsInterface(interfaceId);
  }

  function _beforeTokenTransfer(
      address from,
      address to,
      uint256 tokenId
  ) internal virtual override(ERC721, ERC721Enumerable) {
      super._beforeTokenTransfer(from, to, tokenId);
  }
}