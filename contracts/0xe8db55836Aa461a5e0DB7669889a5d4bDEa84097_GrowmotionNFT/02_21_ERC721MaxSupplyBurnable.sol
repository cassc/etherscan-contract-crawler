// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract ERC721MaxSupplyBurnable is ERC721Enumerable, ERC721Burnable, Ownable {
  using SafeMath for uint256;
  using Counters for Counters.Counter;

  string public baseURI;
  uint256 public maxSupply;
  bool public isBurnable = false;

  Counters.Counter private _numMinted;

  constructor(
    string memory name_,
    string memory symbol_,
    uint256 maxSupply_,
    string memory baseURI_
  ) ERC721(name_, symbol_) {
    maxSupply = maxSupply_;
    baseURI = baseURI_;
  }

  function _safeMint(address to) internal virtual {
    uint256 newId = Counters.current(_numMinted).add(1);
    require(newId <= maxSupply, "max supply reached");
    ERC721._safeMint(to, newId);
    Counters.increment(_numMinted);
  }

  function setBaseURI(string memory uri_) external onlyOwner {
    baseURI = uri_;
  }

  function _baseURI() internal view override returns (string memory) {
    return baseURI;
  }

  function burn(uint256 tokenId_) public override(ERC721Burnable) {
    ERC721Burnable.burn(tokenId_);
  }

  function tokensByOwner(address addr_) public view returns (uint256[] memory) {
    uint256 balance = balanceOf(addr_);

    uint256[] memory tokens = new uint256[](balance);
    for (uint256 i = 0; i < balance; ++i) {
      tokens[i] = tokenOfOwnerByIndex(addr_, i);
    }

    return tokens;
  }

  function supportsInterface(
    bytes4 interfaceId
  ) public view virtual override(ERC721Enumerable, ERC721) returns (bool) {
    return ERC721.supportsInterface(interfaceId) || ERC721Enumerable.supportsInterface(interfaceId);
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 firstTokenId,
    uint256 batchSize
  ) internal virtual override(ERC721, ERC721Enumerable) {
    ERC721Enumerable._beforeTokenTransfer(from, to, firstTokenId, batchSize);
  }
}