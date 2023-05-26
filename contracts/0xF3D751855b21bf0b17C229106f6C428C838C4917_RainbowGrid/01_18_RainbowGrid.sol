/**
 *         ██▓▓▒▒░░
 *       ██▓▓▒▒░░
 *     ██▓▓▒▒░░
 *    ██▓▓▒▒░░
 *   ██▓▓▒▒░░
 *   ██▓▓▒▒░░
 *  ██▓▓▒▒░░
 *  ██▓▓▒▒░░
 *  Rainbow Grid
 *  Kim Asendorf
 *  2021
 */

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract RainbowGrid is
  ERC721Enumerable,
  ERC721URIStorage,
  ERC721Burnable,
  ReentrancyGuard,
  Pausable,
  Ownable
{
  using SafeMath for uint256;
  using Strings for uint256;

  string public baseURI = "ipfs://QmSGvRD4QpgYtzc9EzgXyCf6Ky89b3CfbE6m3UXyj9EYF3/";
  bool[] availableTokens = new bool[](54);
  uint256 public mintPrice = 0.25 ether;
  address payable public withdrawalAddress;

  event onMint(address minter, uint256 tokenId);

  constructor(address payable _withdrawalAddress) ERC721("Rainbow Grid, Kim Asendorf", "ASDFRG") {
    withdrawalAddress = _withdrawalAddress;
    for (uint256 i = 0; i < availableTokens.length; i++) {
      availableTokens[i] = true;
    }
  }

  function pause() public onlyOwner {
    _pause();
  }

  function unpause() public onlyOwner {
    _unpause();
  }

  function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal whenNotPaused override(ERC721, ERC721Enumerable) {
    super._beforeTokenTransfer(from, to, tokenId);
  }

  function mint(uint256 tokenId) public payable whenNotPaused nonReentrant {
    require(mintPrice == msg.value, "Wrong amount of Ethereum supplied.");
    safeMint(tokenId);
  }

  function creatorMint(uint256 tokenId) public onlyOwner {
    safeMint(tokenId);
  }

  function safeMint(uint256 tokenId) private {
    require(tokenId >= 0 && tokenId < availableTokens.length, "This token doesn't exist.");
    require(availableTokens[tokenId], "This token has already been minted.");
    availableTokens[tokenId] = false;
    _safeMint(msg.sender, tokenId);
    emit onMint(msg.sender, tokenId);
  }

  function resetTokenAvailable(uint256 tokenId) public onlyOwner {
    require(tokenId >= 0 && tokenId < availableTokens.length, "This token doesn't exist.");
    require(!_exists(tokenId), "Token has already been minted and can not be resetted.");
    availableTokens[tokenId] = true;
  }

  function withdraw() public onlyOwner {
    Address.sendValue(withdrawalAddress, address(this).balance);
  }

  function getBaseURI() external view returns (string memory) {
    return baseURI;
  }

  function getAvailableTokens() external view returns (bool[] memory) {
    return availableTokens;
  }

  function getBalance() public view returns (uint256) {
    return address(this).balance;
  }

  function getMintPrice() external view returns (uint256) {
    return mintPrice;
  }

  function setMintPrice(uint256 _mintPrice) public onlyOwner {
    mintPrice = _mintPrice;
  }

  function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
    return string(abi.encodePacked(baseURI, Strings.toString(tokenId), ".json"));
  }

  function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
    super._burn(tokenId);
  }

  function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
    return super.supportsInterface(interfaceId);
  }
}