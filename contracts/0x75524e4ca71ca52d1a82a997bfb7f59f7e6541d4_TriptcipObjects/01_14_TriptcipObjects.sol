// @author https://github.com/mikevercoelen

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./ERC721Enum.sol";

contract TriptcipObjects is ERC721Enum, Ownable, ReentrancyGuard {
  using Strings for uint256;
  string public baseURI;

  // Settings
  uint256 public maxSupply = 4000;
  uint public mintPrice = 0.05 ether;
  bool public isPublicSaleOpen;

  mapping(address => bool) public whitelist;

  string private baseTokenURI;

  constructor(string memory _baseTokenURI, bool _isPublicSaleOpen)
    ERC721P("TriptcipObjects", "TRIP")
  {
    setBaseURI(_baseTokenURI);
    isPublicSaleOpen = _isPublicSaleOpen;
  }

  function mintWhitelist(uint256 _mintAmount) public payable {
    uint256 s = totalSupply();

    require(!isPublicSaleOpen, "Nope");
    require(whitelist[msg.sender] == true, "Not whitelisted");
    require(s + _mintAmount <= maxSupply, "More than max");
    require(mintPrice * _mintAmount == msg.value, "Wrong amount");

    for (uint256 i; i < _mintAmount; i++) {
      _mint(msg.sender, s + i);
    }
  }

  function mint(uint256 _mintAmount) public payable nonReentrant {
    uint256 s = totalSupply();

    require(isPublicSaleOpen, "Nope");
    require(_mintAmount > 0, "Duh");
    require(s + _mintAmount <= maxSupply, "Sorry");
    require(msg.value >= mintPrice * _mintAmount);

    for (uint256 i = 0; i < _mintAmount; ++i) {
      _mint(msg.sender, s + i);
    }
  }

  function airdrop(uint[] calldata quantity, address[] calldata recipient)
    public
    onlyOwner
  {
    require(
      quantity.length == recipient.length,
      "Provide quantities and recipients"
    );

    uint256 s = totalSupply();

    for (uint i = 0; i < recipient.length; ++i) {
      for (uint j = 0; j < quantity[i]; ++j) {
        _mint(recipient[i], s++);
      }
    }
  }

  function whitelistSet(address[] calldata _addresses) public onlyOwner {
    for (uint256 i; i < _addresses.length; i++) {
      whitelist[_addresses[i]] = true;
    }
  }

  function setMaxSupply(uint256 _maxSupply) external onlyOwner {
    maxSupply = _maxSupply;
  }

  function setMintPrice(uint256 _mintPrice) external onlyOwner {
    mintPrice = _mintPrice;
  }

  function _baseURI() internal view virtual returns (string memory) {
    return baseURI;
  }

  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }

  function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(_exists(tokenId), "ERC721Metadata: Nonexistent token");
    string memory currentBaseURI = _baseURI();

    return
      bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, tokenId.toString()))
        : "";
  }

  function withdraw() public payable onlyOwner {
    (bool success, ) = payable(msg.sender).call{value: address(this).balance}(
      ""
    );
    require(success);
  }

  function setIsPublicSaleOpen(bool _isPublicSaleOpen) public onlyOwner {
    isPublicSaleOpen = _isPublicSaleOpen;
  }
}