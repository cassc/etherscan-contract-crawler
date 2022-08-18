//SPDX-License-Identifier: MIT
//Contract based on [https://docs.openzeppelin.com/contracts/3.x/erc721](https://docs.openzeppelin.com/contracts/3.x/erc721)

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./ERC721A.sol";

contract HonoraryFrapes is ERC721A, Ownable, ReentrancyGuard {
  using Strings for uint256;

  string public baseURI;
  uint256 public maxSupply;

  constructor(
    string memory name,
    string memory symbol
  ) ERC721A(name, symbol) {
    baseURI = "ipfs://QmQZPJsSjQ45gx3fbsst4fNbXozsuVbiHDuDFLbZEFbref/";
    maxSupply = 4;
  }

  function mint(uint256 numberOfTokens) external onlyOwner {
    require(totalSupply() + numberOfTokens <= maxSupply, "Not enough remaining tokens");

    _safeMint(msg.sender, numberOfTokens);
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  function setBaseURI(string calldata newBaseURI) external onlyOwner {
    baseURI = newBaseURI;
  }

  function withdrawMoney() external onlyOwner nonReentrant {
    (bool success, ) = msg.sender.call{value: address(this).balance}("");
    require(success, "Transfer failed.");
  }

  function getOwnershipData(uint256 tokenId)
    external
    view
    returns (TokenOwnership memory)
  {
    return ownershipOf(tokenId);
  }

  function setMaxSupply(uint256 amount) external onlyOwner {
    require(amount > maxSupply, "Amount must be greater than current max supply.");
    maxSupply = amount;
  }
}