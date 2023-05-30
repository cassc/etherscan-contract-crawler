// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TruePlebs is ERC721A, Ownable {
  string _baseTokenURI;
  
  bool public isActive = false;

  uint256 public price = 0.0069 ether;
  uint256 public MAX_PER_TX = 10;
  uint256 public MAX_SUPPLY = 5555;
  uint256 public constant FREE_MAX_SUPPLY = 1000;
  uint256 public constant MAX_PER_TX_FREE = 1;
  uint256 public reserve = 100;

  constructor(string memory baseURI) ERC721A("True Plebs", "TP") {

  }

  modifier saleIsOpen {
    require(totalSupply() <= MAX_SUPPLY, "Sale has ended.");
    _;
  }

  function toggleSaleStatus() public onlyOwner {
    isActive = !isActive;
  }

  function setBaseURI(string memory baseURI) public onlyOwner {
    _baseTokenURI = baseURI;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return _baseTokenURI;
  }

  function mint(uint256 _count) public payable saleIsOpen {
    uint256 mintIndex = totalSupply();
    uint256 discountPrice = _count;

    if (msg.sender != owner()) {
      require(isActive, "Sale is not active currently.");
    }

    require(mintIndex + _count <= MAX_SUPPLY, "Total supply exceeded.");
    require(
      _count <= MAX_PER_TX,
      "Exceeds maximum allowed tokens"
    );

    if (mintIndex > FREE_MAX_SUPPLY) {
      if (_count > 1) {
        discountPrice = _count - 1;
      }

      if (balanceOf(msg.sender) >= 1 || _count > 1) {
        require(msg.value >= price * discountPrice, "Insufficient ETH amount sent.");
      }
    }
   
    _safeMint(msg.sender, _count);
  }

  function devMint() external onlyOwner {
    require(1 + _numberMinted(msg.sender) <= reserve, "Already minted");
    _safeMint(msg.sender, reserve);
  }

  function tokenURI(uint256 id) public view virtual override returns (string memory) {
    require(_exists(id), "Metadata: URI query for nonexistent token");

    return string(abi.encodePacked(_baseTokenURI, Strings.toString(id), ".json"));
  }

  function withdrawMoney() external onlyOwner {
    (bool success, ) = msg.sender.call{value: address(this).balance}("");
    require(success, "Transfer failed.");
  }
}