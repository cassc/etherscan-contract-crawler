// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import {ConfigSettings} from "gwei-slim-nft-contracts/contracts/base/ERC721Base.sol";
import {ERC721Delegated} from "gwei-slim-nft-contracts/contracts/base/ERC721Delegated.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract ORCTownRoad is ERC721Delegated, ReentrancyGuard {
  using Counters for Counters.Counter;

  constructor(address baseFactory, string memory customBaseURI_)
    ERC721Delegated(
      baseFactory,
      "ORC Town Road",
      "OTR",
      ConfigSettings({
        royaltyBps: 750,
        uriBase: customBaseURI_,
        uriExtension: "",
        hasTransferHook: false
      })
    )
  {}

  /** MINTING LIMITS **/

  mapping(address => uint256) private mintCountMap;

  mapping(address => uint256) private allowedMintCountMap;

  uint256 public constant MINT_LIMIT_PER_WALLET = 2;

  function allowedMintCount(address minter) public view returns (uint256) {
    return MINT_LIMIT_PER_WALLET - mintCountMap[minter];
  }

  function updateMintCount(address minter, uint256 count) private {
    mintCountMap[minter] += count;
  }

  /** MINTING **/

  uint256 public constant MAX_SUPPLY = 6969;

  uint256 public constant MAX_MULTIMINT = 2;

  Counters.Counter private supplyCounter;

  function mint(uint256 count) public nonReentrant {
    require(saleIsActive, "Sale not active");

    if (allowedMintCount(msg.sender) >= count) {
      updateMintCount(msg.sender, count);
    } else {
      revert("Minting limit exceeded");
    }

    require(totalSupply() + count - 1 < MAX_SUPPLY, "Exceeds max supply");

    require(count <= MAX_MULTIMINT, "Mint at most 2 at a time");

    for (uint256 i = 0; i < count; i++) {
      _mint(msg.sender, totalSupply());

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
  }

  /** URI HANDLING **/

  function setBaseURI(string memory customBaseURI_) external onlyOwner {
    _setBaseURI(customBaseURI_, "");
  }

  function tokenURI(uint256 tokenId) public view returns (string memory) {
    return string(abi.encodePacked(_tokenURI(tokenId), ".json"));
  }

  /** PAYOUT **/

  function withdraw() public nonReentrant {
    uint256 balance = address(this).balance;

    Address.sendValue(payable(_owner()), balance);
  }
}

// Contract created with Studio 721 v1.5.0
// https://721.so