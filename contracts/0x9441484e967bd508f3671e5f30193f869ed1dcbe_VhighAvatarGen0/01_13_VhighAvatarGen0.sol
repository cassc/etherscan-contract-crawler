// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract VhighAvatarGen0 is ERC721, ReentrancyGuard, Ownable {
  using Counters for Counters.Counter;

  constructor(string memory customBaseURI_) ERC721("Vhigh! Avatar Gen 0.0", "VAG0") {
    customBaseURI = customBaseURI_;
  }

  /** MINTING LIMITS **/

  mapping(address => uint256) private mintCountMap;

  uint256 public constant MINT_LIMIT_PER_WALLET = 1;

  function allowedMintCount(address minter) public view returns (uint256) {
    return MINT_LIMIT_PER_WALLET - mintCountMap[minter];
  }

  function updateMintCount(address minter) private {
    mintCountMap[minter] += 1;
  }

  /** MINTING **/

  uint256 public constant MAX_SUPPLY = 1000;

  Counters.Counter private supplyCounter;

  function ownerBatchMint(address minter) public onlyOwner {
    uint256 _currentId = totalSupply();

    for (uint256 i = 0; i < 11; i++) {
      _safeMint(minter, (_currentId + i));
      supplyCounter.increment();
    }
  }

  function mint() public nonReentrant {
    require(saleIsActive, "Sale not active");

    if (allowedMintCount(_msgSender()) >= 1) {
      updateMintCount(_msgSender());
    } else {
      revert("Minting limit exceeded");
    }

    require(totalSupply() < MAX_SUPPLY, "Exceeds max supply");

    _safeMint(_msgSender(), totalSupply());

    supplyCounter.increment();
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

  string private customBaseURI;

  function setBaseURI(string memory customBaseURI_) external onlyOwner {
    customBaseURI = customBaseURI_;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return customBaseURI;
  }
}