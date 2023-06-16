// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "erc721a/contracts/ERC721A.sol";

contract GarageGenesisPlus is ERC721A, Ownable {
  uint256 public version1; // Unique ABI tag for Etherscan

  uint256 public supplyCap; // Hard cap
  uint256 public maxSupply; // Soft cap (<= supplyCap)

  uint256 public mintPrice;   // Applies to both private and public sale
  uint256 public publicLimit; // Set to >0 to start public sale

  string public baseURI; // Should end either with "?" (shared by all tokens) or "/" (per-token)

  constructor(uint256 cap, uint256 supply, uint256 price) ERC721A("GarageGenesisPlus", "GARAGE") {
    transferOwnership(tx.origin);
    require(supply <= cap, "supply exceeds cap");
    supplyCap = cap;
    maxSupply = supply;
    mintPrice = price;
  }

  function setSupplyCap(uint256 newCap) external onlyOwner {
    supplyCap = Math.max(totalSupply(), Math.min(supplyCap, newCap));
    maxSupply = Math.max(totalSupply(), Math.min(supplyCap, maxSupply));
  }

  function setMaxSupply(uint256 newSupply) external onlyOwner {
    maxSupply = Math.max(totalSupply(), Math.min(supplyCap, newSupply));
  }

  function setMintPrice(uint256 newPrice) external onlyOwner {
    mintPrice = newPrice;
  }

  function setPublicLimit(uint256 newLimit) external onlyOwner {
    publicLimit = newLimit;
  }

  function setBaseURI(string memory newBaseURI) external onlyOwner {
    baseURI = newBaseURI;
  }

  function _baseURI() internal view override returns (string memory) {
    return baseURI;
  }

  function setPrivateLimit(address[] calldata addresses, uint256[] calldata num) external onlyOwner {
    require(addresses.length == num.length, "array length mismatch");
    for (uint256 i = 0; i < addresses.length; i++) {
      _setAux(addresses[i], SafeCast.toUint64(num[i]));
    }
  }

  function privateLimit(address owner) public view returns (uint64) {
    return _getAux(owner);
  }

  function numberMinted(address owner) external view returns (uint256) {
    return _numberMinted(owner);
  }

  function ownershipStart(uint256 tokenId) external view returns (uint64) {
    return ownershipOf(tokenId).startTimestamp;
  }

  function mint(uint256 num) external payable {
    mintTo(msg.sender, num);
  }

  function mintTo(address recipient, uint256 num) public payable {
    require(tx.origin == msg.sender, "called from contract");
    require(totalSupply() + num <= maxSupply, "max supply reached");

    uint256 price = recipient == owner() ? 0 : mintPrice;
    require(msg.value == price * num, "wrong payment amount");

    uint256 minted = _numberMinted(recipient);
    uint256 limit = Math.max(publicLimit, privateLimit(recipient));
    uint256 remaining = limit > minted ? limit - minted : 0;
    require(num <= remaining, "mint limit exceeded");

    _safeMint(recipient, num);
  }

  function withdraw() external onlyOwner {
    withdrawTo(msg.sender);
  }

  function withdrawTo(address recipient) public onlyOwner {
    Address.sendValue(payable(recipient), address(this).balance);
  }
}