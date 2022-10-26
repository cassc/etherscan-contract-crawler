// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "erc721a/contracts/ERC721A.sol";

contract WarriorsOnBlur is ERC721A, Ownable, PaymentSplitter, ReentrancyGuard {
  using SafeMath for uint256;
  using Address for address;
  using Strings for uint256;

  uint16 public maxSupply = 6000;

  bool public PAID_MINT_IS_ACTIVE = false;
  uint256 public PAID_MINT_PRICE = 0.003 ether;
  uint16 public PAID_MINT_TX_LIMIT = 10;

  bool public freeMintIsActive = false;
  uint16 public freeMintWalletLimit = 1;
  uint16 public freeMintAllocation = 0;
  mapping(address => uint16) public freeMintCount;

  bool public revealed = false;
  string public unrevealedURI = "";
  string public baseURI = "";

  mapping (address => bool) public disabledOperators;

  constructor(string memory _baseURI, string memory _unrevealedURI, address[] memory _payees, uint256[] memory _payeeShares, address[] memory _disabledOperators)
    ERC721A("Warriors On Blur", "WARRIORSONBLUR")
    PaymentSplitter(_payees, _payeeShares)
  {
    baseURI = _baseURI;
    unrevealedURI = _unrevealedURI;

    for (uint256 i = 0; i < _disabledOperators.length; i++) {
      disabledOperators[_disabledOperators[i]] = true;
    }
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

  function tokensOfOwner(address _owner) external view returns (uint256[] memory) {
    uint256 tokenIdsIdx;
    address currOwnershipAddr;
    uint256 tokenIdsLength = balanceOf(_owner);
    uint256[] memory tokenIds = new uint256[](tokenIdsLength);
    TokenOwnership memory ownership;

    for (uint256 i = _startTokenId(); tokenIdsIdx != tokenIdsLength; i++) {
      ownership = _ownershipOf(i);
      if (ownership.burned) {
        continue;
      }
      if (ownership.addr != address(0)) {
        currOwnershipAddr = ownership.addr;
      }
      if (currOwnershipAddr == _owner) {
        tokenIds[tokenIdsIdx++] = i;
      }
    }
    return tokenIds;
  }

  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
    require(_exists(_tokenId), "invalid token");
    if (!revealed) {
      return unrevealedURI;
    }
    return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, _tokenId.toString(), ".json")) : '';
  }

  function approve(address to, uint256 id) public payable virtual override {
    require(!disabledOperators[to], "This operator is disabled");
    super.approve(to, id);
  }

  function setApprovalForAll(address operator, bool approved) public virtual override {
    require(!disabledOperators[operator], "This operator is disabled");
    super.setApprovalForAll(operator, approved);
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

  function disableOperators(address[] calldata _operators) external onlyOwner {
    for (uint256 i = 0; i < _operators.length; i++) {
      disabledOperators[_operators[i]] = true;
    }
  }

  function enableOperators(address[] calldata _operators) external onlyOwner {
    for (uint256 i = 0; i < _operators.length; i++) {
      disabledOperators[_operators[i]] = false;
    }
  }
  
  function airDrop(address _to, uint16 _quantity) external onlyOwner {
    require(_to != address(0), "invalid address");
    require(_quantity > 0 && _quantity <= tokensRemaining(), "invalid quantity");
    _safeMint(_to, _quantity);
  }
}