// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import {ConfigSettings} from "gwei-slim-nft-contracts/contracts/base/ERC721Base.sol";
import {ERC721Delegated} from "gwei-slim-nft-contracts/contracts/base/ERC721Delegated.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract OwnableDelegateProxy {}

contract ProxyRegistry {
  mapping(address => OwnableDelegateProxy) public proxies;
}

contract CanvasbyFeltZine is ERC721Delegated, ReentrancyGuard {
  using Counters for Counters.Counter;

  constructor(
    address baseFactory,
    string memory customBaseURI_,
    address proxyRegistryAddress_
  )
    ERC721Delegated(
      baseFactory,
      "Canvas by Felt Zine",
      "CNVS",
      ConfigSettings({
        royaltyBps: 1000,
        uriBase: customBaseURI_,
        uriExtension: "",
        hasTransferHook: false
      })
    )
  {
    proxyRegistryAddress = proxyRegistryAddress_;
  }

  /** MINTING **/

  uint256 public constant MAX_SUPPLY = 500;

  uint256 public constant MAX_MULTIMINT = 20;

  uint256 public constant PRICE = 30000000000000000;

  Counters.Counter private supplyCounter;

  function mint(uint256 count) public payable nonReentrant {
    require(saleIsActive, "Sale not active");

    require(totalSupply() + count - 1 < MAX_SUPPLY, "Exceeds max supply");

    require(count <= MAX_MULTIMINT, "Mint at most 20 at a time");

    require(
      msg.value >= PRICE * count, "Insufficient payment, 0.03 ETH per item"
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

  /** PAYOUT **/

  function withdraw() public nonReentrant {
    uint256 balance = address(this).balance;

    Address.sendValue(payable(_owner()), balance);
  }

  /** PROXY REGISTRY **/

  address private immutable proxyRegistryAddress;

  function isApprovedForAll(address owner, address operator) public view
    returns (bool)
  {
    ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);

    if (address(proxyRegistry.proxies(owner)) == operator) {
      return true;
    }

    return _isApprovedForAll(owner, operator);
  }
}

// Contract created with Studio 721 v1.5.0
// https://721.so