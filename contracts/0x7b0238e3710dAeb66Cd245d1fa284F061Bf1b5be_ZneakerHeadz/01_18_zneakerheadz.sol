// SPDX-License-Identifier: UNLICENSED

// ███╗   ███╗ █████╗ ██████╗ ███████╗   ██╗    ██╗██╗████████╗██╗  ██╗   ███╗   ███╗ █████╗ ███████╗ ██████╗ ███╗   ██╗
// ████╗ ████║██╔══██╗██╔══██╗██╔════╝   ██║    ██║██║╚══██╔══╝██║  ██║   ████╗ ████║██╔══██╗██╔════╝██╔═══██╗████╗  ██║
// ██╔████╔██║███████║██║  ██║█████╗     ██║ █╗ ██║██║   ██║   ███████║   ██╔████╔██║███████║███████╗██║   ██║██╔██╗ ██║
// ██║╚██╔╝██║██╔══██║██║  ██║██╔══╝     ██║███╗██║██║   ██║   ██╔══██║   ██║╚██╔╝██║██╔══██║╚════██║██║   ██║██║╚██╗██║
// ██║ ╚═╝ ██║██║  ██║██████╔╝███████╗   ╚███╔███╔╝██║   ██║   ██║  ██║   ██║ ╚═╝ ██║██║  ██║███████║╚██████╔╝██║ ╚████║
// ╚═╝     ╚═╝╚═╝  ╚═╝╚═════╝ ╚══════╝    ╚══╝╚══╝ ╚═╝   ╚═╝   ╚═╝  ╚═╝   ╚═╝     ╚═╝╚═╝  ╚═╝╚══════╝ ╚═════╝ ╚═╝  ╚═══╝

pragma solidity ^0.8.14;

import 'erc721a/contracts/extensions/ERC721ABurnable.sol';
import 'erc721a/contracts/extensions/ERC721AQueryable.sol';
import "./mason/utils/AccessControl.sol";
import "./mason/utils/EIP712Common.sol";
import "./mason/utils/Toggleable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "erc721a/contracts/ERC721A.sol";

error ExceedsMaxPerWallet();
error ExceedsMaxSupply();
error InsufficientPayment();

contract ZneakerHeadz is ERC721A, ERC721AQueryable, Ownable, AccessControl, Toggleable, EIP712Common{

  uint256 public MAX_PER_WALLET;
  uint256 public MAX_SUPPLY;
  uint256 public PRICE;
  uint256 public WHITELIST_PRICE;

  PaymentSplitter private _splitter;

  address private royaltyAddress;
  uint256 private royaltyPercent;

  constructor (
    string memory _tokenName,
    string memory _tokenSymbol,
    string memory _customBaseURI,
    address[] memory payees,
    uint256[] memory shares,
    uint256 _tokenPrice,
    uint256 _tokensForSale,
    address _royaltyAddress,
    uint256 _royaltyPercent
  ) ERC721A(_tokenName, _tokenSymbol) {
    customBaseURI = _customBaseURI;

    MAX_SUPPLY = _tokensForSale;
    PRICE = _tokenPrice;
    WHITELIST_PRICE = _tokenPrice;
    MAX_PER_WALLET = 5;

    royaltyAddress = _royaltyAddress;
    royaltyPercent = _royaltyPercent;

    _splitter = new PaymentSplitter(payees, shares);
    _setRoyalties(_royaltyAddress, _royaltyPercent);
  }

  /** MINTING **/

  function mint(uint256 _count) external payable noContracts requireActiveSale {
    if(_totalMinted() + _count > MAX_SUPPLY) revert ExceedsMaxSupply();
    if(msg.value < PRICE * _count) revert InsufficientPayment();

    if(_numberMinted(msg.sender) + _count > MAX_PER_WALLET) revert ExceedsMaxPerWallet();

    _mint(msg.sender, _count);

    payable(_splitter).transfer(msg.value);
  }

  function ownerMint(uint256 _count, address _recipient) external onlyOwner {
    if(_totalMinted() + _count > MAX_SUPPLY) revert ExceedsMaxSupply();

    _mint(_recipient, _count);
  }

  function whitelistMint(uint256 _count, uint256 _discount, bytes calldata _signature) external payable requiresDiscount(_signature, _discount) requireActiveWhitelist noContracts {
    if(_totalMinted() + _count > MAX_SUPPLY) revert ExceedsMaxSupply();

    uint256 numberMinted = _numberMinted(msg.sender);

    if(numberMinted + _count > MAX_PER_WALLET + _discount) revert ExceedsMaxPerWallet();
    if(msg.value < _discountedPrice(numberMinted, _count, _discount)) revert InsufficientPayment();

    _mint(msg.sender, _count);

    payable(_splitter).transfer(msg.value);
  }

  /** MINTING LIMITS **/
  function _discountedPrice(uint256 _numberMinted, uint256 _count, uint256 _discount) internal view returns (uint256) {
    if(_numberMinted + _count <= _discount) {
      return 0;
    } else {
      return (subtract(_count, _allowedFreeMints(msg.sender, _discount))) * WHITELIST_PRICE;
    }
  }

  function subtract(uint a, uint b) public pure returns(uint remainder) {
    if(b > a) return 0;
    return a - b;
  }


  function allowedMintCount(address _minter) public view returns (uint256) {
    return MAX_PER_WALLET - _numberMinted(_minter);
  }

  function allowedWhitelistMintCount(address _minter, uint256 _discount, bytes calldata _signature) public view requiresDiscount(_signature, _discount) returns (uint256) {
    return MAX_PER_WALLET + _discount - _numberMinted(_minter);
  }

  function allowedFreeMints(address _minter, uint256 _discount, bytes calldata _signature) public view requiresDiscount(_signature, _discount) returns (uint256) {
    return _allowedFreeMints(_minter, _discount);
  }

  function _allowedFreeMints(address _minter, uint256 _discount) internal view returns (uint256) {
    return subtract(_discount, _numberMinted(_minter));
  }

  /** WHITELIST **/

  function checkWhitelist(uint256 _discount, bytes calldata _signature) public view requiresDiscount(_signature, _discount) returns (bool) {
    return true;
  }

   /** ADMIN **/
  function setMaxPerWallet(uint256 _max) external onlyOwner() {
    MAX_PER_WALLET = _max;
  }

  function setPrice(uint256 _tokenPrice) external onlyOwner {
    PRICE = _tokenPrice;
  }

  function setWhitelistPrice(uint256 _tokenPrice) external onlyOwner {
    WHITELIST_PRICE = _tokenPrice;
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

  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }

  /** PAYOUT **/
  function release(address payable account) public virtual onlyOwner {
    _splitter.release(account);
  }

  function _setRoyalties(address _receiver, uint256 _percentage) internal {
    royaltyAddress = _receiver;
    royaltyPercent = _percentage;
  }

  function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view returns (
    address receiver,
    uint256 royaltyAmount
  ) {
    receiver = royaltyAddress;

    // This sets percentages by price * percentage / 100
    royaltyAmount = _salePrice * royaltyPercent / 100;
  }
}