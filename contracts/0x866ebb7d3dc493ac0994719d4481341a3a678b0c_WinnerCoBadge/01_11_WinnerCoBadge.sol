//SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "erc721a/contracts/ERC721A.sol";

contract WinnerCoBadge is ERC721A, Ownable {
  using Strings for string;
  using Address for address;

  uint256 public constant TOTAL_SUPPLY = 10000;

  uint256 public txLimit = 1;
  uint256 public walletLimit = 2;

  bool public isSaleActive = false;

  string public baseURI_; 

  constructor() ERC721A("WinnerCo ID Badge", "WCID") Ownable() {}

  function _baseURI() override internal view returns (string memory) {
    return baseURI_;
  }

  function mint(uint256 _amount, address _to) public {
    require(isSaleActive, "Sale is not active");
    require(_amount <= txLimit, "Amount exceeds tx limit");
    require(_numberMinted(_to) + _amount <= walletLimit, "Amount exceeds wallet limit");
    require(totalSupply() + _amount <= TOTAL_SUPPLY, "Total supply exceeds limit");

    _safeMint(_to, _amount);
  }

  // Owner Functions
  function setBaseURI(string calldata baseURI__) public onlyOwner {
    baseURI_ = baseURI__;
  }

  function setTxLimit(uint256 t) public onlyOwner {
    txLimit = t;
  }

  function setWalletLimit(uint256 w) public onlyOwner {
    walletLimit = w;
  }

  function setIsSalesActive(bool s) public onlyOwner {
    isSaleActive = s;
  }
}