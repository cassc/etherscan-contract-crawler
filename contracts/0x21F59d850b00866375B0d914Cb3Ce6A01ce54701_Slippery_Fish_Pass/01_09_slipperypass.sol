// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "erc721a/contracts/ERC721A.sol";

contract Slippery_Fish_Pass is ERC721A, Ownable, ReentrancyGuard {
  using Strings for uint256;
  using SafeMath for uint256;
  using ECDSA for bytes32;

  uint256 public MAX_SlipperyFishPass;
  uint256 public MAX_SlipperyFishPass_PER_PURCHASE;

  uint256 public SlipperyFishPass_PRICE = 0.0 ether;

  string public tokenBaseURI;
  string public unrevealedURI;

  bool public batchActive = false;

  constructor(
    uint256 _maxSlipperyFishPass,
    uint256 _maxSlipperyFishPassPerPurchase
  ) ERC721A("Slippery Fish Pass", "SFP") {
    MAX_SlipperyFishPass = _maxSlipperyFishPass;
    MAX_SlipperyFishPass_PER_PURCHASE = _maxSlipperyFishPassPerPurchase;
  }

  function setPrice(uint256 _newPrice) external onlyOwner {
    SlipperyFishPass_PRICE = _newPrice;
  }

  function setMaxPerPurchase(uint256 _newMaxPerPurchase) external onlyOwner {
    MAX_SlipperyFishPass_PER_PURCHASE = _newMaxPerPurchase;
  }

  function setTokenBaseURI(string memory _baseURI) external onlyOwner {
    tokenBaseURI = _baseURI;
  }

  function setUnrevealedURI(string memory _unrevealedUri) external onlyOwner {
    unrevealedURI = _unrevealedUri;
  }

  function tokenURI(uint256 _tokenId) override public view returns (string memory) {
    bool revealed = bytes(tokenBaseURI).length > 0;

    if (!revealed) {
      return unrevealedURI;
    }

    require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");

    return string(abi.encodePacked(tokenBaseURI, _tokenId.toString()));
  }

  function batchMint(uint256 _quantity, address _batchAddress) external onlyOwner {
    require(batchActive, "batch is not active");

    _batchMintSlipperyFishPass(_quantity, _batchAddress);
  }

  function _batchMintSlipperyFishPass(uint256 _quantity, address _batchAddress) internal {
    require(_quantity > 0, "You must mint at least 1 SlipperyFishPass");
    require(_totalMinted() + _quantity <= MAX_SlipperyFishPass, "This batch would exceed max supply of SlipperyFishPass");
    require(_quantity <= MAX_SlipperyFishPass_PER_PURCHASE, "Quantity is more than allowed per transaction.");

    _safeMint(_batchAddress, _quantity);
  }

  function batchTransfer(address[] calldata recipients, uint256[] calldata amounts) external onlyOwner {
    require(recipients.length > 0, "No recipients");
    require(recipients.length == amounts.length, "amounts argument size mismatched");

    for (uint256 i = 0; i < recipients.length; i++) {
      transferFrom(msg.sender, recipients[i], amounts[i]);
    }
  }

  function setbatchActive(bool _active) external onlyOwner {
    batchActive = _active;
  }

  function withdraw() public onlyOwner {
    uint256 balance = address(this).balance;
    payable(msg.sender).transfer(balance);
  }
}