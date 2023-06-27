// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import {ConfigSettings} from "gwei-slim-nft-contracts/contracts/base/ERC721Base.sol";
import {ERC721Delegated} from "gwei-slim-nft-contracts/contracts/base/ERC721Delegated.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract Vessels is ERC721Delegated, ReentrancyGuard {
  using Counters for Counters.Counter;

  constructor(address baseFactory, string memory customBaseURI_)
    ERC721Delegated(
      baseFactory,
      "Vessels",
      "VSSL",
      ConfigSettings({
        royaltyBps: 1000,
        uriBase: customBaseURI_,
        uriExtension: "",
        hasTransferHook: false
      })
    )
  {
    allowedMintCountMap[msg.sender] = 10;

    allowedMintCountMap[0x90D65F8AD70d018115b7499BBcE2E71eC66dc064] = 40;
  }

  /** MINTING LIMITS **/

  mapping(address => uint256) private mintCountMap;

  mapping(address => uint256) private allowedMintCountMap;

  uint256 public constant MINT_LIMIT_PER_WALLET = 20;

  function max(uint256 a, uint256 b) private pure returns (uint256) {
    return a >= b ? a : b;
  }

  function allowedMintCount(address minter) public view returns (uint256) {
    if (saleIsActive) {
      return (
        max(allowedMintCountMap[minter], MINT_LIMIT_PER_WALLET) -
        mintCountMap[minter]
      );
    }

    return allowedMintCountMap[minter] - mintCountMap[minter];
  }

  function updateMintCount(address minter, uint256 count) private {
    mintCountMap[minter] += count;
  }

  /** MINTING **/

  uint256 public constant MAX_SUPPLY = 433;

  uint256 public constant MAX_MULTIMINT = 20;

  uint256 public constant PRICE = 100000000000000000;

  Counters.Counter private supplyCounter;

  function mint(uint256 count) public payable nonReentrant {
    if (allowedMintCount(msg.sender) >= count) {
      updateMintCount(msg.sender, count);
    } else {
      revert(saleIsActive ? "Minting limit exceeded" : "Sale not active");
    }

    require(totalSupply() + count - 1 < MAX_SUPPLY, "Exceeds max supply");

    require(count <= MAX_MULTIMINT, "Mint at most 20 at a time");

    require(
      msg.value >= PRICE * count, "Insufficient payment, 0.1 ETH per item"
    );

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

  address private constant payoutAddress1 =
    0x90D65F8AD70d018115b7499BBcE2E71eC66dc064;

  address private constant payoutAddress2 =
    0xeb418E53EFcDc351137C9A81c70967b8D7063f4C;

  address private constant payoutAddress3 =
    0x813b9B79Ad45eE466DF3a2b3ED31c47aC3B281AA;

  address private constant payoutAddress4 =
    0xb71cCC1DB28312CB2688e0881230f91fCb2085E2;

  function withdraw() public nonReentrant {
    uint256 balance = address(this).balance;

    Address.sendValue(payable(payoutAddress1), balance * 91 / 100);

    Address.sendValue(payable(payoutAddress2), balance * 6 / 100);

    Address.sendValue(payable(payoutAddress3), balance * 3 / 100);

    Address.sendValue(payable(payoutAddress4), balance * 3 / 100);
  }
}

// Contract created with Studio 721 v1.5.0
// https://721.so