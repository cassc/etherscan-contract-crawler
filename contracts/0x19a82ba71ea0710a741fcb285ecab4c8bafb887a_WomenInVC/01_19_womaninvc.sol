// SPDX-License-Identifier: UNLICENSED

// ███╗   ███╗ █████╗ ██████╗ ███████╗   ██╗    ██╗██╗████████╗██╗  ██╗   ███╗   ███╗ █████╗ ███████╗ ██████╗ ███╗   ██╗
// ████╗ ████║██╔══██╗██╔══██╗██╔════╝   ██║    ██║██║╚══██╔══╝██║  ██║   ████╗ ████║██╔══██╗██╔════╝██╔═══██╗████╗  ██║
// ██╔████╔██║███████║██║  ██║█████╗     ██║ █╗ ██║██║   ██║   ███████║   ██╔████╔██║███████║███████╗██║   ██║██╔██╗ ██║
// ██║╚██╔╝██║██╔══██║██║  ██║██╔══╝     ██║███╗██║██║   ██║   ██╔══██║   ██║╚██╔╝██║██╔══██║╚════██║██║   ██║██║╚██╗██║
// ██║ ╚═╝ ██║██║  ██║██████╔╝███████╗   ╚███╔███╔╝██║   ██║   ██║  ██║   ██║ ╚═╝ ██║██║  ██║███████║╚██████╔╝██║ ╚████║
// ╚═╝     ╚═╝╚═╝  ╚═╝╚═════╝ ╚══════╝    ╚══╝╚══╝ ╚═╝   ╚═╝   ╚═╝  ╚═╝   ╚═╝     ╚═╝╚═╝  ╚═╝╚══════╝ ╚═════╝ ╚═╝  ╚═══╝

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./EIP712Common.sol";
import "erc721a/contracts/ERC721A.sol";

contract WomenInVC is ERC721A, ReentrancyGuard, Ownable, EIP712Common{
  using Counters for Counters.Counter;

  uint256 public PRICE;
  uint256 public WHITELIST_PRICE;
  uint256 public MAX_SUPPLY;
  uint256 public MAX_RESERVED_SUPPLY;
  uint256 public MAX_PUBLIC_SUPPLY;
  uint256 public MAX_PER_WALLET;
  uint256 public MAX_MULTIMINT;
  uint256 public MAX_WHITELIST_MULTIMINT;

  Counters.Counter private reservedSupplyCounter;

  PaymentSplitter private _splitter;

  constructor (
    string memory tokenName,
    string memory tokenSymbol,
    string memory customBaseURI_,
    address[] memory payees,
    uint256[] memory shares,
    uint256 _tokenPrice,
    uint256 _tokensForSale,
    uint256 _tokensReserved
  ) ERC721A(tokenName, tokenSymbol) {
    customBaseURI = customBaseURI_;

    PRICE = _tokenPrice;
    WHITELIST_PRICE = _tokenPrice;

    MAX_SUPPLY = _tokensForSale;
    MAX_RESERVED_SUPPLY = _tokensReserved;
    MAX_PUBLIC_SUPPLY = MAX_SUPPLY - MAX_RESERVED_SUPPLY;

    MAX_PER_WALLET = 10;

    MAX_MULTIMINT = 10;
    MAX_WHITELIST_MULTIMINT = 10;

    _splitter = new PaymentSplitter(payees, shares);
  }


  /** MINTING **/

  function mint(uint256 count) public payable nonReentrant {
    require(saleIsActive, "Sale not active");
    require(msg.sender == tx.origin, "Contracts cannot mint");
    require(totalSupply() - totalReservedSupply() + count - 1 < MAX_PUBLIC_SUPPLY, "Exceeds max supply");
    require(count - 1 < MAX_MULTIMINT, "Trying to mint too many at a time");
    require(
      msg.value >= PRICE * count, "Insufficient payment"
    );

    if (allowedMintCount(msg.sender) > count) {
      updateMintCount(msg.sender, count);
    } else {
      revert("Minting limit exceeded");
    }

    _safeMint(msg.sender, count);

    payable(_splitter).transfer(msg.value);
  }

  function ownerMint(uint256 count, address recipient) external onlyOwner() {
    require(totalReservedSupply() + count - 1 < MAX_RESERVED_SUPPLY, "Exceeds max reserved supply");
    require(totalSupply() + count - 1 < MAX_SUPPLY , "Exceeds max supply");

    for (uint256 i = 0; i < count;) {
      reservedSupplyCounter.increment();
      unchecked { ++i; }
    }

    _safeMint(recipient, count);
  }

    function whitelistMint(uint256 count, bytes calldata signature) public payable requiresWhitelist(signature) nonReentrant {
    require(whitelistIsActive, "Whitelist not active");
    require(totalSupply() - totalReservedSupply()  + count - 1 < MAX_PUBLIC_SUPPLY, "Exceeds max supply");
    require(count - 1 < MAX_WHITELIST_MULTIMINT, "Trying to mint too many at a time");
    require(
      msg.value >= WHITELIST_PRICE * count, "Insufficient payment"
    );

    if (allowedMintCount(msg.sender) > count) {
      updateMintCount(msg.sender, count);
    } else {
      revert("Minting limit exceeded");
    }

    _safeMint(msg.sender, count);

    payable(_splitter).transfer(msg.value);
  }

  function totalReservedSupply() public view returns (uint256) {
    return reservedSupplyCounter.current();
  }

  /** ACTIVATION **/

  bool public saleIsActive = false;
  bool public whitelistIsActive = true;

  function flipSaleState() external onlyOwner {
    saleIsActive = !saleIsActive;
  }

  function flipWhitelistState() external onlyOwner {
    whitelistIsActive = !whitelistIsActive;
  }

  /** ADMIN **/

  function setPrice(uint256 _tokenPrice) external onlyOwner {
    PRICE = _tokenPrice;
  }

  function setWhitelistPrice(uint256 _tokenPrice) external onlyOwner {
    WHITELIST_PRICE = _tokenPrice;
  }

  function setMultiMint(uint256 _maxMultimint) external onlyOwner {
    MAX_MULTIMINT = _maxMultimint;
  }

  function setWhitelistMultiMint(uint256 _maxMultimint) external onlyOwner {
    MAX_WHITELIST_MULTIMINT = _maxMultimint;
  }

  function setMaxPerWallet(uint256 _maxPerWallet) external onlyOwner {
    MAX_PER_WALLET = _maxPerWallet;
  }

  /** MINTING LIMITS **/

  mapping(address => uint256) private mintCountMap;

  function allowedMintCount(address minter) public view returns (uint256) {
    return MAX_PER_WALLET - mintCountMap[minter];
  }

  function updateMintCount(address minter, uint256 count) private {
    mintCountMap[minter] += count;
  }

  /** Whitelist **/

  function checkWhitelist(bytes calldata signature) public view requiresWhitelist(signature) returns (bool) {
    return true;
  }

  /** URI HANDLING **/

  string private customBaseURI;

  function baseTokenURI() public view returns (string memory) {
    return customBaseURI;
  }

  function setBaseURI(string memory customBaseURI_) external onlyOwner {
    customBaseURI = customBaseURI_;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return customBaseURI;
  }

  /** PAYOUT **/

  function release(address payable account) public virtual onlyOwner {
    _splitter.release(account);
  }
}