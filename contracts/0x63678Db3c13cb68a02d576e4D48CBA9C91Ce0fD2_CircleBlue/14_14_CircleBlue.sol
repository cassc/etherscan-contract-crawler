// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@big-whale-labs/versioned-contract/contracts/Versioned.sol";

contract CircleBlue is ERC721, Ownable, Versioned {
  using Counters for Counters.Counter;

  Counters.Counter public tokenId;

  string public baseURI;
  uint256 public idCap = 1000;
  uint256 public mintCost = 0.013 ether;

  constructor(
    string memory tokenName,
    string memory tokenSymbol,
    string memory version,
    string memory _newBaseURI
  ) ERC721(tokenName, tokenSymbol) Versioned(version) {
    baseURI = _newBaseURI;
  }

  function tokenURI(
    uint256
  ) public view virtual override returns (string memory) {
    return baseURI;
  }

  function setBaseURI(string memory _newBaseURI) external onlyOwner {
    baseURI = _newBaseURI;
  }

  function setMintCost(uint256 _newMintCost) external onlyOwner {
    mintCost = _newMintCost;
  }

  function setIdCap(uint256 _idCap) external onlyOwner {
    idCap = _idCap;
  }

  function mint() external payable {
    uint256 _tokenId = tokenId.current();
    // Check if value is > mintCost
    require(
      msg.value >= mintCost,
      "Value must be greater or equal to mintCost"
    );
    require(_tokenId < idCap, "This token is unmintable!");
    // Mint
    _safeMint(msg.sender, _tokenId);
    // Send value to owner
    payable(owner()).transfer(msg.value);
    // Increment tokenId
    tokenId.increment();
  }
}