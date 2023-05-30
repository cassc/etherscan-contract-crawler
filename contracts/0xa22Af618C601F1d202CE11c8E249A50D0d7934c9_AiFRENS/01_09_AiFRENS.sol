// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "erc721a/contracts/ERC721A.sol";

contract AiFRENS is ERC721A, Ownable, ReentrancyGuard {
  using Strings for uint256;
  using SafeMath for uint256;
  using ECDSA for bytes32;

  uint256 public MAX_AiFRENS;
  uint256 public MAX_AiFRENS_PER_PURCHASE;
  uint256 public MAX_AiFRENS_GIFT_CAP;
  uint256 public MAX_AiFRENS_PRESALE_CAP;

  uint256 public AiFRENS_PRICE = 0.00 ether;

  string public tokenBaseURI;
  string public unrevealedURI;

  bool public presaleActive = false;
  bool public mintActive = false;
  bool public giftActive = false;

  mapping(address => uint256) private presaleAddressMintCount;

  constructor(
    uint256 _maxAiFRENS,
    uint256 _maxAiFRENSPerPurchase,
    uint256 _maxAiFRENSpresaleCap
  ) ERC721A("AiFRENS Series 1", "AiF1") {
    MAX_AiFRENS = _maxAiFRENS;
    MAX_AiFRENS_PER_PURCHASE = _maxAiFRENSPerPurchase;
    MAX_AiFRENS_PRESALE_CAP = _maxAiFRENSpresaleCap;
  }

  function setPrice(uint256 _newPrice) external onlyOwner {
    AiFRENS_PRICE = _newPrice;
  }

  function setPreSaleCap(uint256 _newPresaleCap) external onlyOwner {
    MAX_AiFRENS_PRESALE_CAP = _newPresaleCap;
  }

  function setMaxPerPurchase(uint256 _newMaxPerPurchase) external onlyOwner {
    MAX_AiFRENS_PER_PURCHASE = _newMaxPerPurchase;
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

  function giftMint(uint256 _quantity, address _giftAddress) external onlyOwner {
    require(giftActive, "Gift is not active");

    _giftMintAiFRENS(_quantity, _giftAddress);
  }

  function _giftMintAiFRENS(uint256 _quantity, address _giftAddress) internal {
    require(_quantity > 0, "You must mint at least 1 AiFRENS");
    require(_totalMinted() + _quantity <= MAX_AiFRENS, "This gift would exceed max supply of AiFRENS");
    require(_quantity <= MAX_AiFRENS_PER_PURCHASE, "Quantity is more than allowed per transaction.");

    _safeMint(_giftAddress, _quantity);
  }

  function presaleMint(uint256 _quantity, bytes calldata _presaleSignature) external payable nonReentrant {
    require(presaleActive, "Presale is not active");
    require(verifyOwnerSignature(keccak256(abi.encode(msg.sender)), _presaleSignature), "Invalid presale signature");
    require(_quantity <= MAX_AiFRENS_PRESALE_CAP, "This would exceed the maximum AiFRENS you are allowed to mint in presale");
    require(msg.value >= AiFRENS_PRICE * _quantity, "The ether value sent is not correct");
    require(presaleAddressMintCount[msg.sender].add(_quantity) <= MAX_AiFRENS_PRESALE_CAP, "This purchase would exceed the maximum AiFRENS you are allowed to mint in the presale");

    presaleAddressMintCount[msg.sender] += _quantity;
    _safeMintAiFRENS(_quantity);
  }

  function publicMint(uint256 _quantity) external payable nonReentrant {
    require(mintActive, "Public sale is not active.");
    require(tx.origin == msg.sender, "The caller is another contract");
    require(msg.value >= AiFRENS_PRICE * _quantity, "The ether value sent is not correct");

    _safeMintAiFRENS(_quantity);
  }

  function _safeMintAiFRENS(uint256 _quantity) internal {
    require(_quantity > 0, "You must mint at least 1 AiFREN");
    require(_quantity <= MAX_AiFRENS_PER_PURCHASE, "Quantity is more than allowed per transaction.");
    require(_totalMinted() + _quantity <= MAX_AiFRENS, "This purchase would exceed max supply of AiFRENS");

    _safeMint(msg.sender, _quantity);
  }

  function setPresaleActive(bool _active) external onlyOwner {
    presaleActive = _active;
  }

  function setGiftActive(bool _active) external onlyOwner {
    giftActive = _active;
  }

  function setMintActive(bool _active) external onlyOwner {
    mintActive = _active;
  }

  function withdraw() public onlyOwner {
    uint256 balance = address(this).balance;
    payable(msg.sender).transfer(balance);
  }

  function verifyOwnerSignature(bytes32 hash, bytes memory signature) private view returns(bool) {
    return hash.toEthSignedMessageHash().recover(signature) == owner();
  }
}