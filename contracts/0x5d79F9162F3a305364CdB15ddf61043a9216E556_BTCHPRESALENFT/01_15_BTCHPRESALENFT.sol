// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract BTCHPRESALENFT is ERC721Enumerable, ReentrancyGuard, Ownable {
  using Counters for Counters.Counter;

  constructor(string memory customBaseURI_) ERC721("BTCH PRESALE NFT", "BPN") {
    customBaseURI = customBaseURI_;
  }

  /** MINTING **/

  uint256 public constant MAX_SUPPLY = 20980;

  uint256 public constant MAX_MULTIMINT = 100;

  uint256 public constant PRICE = 6900000000000000;

  function mint(uint256 count) public payable nonReentrant {
    require(saleIsActive, "Sale not active");

    require(totalSupply() + count - 1 < MAX_SUPPLY, "Exceeds max supply");

    require(count <= MAX_MULTIMINT, "Mint at most 100 at a time");

    require(
      msg.value >= PRICE * count, "Insufficient payment, 0.0069 ETH per item"
    );

    for (uint256 i = 0; i < count; i++) {
      _mint(msg.sender, totalSupply());
    }
  }

  /** ACTIVATION **/

  bool public saleIsActive = true;

  function setSaleIsActive(bool saleIsActive_) external onlyOwner {
    saleIsActive = saleIsActive_;
  }

  /** URI HANDLING **/

  string private customBaseURI;

  function setBaseURI(string memory customBaseURI_) external onlyOwner {
    customBaseURI = customBaseURI_;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return customBaseURI;
  }

  function tokenURI(uint256) public view override returns (string memory) {
    return _baseURI();
  }

  /** PAYOUT **/

  function withdraw() public nonReentrant {
    uint256 balance = address(this).balance;

    Address.sendValue(payable(owner()), balance);
  }
}

// Contract created with Studio 721 v1.5.0
// https://721.so