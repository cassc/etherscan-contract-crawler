/**
 *  SABOTAGE|S4B0T4G3|5A8O][A6E|5480_463|ₛᵃ₈ᴼ†⁴ɢᵉ
 *  Kim Asendorf, 2022
 *  https://sabotage.kim
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

contract Sabotage is
  ERC721Enumerable,
  ERC721URIStorage,
  ERC721Burnable,
  ReentrancyGuard,
  Pausable,
  Ownable
{
  using SafeMath for uint256;
  using Strings for uint256;

  string public baseURI = "https://sabotage.kim/meta/";

  uint256 public editorMintPrice = 64 ether;
  uint256 public mainMintPrice = 0.25 ether;
  uint256 public customMintPrice = 0.5 ether;

  uint256 public mainSupply = 256;
  uint256 public customSupply = 16;

  address payable public withdrawalAddress;

  event onMint(address minter, uint256 tokenId);

  constructor(address payable _withdrawalAddress) ERC721("SABOTAGE, Kim Asendorf", "S4B0T4G3") {
    withdrawalAddress = _withdrawalAddress;
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
    require(totalSupply() < (mainSupply + customSupply + 1), "All Tokens have been minted.");
    require((tokenId >= 0 && tokenId <= mainSupply) || (tokenId > 1000 && tokenId <= (1000 + customSupply)), "Token doesn't exist.");
    if (tokenId == 0) {
      require(editorMintPrice == msg.value, "Wrong amount of Ethereum supplied.");
    } else if (tokenId > 0 && tokenId <= mainSupply) {
      require(mainMintPrice == msg.value, "Wrong amount of Ethereum supplied.");
    } else if (tokenId > 1000 && tokenId <= (1000 + customSupply)) {
      require(customMintPrice == msg.value, "Wrong amount of Ethereum supplied.");
    }
    safeMint(tokenId);
  }

  function creatorMint(uint256[] memory tokenIds) public onlyOwner {
    for (uint256 i = 0; i < tokenIds.length; i++) {
      safeMint(tokenIds[i]);
    }
  }

  function safeMint(uint256 tokenId) private {
    _safeMint(msg.sender, tokenId);
    emit onMint(msg.sender, tokenId);
  }

  function withdraw() public onlyOwner {
    Address.sendValue(withdrawalAddress, address(this).balance);
  }

  function setBaseURI(string memory _baseURI) public onlyOwner {
    baseURI = _baseURI;
  }

  function setEditorMintPrice(uint256 _mintPrice) public onlyOwner {
    editorMintPrice = _mintPrice;
  }

  function setMainMintPrice(uint256 _mintPrice) public onlyOwner {
    mainMintPrice = _mintPrice;
  }

  function setCustomMintPrice(uint256 _mintPrice) public onlyOwner {
    customMintPrice = _mintPrice;
  }

  function setMainSupply(uint256 _supply) public onlyOwner {
    mainSupply = _supply;
  }

  function setCustomSupply(uint256 _supply) public onlyOwner {
    customSupply = _supply;
  }

  function setWithdrawalAdress(address payable _withdrawaladress) public onlyOwner {
    withdrawalAddress = _withdrawaladress;
  }

  function getContractBalance() public view returns (uint256) {
    return address(this).balance;
  }

  function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
    return string(abi.encodePacked(baseURI, Strings.toString(tokenId)));
  }

  function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
    super._burn(tokenId);
  }

  function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
    return super.supportsInterface(interfaceId);
  }
}