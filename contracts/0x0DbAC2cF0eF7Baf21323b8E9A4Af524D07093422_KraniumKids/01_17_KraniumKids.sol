// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "erc721a/contracts/ERC721A.sol";

contract KraniumKids is ERC721A, Ownable, PaymentSplitter, ReentrancyGuard {
  using SafeMath for uint256;
  using Address for address;
  using Strings for uint256;

  uint16 public maxSupply = 999;

  bool public PAID_MINT_IS_ACTIVE = false;
  uint256 public PAID_MINT_PRICE = 0.005 ether;
  uint16 public PAID_MINT_TX_LIMIT = 10;

  bool public freeMintIsActive = false;
  uint16 public freeMintWalletLimit = 1;
  uint16 public freeMintAllocation = 0;
  mapping(address => uint16) public freeMintCount;

  bool public revealed = false;
  string public unrevealedURI = "";
  string public baseURI = "";

  address[] payees = [
    0xD8Fa1aDAE3d6ff33CED521F6D98Cf3321163590B,
    0x91D78C3624807c12B5aca4ee82988A3369da5Fd0
  ];

  uint256[] payeeShares = [
    50,
    50
  ];

  constructor(string memory _baseURI, string memory _unrevealedURI)
    ERC721A("999 Kranium Kids", "KRANIUMKIDS")
    PaymentSplitter(payees, payeeShares)
  {
    baseURI = _baseURI;
    unrevealedURI = _unrevealedURI;
  }

  function tokensRemaining() public view returns (uint256) {
    return uint256(maxSupply).sub(totalSupply());
  }

  function paidMint(uint16 _quantity) external payable nonReentrant {
    require(PAID_MINT_IS_ACTIVE, "mint is disabled");
    require(_quantity <= PAID_MINT_TX_LIMIT && _quantity <= tokensRemaining(), "invalid mint quantity");
    require(msg.value >= PAID_MINT_PRICE.mul(_quantity), "invalid mint value");

    _safeMint(msg.sender, _quantity);
  }

  function freeMint(uint16 _quantity) external payable nonReentrant {
    require(freeMintIsActive, "mint is disabled");
    require(_quantity <= freeMintAllocation, "insufficient free allocation");
    require(_quantity <= tokensRemaining(), "invalid mint quantity");

    uint16 alreadyFreeMinted = freeMintCount[msg.sender];
    require((alreadyFreeMinted + _quantity) <= freeMintWalletLimit, "exceeds free mint wallet limit");

    _safeMint(msg.sender, _quantity);

    freeMintCount[msg.sender] = alreadyFreeMinted + _quantity;
    freeMintAllocation -= _quantity;
  }

  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
    require(_exists(_tokenId), "invalid token");
    if (!revealed) {
      return unrevealedURI;
    }
    return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, _tokenId.toString(), ".json")) : '';
  }

  function setBaseURI(string memory _baseUri) external onlyOwner {
    baseURI = _baseUri;
  }

  function reduceMaxSupply(uint16 _maxSupply) external onlyOwner {
    require(_maxSupply < maxSupply, "must be less than curernt max supply");
    require(_maxSupply >= totalSupply(), "must be gte the total supply");
    require(_maxSupply >= freeMintAllocation, "must be gte free mint allocation");
    maxSupply = _maxSupply;
  }

  function paidMintIsActive() external view returns (bool) {
    return PAID_MINT_IS_ACTIVE;
  }

  function setPaidMintIsActive(bool _paidMintIsActive) external onlyOwner {
    PAID_MINT_IS_ACTIVE = _paidMintIsActive;
  }

  function paidMintPrice() external view returns (uint256) {
    return PAID_MINT_PRICE;
  }

  function setPaidMintPrice(uint256 _paidMintPrice) external onlyOwner {
    PAID_MINT_PRICE = _paidMintPrice;
  }

  function paidMintTxLimit() external view returns (uint16) {
    return PAID_MINT_TX_LIMIT;
  }

  function setPaidMintTxLimit(uint16 _paidMintTxLimit) external onlyOwner {
    PAID_MINT_TX_LIMIT = _paidMintTxLimit;
  }

  function setFreeMintWalletLimit(uint16 _freeMintWalletLimit) external onlyOwner {
    freeMintWalletLimit = _freeMintWalletLimit;
  }

  function setFreeMintIsActive(bool _freeMintIsActive) external onlyOwner {
    freeMintIsActive = _freeMintIsActive;
  }

  function setFreeMintAllocation(uint16 _freeMintAllocation) external onlyOwner {
    require(_freeMintAllocation <= tokensRemaining(), "exceeds total remaining");
    freeMintAllocation = _freeMintAllocation;
  }

  function setRevealed(bool _revealed) external onlyOwner {
    revealed = _revealed;
  }

  function setUnrevealedURI(string memory _unrevealedURI) external onlyOwner {
    unrevealedURI = _unrevealedURI;
  }

  function airDrop(address _to, uint16 _quantity) external onlyOwner {
    require(_to != address(0), "invalid address");
    require(_quantity > 0 && _quantity <= tokensRemaining(), "invalid quantity");
    _safeMint(_to, _quantity);
  }
}