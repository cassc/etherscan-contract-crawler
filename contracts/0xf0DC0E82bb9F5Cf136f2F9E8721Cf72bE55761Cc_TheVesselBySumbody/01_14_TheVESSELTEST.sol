// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract TheVesselBySumbody is ERC721, ReentrancyGuard, Ownable {
  using Counters for Counters.Counter;

  constructor(string memory customBaseURI_)
    ERC721("The Vessel By Sumbody", "TVSS")
  {
    customBaseURI = customBaseURI_;
  }

  /** MINTING **/

  uint256 public constant MAX_SUPPLY = 100;

  uint256 public constant MAX_MULTIMINT = 20;

  uint256 public constant PRICE = 180000000000000000;

  Counters.Counter private supplyCounter;

  event SaleActive(bool saleIsActive);

  function mint(uint256[] calldata ids) public payable nonReentrant {
    uint256 count = ids.length;

    require(saleIsActive, "Sale not active");

    require(totalSupply() + count - 1 < MAX_SUPPLY, "Exceeds max supply");

    require(count <= MAX_MULTIMINT, "Mint at most 20 at a time");

    require(
      msg.value >= PRICE * count, "Insufficient payment, 0.18 ETH per item"
    );

    for (uint256 i = 0; i < count; i++) {
      uint256 id = ids[i];

      require(id < MAX_SUPPLY, "Invalid token id");

      _mint(msg.sender, id);

      supplyCounter.increment();
    }
  }

  function totalSupply() public view returns (uint256) {
    return supplyCounter.current();
  }

  /** ACTIVATION **/

  bool public saleIsActive = false;

  function setSaleIsActive(bool saleIsActive_) external onlyOwner {
    saleIsActive = saleIsActive_;
    emit SaleActive(saleIsActive_);
  }

  /** URI HANDLING **/

  string private customBaseURI;

  function setBaseURI(string memory customBaseURI_) external onlyOwner {
    customBaseURI = customBaseURI_;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return customBaseURI;
  }

  function tokenURI(uint256 tokenId) public view override
    returns (string memory)
  {
    return string(abi.encodePacked(super.tokenURI(tokenId), ".json"));
  }

  /** PAYOUT **/

  address private constant payoutAddress1 =
    0x1a9a4932F36B3641f5f63e98F77f8a1f28d85Dad;

  function withdraw() public nonReentrant {
    uint256 balance = address(this).balance;

    Address.sendValue(payable(payoutAddress1), balance);
  }
}

// Contract created with Studio 721 v1.5.0
// https://721.so