// SPDX-License-Identifier: UNLICENSED

// ███╗   ███╗ █████╗ ██████╗ ███████╗   ██╗    ██╗██╗████████╗██╗  ██╗   ███╗   ███╗ █████╗ ███████╗ ██████╗ ███╗   ██╗
// ████╗ ████║██╔══██╗██╔══██╗██╔════╝   ██║    ██║██║╚══██╔══╝██║  ██║   ████╗ ████║██╔══██╗██╔════╝██╔═══██╗████╗  ██║
// ██╔████╔██║███████║██║  ██║█████╗     ██║ █╗ ██║██║   ██║   ███████║   ██╔████╔██║███████║███████╗██║   ██║██╔██╗ ██║
// ██║╚██╔╝██║██╔══██║██║  ██║██╔══╝     ██║███╗██║██║   ██║   ██╔══██║   ██║╚██╔╝██║██╔══██║╚════██║██║   ██║██║╚██╗██║
// ██║ ╚═╝ ██║██║  ██║██████╔╝███████╗   ╚███╔███╔╝██║   ██║   ██║  ██║   ██║ ╚═╝ ██║██║  ██║███████║╚██████╔╝██║ ╚████║
// ╚═╝     ╚═╝╚═╝  ╚═╝╚═════╝ ╚══════╝    ╚══╝╚══╝ ╚═╝   ╚═╝   ╚═╝  ╚═╝   ╚═╝     ╚═╝╚═╝  ╚═╝╚══════╝ ╚═════╝ ╚═╝  ╚═══╝

pragma solidity ^0.8.14;

import "./mason/utils/AccessControl.sol";
import "./mason/utils/EIP712Common.sol";
import "./mason/utils/Toggleable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "erc721a/contracts/ERC721A.sol";
import 'erc721a/contracts/extensions/ERC721ABurnable.sol';

error ExceedsMaxPerWallet();
error ExceedsMaxSupply();

contract DAOHouseFriends is ERC721A, ERC721ABurnable, Ownable, AccessControl, Toggleable, EIP712Common{
  address public GENESIS_TOKEN;
  uint256 public MAX_PER_WALLET_MULTIPLIER;
  uint256 public MAX_PER_WALLET;
  uint256 public MAX_SUPPLY;

  PaymentSplitter private _splitter;

  constructor (
    string memory _tokenName,
    string memory _tokenSymbol,
    string memory _customBaseURI,
    uint256 _tokensForSale,
    address _genesisToken,
    address[] memory _payees,
    uint256[] memory _shares
  ) ERC721A(_tokenName, _tokenSymbol) {
    customBaseURI = _customBaseURI;

    MAX_SUPPLY = _tokensForSale;
    MAX_PER_WALLET = 3;
    MAX_PER_WALLET_MULTIPLIER = 10;
    GENESIS_TOKEN = _genesisToken;

     _splitter = new PaymentSplitter(_payees, _shares);
     _setRoyalties(address(_splitter), 10);
  }

  /** MINTING **/

  function mint(uint256 _count) external noContracts requireActiveSale {
    if(_totalMinted() + _count > MAX_SUPPLY) revert ExceedsMaxSupply();
    if(_numberMinted(msg.sender) + _count > _maxMints(msg.sender)) revert ExceedsMaxPerWallet();

    _mint(msg.sender, _count);
  }

  function ownerMint(uint256 _count, address _recipient) external onlyOwner() {
    if(_totalMinted() + _count > MAX_SUPPLY) revert ExceedsMaxSupply();

    _mint(_recipient, _count);
  }

  function whitelistMint(uint256 _count, bytes calldata _signature) external requiresWhitelist(_signature) requireActiveWhitelist noContracts {
    if(_totalMinted() + _count > MAX_SUPPLY) revert ExceedsMaxSupply();
    if(_numberMinted(msg.sender) + _count > _maxMints(msg.sender)) revert ExceedsMaxPerWallet();

    _mint(msg.sender, _count);
  }

  /** MINTING LIMITS **/

  function _maxMints(address minter) internal view returns (uint256) {
    IERC721A genesisToken = IERC721A(GENESIS_TOKEN);
    uint256 genesisBalance = genesisToken.balanceOf(minter);


    return genesisBalance > 0 ? genesisBalance * MAX_PER_WALLET_MULTIPLIER : MAX_PER_WALLET;
  }

  function allowedMintCount(address minter) public view returns (uint256) {
    return _maxMints(minter) - _numberMinted(minter);
  }

  function setMaxPerWallet(uint256 _max) external onlyOwner() {
    MAX_PER_WALLET = _max;
  }

  function setMaxPerWalletMultiplier(uint256 _multiplier) external onlyOwner() {
    MAX_PER_WALLET_MULTIPLIER = _multiplier;
  }

  function setGenesisToken(address _genesisToken) external onlyOwner() {
    GENESIS_TOKEN = _genesisToken;
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

  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }

  /** SECONDARY ROYALTIES **/
  address private royaltyAddress;
  uint256 private royaltyPercent;

  function _setRoyalties(address _receiver, uint256 _percentage) internal {
    royaltyAddress = _receiver;
    royaltyPercent = _percentage;
  }

  function royaltyInfo(
    uint256 _tokenId,
    uint256 _salePrice
  ) external view returns (
    address receiver,
    uint256 royaltyAmount
  ) {
    receiver = royaltyAddress;

    // This sets percentages by price * percentage / 100
    royaltyAmount = _salePrice * royaltyPercent / 100;
  }
}