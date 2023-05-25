// SPDX-License-Identifier: UNLICENSED

// ███╗   ███╗ █████╗ ██████╗ ███████╗    ██╗    ██╗██╗████████╗██╗  ██╗    ███╗   ███╗ █████╗ ███████╗ ██████╗ ███╗   ██╗
// ████╗ ████║██╔══██╗██╔══██╗██╔════╝    ██║    ██║██║╚══██╔══╝██║  ██║    ████╗ ████║██╔══██╗██╔════╝██╔═══██╗████╗  ██║
// ██╔████╔██║███████║██║  ██║█████╗      ██║ █╗ ██║██║   ██║   ███████║    ██╔████╔██║███████║███████╗██║   ██║██╔██╗ ██║
// ██║╚██╔╝██║██╔══██║██║  ██║██╔══╝      ██║███╗██║██║   ██║   ██╔══██║    ██║╚██╔╝██║██╔══██║╚════██║██║   ██║██║╚██╗██║
// ██║ ╚═╝ ██║██║  ██║██████╔╝███████╗    ╚███╔███╔╝██║   ██║   ██║  ██║    ██║ ╚═╝ ██║██║  ██║███████║╚██████╔╝██║ ╚████║
// ╚═╝     ╚═╝╚═╝  ╚═╝╚═════╝ ╚══════╝     ╚══╝╚══╝ ╚═╝   ╚═╝   ╚═╝  ╚═╝    ╚═╝     ╚═╝╚═╝  ╚═╝╚══════╝ ╚═════╝ ╚═╝  ╚═══╝

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "./EIP712Whitelisting.sol";

