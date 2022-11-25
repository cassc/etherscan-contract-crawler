// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract TomTurkeys is ERC721, ReentrancyGuard, Ownable {
  using Counters for Counters.Counter;

  address private constant payoutAddress1 = 0x9ae55d2b5D623d3a316995d90891eD91EdD2374C;
  address private constant payoutAddress2 = 0x69B063E93E653945B99587E8c3Cb35de348A839D;

  uint256 public constant MAX_MULTIMINT = 20;
  uint256 public constant MAX_SUPPLY = 144;
  uint256 public price = 69420000000000000;

  Counters.Counter private supplyCounter;
  bool public saleIsActive = false;
  string private customBaseURI;

  constructor(string memory customBaseURI_) ERC721("TomTurkeys", "TT") {
    customBaseURI = customBaseURI_;
  }

 function mint(uint256 count) public payable nonReentrant {
    require(saleIsActive, "Sale not active");

    require(totalSupply() + count - 1 < MAX_SUPPLY, "Exceeds max supply");

    require(count <= MAX_MULTIMINT, "Mint at most 20 at a time");

    require(
      msg.value >= price * count, "Insufficient payment"
    );

    for (uint256 i = 0; i < count; i++) {
      _mint(msg.sender, totalSupply());

      supplyCounter.increment();
    }
  }

  function totalSupply() public view returns (uint256) {
    return supplyCounter.current();
  }

  function setSaleIsActive(bool saleIsActive_) external onlyOwner {
    saleIsActive = saleIsActive_;
  }

  function setBaseURI(string memory customBaseURI_) external onlyOwner {
    customBaseURI = customBaseURI_;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return customBaseURI;
  }

  function setSalePrice(uint256 newPrice) external onlyOwner {
    price = newPrice;
  }

  function withdraw() public nonReentrant {
    uint256 balance = address(this).balance;

    Address.sendValue(payable(owner()), balance * 40 / 100);

    Address.sendValue(payable(payoutAddress1), balance * 40 / 100);

    Address.sendValue(payable(payoutAddress2), balance * 20 / 100);
  }
}