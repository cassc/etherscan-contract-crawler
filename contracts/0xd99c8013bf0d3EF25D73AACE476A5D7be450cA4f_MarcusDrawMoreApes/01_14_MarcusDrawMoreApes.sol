// SPDX-License-Identifier: MIT

//  __  __                                                            ___
//  |  \/  |   __ _       _ _     __      _  _      ___       o O O   |   \      _ _    __ _    __ __ __
//  | |\/| |  / _` |     | '_|   / _|    | +| |    (_-<      o        | |) |    | '_|  / _` |   \ V  V /
//  |_|__|_|  \__,_|    _|_|_    \__|_    \_,_|    /__/_    TS__[O]   |___/    _|_|_   \__,_|    \_/\_/
//  _|"""""| _|"""""| _|"""""| _|"""""| _|"""""| _|"""""|  {======| _|"""""| _|"""""| _|"""""| _|"""""|
//  "`-0-0-' "`-0-0-' "`-0-0-' "`-0-0-' "`-0-0-' "`-0-0-' ./o--000' "`-0-0-' "`-0-0-' "`-0-0-' "`-0-0-'
// 48cc28ad5484dd1b3c00fd2f32924fa2f0ef2dccf2b7461b20cab6a9ce3e2978e86c6b772932f46e8a98ed42accc0a50
//
//  __  __                                          ___      _ __
//  |  \/  |    ___       _ _     ___       o O O   /   \    | '_ \    ___      ___
//  | |\/| |   / _ \     | '_|   / -_)     o        | - |    | .__/   / -_)    (_-<
//  |_|__|_|   \___/    _|_|_    \___|    TS__[O]   |_|_|    |_|__    \___|    /__/_
//  _|"""""| _|"""""| _|"""""| _|"""""|  {======| _|"""""| _|"""""| _|"""""| _|"""""|
//  "`-0-0-' "`-0-0-' "`-0-0-' "`-0-0-' ./o--000' "`-0-0-' "`-0-0-' "`-0-0-' "`-0-0-'
// 449ee63cb95a50adb08c1934e9a6b8bc1f7ebf88d3d15b097d071489b02bc55e

pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract MarcusDrawMoreApes is ERC721, ERC721Enumerable, Ownable {
  using Strings for uint256;
  using Counters for Counters.Counter;

  uint256 private constant _apesToSetAside = 30;
  Counters.Counter private _tokenIdCounter;
  string private _baseURIStr;
  string private _defaultURI;

  uint256 public constant price = 0.1 ether;
  uint256 public constant maxPerPurchase = 20;
  uint256 public immutable maxSupply;
  uint256 public immutable saleTimestamp;
  uint256 public immutable revealTimestamp;
  string public provenanceHash;
  bool public isSaleActive = false;

  constructor(
    string memory name,
    string memory symbol,
    uint256 maxSupply_,
    uint256 saleTimestamp_
  ) ERC721(name, symbol) {
    maxSupply = maxSupply_;
    saleTimestamp = saleTimestamp_;
    revealTimestamp = saleTimestamp + 1 weeks;
  }

  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable) returns (bool) {
    return super.supportsInterface(interfaceId);
  }

  modifier supplyCheck(uint256 quantity) {
    require(totalSupply() + quantity <= maxSupply, "Purchase would exceed max supply of Apes");
    _;
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal override(ERC721, ERC721Enumerable) {
    super._beforeTokenTransfer(from, to, tokenId);
  }

  function withdraw() public onlyOwner {
    uint256 balance = address(this).balance;
    if (balance > 0) {
      Address.sendValue(payable(owner()), balance);
    }
  }

  function toggleSaleState() public onlyOwner {
    isSaleActive = !isSaleActive;
  }

  function setDefaultURI(string memory uri) public onlyOwner {
    _defaultURI = uri;
  }

  function setProvenanceHash(string memory hash) public onlyOwner {
    provenanceHash = hash;
  }

  function _baseURI() internal view override returns (string memory) {
    return _baseURIStr;
  }

  function mintApes(uint256 quantity) public payable supplyCheck(quantity) {
    require(isSaleActive, "Sale must be active to mint one of Marcus' Apes");
    require(quantity <= maxPerPurchase, "Can only mint 20 Apes at a time");
    require(price * quantity <= msg.value, "Ether value sent is insufficient");

    _mintMultipleApes(_msgSender(), quantity);
  }

  function _mintMultipleApes(address to, uint256 quantity) private {
    for (uint256 i = 0; i < quantity; i++) {
      uint256 tokenId = _tokenIdCounter.current();
      _tokenIdCounter.increment();
      _safeMint(to, tokenId);
    }
  }

  function setAsideApes() public onlyOwner supplyCheck(_apesToSetAside) {
    _mintMultipleApes(_msgSender(), _apesToSetAside);
  }

  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    _requireMinted(tokenId);

    string memory baseURI = _baseURI();
    return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : _defaultURI;
  }

  function renounceOwnership() public view override onlyOwner {
    revert BadCall();
  }

  function setBaseURI(string memory uri) public onlyOwner {
    _baseURIStr = uri;
  }
}

error BadCall();