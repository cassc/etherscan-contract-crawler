//SPDX-License-Identifier: Unlicense
//Criminal Guild Membership For Sidequest
//World Domination would be cool but capturing both Iresa and Lurvine is the goal.
//Criminal Membership is a freemint - secondary royalities will go to securing Side Quest adventures - and $QUEST


pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract CriminalMembership is ERC1155, Ownable, ReentrancyGuard {
  using Address for address;

  uint256 constant public MAX_SUPPLY = 700;
  uint256 constant public RESERVED = 10;
  uint256 constant public TOKEN_ID = 0;
  uint256 constant public maxPerWallet = 2;
  // Track mints
  mapping(address => uint256) walletMints;

  string public name = "CriminalMembership";
  string public symbol = "CRIMINAL";
  uint256 public totalSupply;
  bool public saleActive;

  constructor(string memory _uri) ERC1155(_uri) {
    _mint(msg.sender, TOKEN_ID, RESERVED, "");
    totalSupply += RESERVED;
  }

  function setMetadata(string memory _uri) public onlyOwner {
    _setURI(_uri);
  }

  function flipSaleActive() public onlyOwner {
    saleActive = !saleActive;
  }

  function mint(uint256 amount) public payable nonReentrant {
    require(saleActive,                         "Sale is not active");
    require(totalSupply + amount <= MAX_SUPPLY, "Exceeds maximum number of tokens");
    require(walletMints[msg.sender] + amount <= maxPerWallet, "Exceeds max per wallet");
    walletMints[msg.sender] += amount;
    _mint(msg.sender, TOKEN_ID, amount, "");
    totalSupply += amount;
  }

  function withdraw() onlyOwner public {
    Address.sendValue(payable(msg.sender), address(this).balance);
  }
}