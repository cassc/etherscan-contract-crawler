// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
// Proof of Authenticity: 55e5b53824706b754e0b36164b7d08d177eb8d51a12078eca7c5ad5b2bef753d

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract Euc is ERC721Enumerable, ReentrancyGuard, Ownable {
  using Counters for Counters.Counter;
  constructor() ERC721("Euclidean Nodes", "EUC") {
  }
  mapping(address => uint256) private mintCountMap;
  mapping(address => uint256) private allowedMintCountMap;
  uint256 public constant MINT_LIMIT_PER_WALLET = 512;
  function allowedMintCount(address minter) public view returns (uint256) {
    return MINT_LIMIT_PER_WALLET - mintCountMap[minter];
  }
  function updateMintCount(address minter, uint256 count) private {
    mintCountMap[minter] += count;
  }
  uint256 public constant MAX_SUPPLY = 512;
  uint256 public constant MAX_MULTIMINT = 512;
  uint256 public constant PRICE = 0;
  function mint(uint256 _mintAmount) public payable nonReentrant onlyOwner {
  uint256 supply = totalSupply();
    require(saleIsActive, "Sale not active");
    require(_mintAmount > 0);
    require(_mintAmount <= MAX_MULTIMINT);
    require(supply + _mintAmount <= MAX_SUPPLY);
    if (msg.sender != owner()) {
      require(msg.value >= PRICE * _mintAmount);
    }
    for (uint256 i = 1; i <= _mintAmount; i++) {
      _safeMint(msg.sender, supply + i);
    }
  }
  bool public saleIsActive = true;
  function setSaleIsActive(bool saleIsActive_) external onlyOwner {
    saleIsActive = saleIsActive_;
  }
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
  function withdraw() public nonReentrant {
    uint256 balance = address(this).balance;
    Address.sendValue(payable(owner()), balance);
  }
}