contract LinksDAO is ERC721, ReentrancyGuard, Ownable, EIP712Whitelisting {
  using Counters for Counters.Counter;

    /** MINTING **/
  uint256 public MAX_STANDARD_PER_WALLET;
  uint256 public MAX_PREMIUM_PER_WALLET;
  uint256 public PREMIUM_PRICE;
  uint256 public STANDARD_PRICE;
  uint256 public MAX_STANDARD_SUPPLY;
  uint256 public MAX_PREMIUM_SUPPLY;
  uint256 public MAX_SUPPLY;
  uint256 public MAX_STANDARD_RESERVED_SUPPLY;
  uint256 public MAX_PREMIUM_RESERVED_SUPPLY;
  uint256 public MAX_MULTIMINT;
  uint256 public MAX_STANDARD_WHITELIST_SUPPLY;
  uint256 public MAX_PREMIUM_WHITELIST_SUPPLY;

  PaymentSplitter private _splitter;

  constructor (
    string memory tokenName,
    string memory tokenSymbol,
    string memory customBaseURI_,
    address[] memory payees,
    uint256[] memory shares,
    uint256 standardPrice,
    uint256 premiumPrice
   ) ERC721(tokenName, tokenSymbol) EIP712Whitelisting() {
    customBaseURI = customBaseURI_;

    _splitter = new PaymentSplitter(payees, shares);

    STANDARD_PRICE = standardPrice;
    PREMIUM_PRICE = premiumPrice;
    MAX_PREMIUM_PER_WALLET = 1;
    MAX_STANDARD_PER_WALLET = 3;

    MAX_MULTIMINT = 3;

    MAX_STANDARD_SUPPLY = 6363;
    MAX_PREMIUM_SUPPLY = 2727;
    MAX_STANDARD_RESERVED_SUPPLY = 636;
    MAX_PREMIUM_RESERVED_SUPPLY = 272;
    MAX_SUPPLY = MAX_STANDARD_SUPPLY + MAX_PREMIUM_SUPPLY;

    MAX_STANDARD_WHITELIST_SUPPLY = 3181;
    MAX_PREMIUM_WHITELIST_SUPPLY = 1363;
  }

  /** ADMIN FUNCTIONS **/

  bool public saleIsActive = false;
  bool public whitelistSaleIsActive = true;

  function flipSaleState() external onlyOwner {
    saleIsActive = !saleIsActive;
  }

  function flipWhitelistSaleState() external onlyOwner {
    whitelistSaleIsActive = !whitelistSaleIsActive;
  }

  function setStandardPrice(uint256 price) external onlyOwner {
    STANDARD_PRICE = price;
  }

  function setPremiumPrice(uint256 price) external onlyOwner {
    PREMIUM_PRICE = price;
  }

  function setPremiumLimitPerWallet(uint256 maxPerWallet) external onlyOwner {
    MAX_PREMIUM_PER_WALLET = maxPerWallet;
  }

  function setStandardLimitPerWallet(uint256 maxPerWallet) external onlyOwner {
    MAX_STANDARD_PER_WALLET = maxPerWallet;
  }

  function setMultiMint(uint256 maxMultiMint) external onlyOwner {
    MAX_MULTIMINT = maxMultiMint;
  }

  function setMaxStandardWhitelistSupply(uint256 maxSupply) external onlyOwner {
    MAX_STANDARD_WHITELIST_SUPPLY = maxSupply;
  }

  function setMaxPremiumWhitelistSupply(uint256 maxSupply) external onlyOwner {
    MAX_PREMIUM_WHITELIST_SUPPLY = maxSupply;
  }

  /** MINTING LIMITS **/

  mapping(address => uint256) private standardMintCountMap;
  mapping(address => uint256) private premiumMintCountMap;
  //mapping(address => uint256) private standardAllowedMintCountMap;

  function allowedStandardMintCount(address minter) public view returns (uint256) {
    return MAX_STANDARD_PER_WALLET - standardMintCountMap[minter];
  }

  function updateStandardMintCount(address minter, uint256 count) private {
    standardMintCountMap[minter] += count;
  }

    function allowedPremiumMintCount(address minter) public view returns (uint256) {
    return MAX_PREMIUM_PER_WALLET - premiumMintCountMap[minter];
  }

  function updatePremiumMintCount(address minter, uint256 count) private {
    premiumMintCountMap[minter] += count;
  }

  /** COUNTERS */

  Counters.Counter private standardSupplyCounter;
  Counters.Counter private standardReservedSupplyCounter;
  Counters.Counter private premiumSupplyCounter;
  Counters.Counter private premiumReservedSupplyCounter;
  Counters.Counter private standardWhitelistMintCounter;
  Counters.Counter private premiumWhitelistMintCounter;

  function totalStandardSupply() public view returns (uint256) {
    return standardSupplyCounter.current();
  }

  function totalStandardReservedSupply() public view returns (uint256) {
    return standardReservedSupplyCounter.current();
  }

  function totalPremiumSupply() public view returns (uint256) {
    return premiumSupplyCounter.current();
  }

  function totalPremiumReservedSupply() public view returns (uint256) {
    return premiumReservedSupplyCounter.current();
  }

  function totalStandardWhitelistMints() public view returns (uint256) {
    return standardWhitelistMintCounter.current();
  }

    function totalPremiumWhitelistMints() public view returns (uint256) {
    return premiumWhitelistMintCounter.current();
  }

  /** MINTING **/

  function mintStandard(uint256 count) public payable nonReentrant {
    require(saleIsActive, "Sale not active");
    require(totalStandardSupply() + count - 1 < MAX_STANDARD_SUPPLY - MAX_STANDARD_RESERVED_SUPPLY, "Exceeds max supply");
    require(count - 1 < MAX_MULTIMINT, "Trying to mint too many at a time");
    require(msg.value >= STANDARD_PRICE * count, "Insufficient payment");

    if (allowedStandardMintCount(_msgSender()) > 0) {
      updateStandardMintCount(_msgSender(), count);
    } else {
      revert("Minting limit exceeded");
    }

    for (uint256 i = 0; i < count; i++) {
      standardSupplyCounter.increment();
      _safeMint(_msgSender(), MAX_STANDARD_RESERVED_SUPPLY + totalStandardSupply());
    }

    payable(_splitter).transfer(msg.value);
  }

  function mintPremium(uint256 count) public payable nonReentrant {
    require(saleIsActive, "Sale not active");
    require(totalPremiumSupply() + count - 1 < MAX_PREMIUM_SUPPLY - MAX_PREMIUM_RESERVED_SUPPLY, "Exceeds max supply");
    require(count - 1 < MAX_MULTIMINT, "Trying to mint too many at a time");
    require(msg.value >= PREMIUM_PRICE , "Insufficient payment");

    if (allowedPremiumMintCount(_msgSender()) > 0) {
      updatePremiumMintCount(_msgSender(), count);
    } else {
      revert("Minting limit exceeded");
    }

    for (uint256 i = 0; i < count; i++) {
      premiumSupplyCounter.increment();
      _safeMint(_msgSender(), MAX_STANDARD_SUPPLY + MAX_PREMIUM_RESERVED_SUPPLY + totalPremiumSupply());
    }

    payable(_splitter).transfer(msg.value);
  }

  function mintStandardReserved(uint256 count) external onlyOwner {
    require(totalStandardReservedSupply() + count - 1 < MAX_STANDARD_RESERVED_SUPPLY, "Exceeds max supply");

    for (uint256 i = 0; i < count; i++) {
      standardReservedSupplyCounter.increment();
      _safeMint(_msgSender(), totalStandardReservedSupply());
    }
  }

  function mintStandardReservedToAddress(uint256 count, address account) external onlyOwner {
    require(totalStandardReservedSupply() + count - 1 < MAX_STANDARD_RESERVED_SUPPLY, "Exceeds max supply");

    for (uint256 i = 0; i < count; i++) {
      standardReservedSupplyCounter.increment();
      _safeMint(account, totalStandardReservedSupply());
    }
  }

  function mintPremiumReserved(uint256 count) external onlyOwner{
    require(totalPremiumReservedSupply() + count - 1 < MAX_PREMIUM_RESERVED_SUPPLY, "Exceeds max supply");

    for (uint256 i = 0; i < count; i++) {
      premiumReservedSupplyCounter.increment();
      _safeMint(_msgSender(), MAX_STANDARD_SUPPLY + totalPremiumReservedSupply());
    }
  }

  function mintPremiumReservedToAddress(uint256 count, address account) external onlyOwner{
    require(totalPremiumReservedSupply() + count - 1 < MAX_PREMIUM_RESERVED_SUPPLY, "Exceeds max supply");

    for (uint256 i = 0; i < count; i++) {
      premiumReservedSupplyCounter.increment();
      _safeMint(account, MAX_STANDARD_SUPPLY + totalPremiumReservedSupply());
    }
  }

  function mintStandardWhitelist(uint256 count, bytes calldata signature) public payable requiresWhitelist(signature) nonReentrant {
    require(whitelistSaleIsActive, "Sale not active");
    require(totalStandardWhitelistMints() + count - 1 < MAX_STANDARD_WHITELIST_SUPPLY, "Exceeds whitelist supply");
    require(totalStandardSupply() < MAX_STANDARD_SUPPLY - MAX_STANDARD_RESERVED_SUPPLY + count - 1, "Exceeds max supply");
    require(count - 1 < MAX_MULTIMINT, "Trying to mint too many at a time");
    require(msg.value >= STANDARD_PRICE * count, "Insufficient payment");

    if (allowedStandardMintCount(_msgSender()) > 0) {
      updateStandardMintCount(_msgSender(), count);
    } else {
      revert("Minting limit exceeded");
    }

    for (uint256 i = 0; i < count; i++) {
      standardSupplyCounter.increment();
      standardWhitelistMintCounter.increment();
      _safeMint(_msgSender(), MAX_STANDARD_RESERVED_SUPPLY + totalStandardSupply());
    }

    payable(_splitter).transfer(msg.value);
  }

  function mintPremiumWhitelist(uint256 count, bytes calldata signature) public payable requiresWhitelist(signature) nonReentrant {
    require(whitelistSaleIsActive, "Sale not active");
    require(totalPremiumWhitelistMints() + count - 1 < MAX_PREMIUM_WHITELIST_SUPPLY, "Exceeds whitelist supply");
    require(totalPremiumSupply() < MAX_PREMIUM_SUPPLY - MAX_PREMIUM_RESERVED_SUPPLY + count - 1, "Exceeds max supply");
    require(count - 1 < MAX_MULTIMINT, "Trying to mint too many at a time");
    require(msg.value >= PREMIUM_PRICE * count, "Insufficient payment");

    if (allowedPremiumMintCount(_msgSender()) > 0) {
      updatePremiumMintCount(_msgSender(), count);
    } else {
      revert("Minting limit exceeded");
    }

    for (uint256 i = 0; i < count; i++) {
      premiumSupplyCounter.increment();
      premiumWhitelistMintCounter.increment();
      _safeMint(_msgSender(), MAX_STANDARD_SUPPLY + MAX_PREMIUM_RESERVED_SUPPLY + totalPremiumSupply());
    }

    payable(_splitter).transfer(msg.value);
  }

  /** WHITELIST **/

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