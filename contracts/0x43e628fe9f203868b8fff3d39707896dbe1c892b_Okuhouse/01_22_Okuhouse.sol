//SPDX-License-Identifier: Unlicense
// Creator: Pixel8 Labs
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/access/AccessControl.sol';
import '@openzeppelin/contracts/token/common/ERC2981.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/finance/PaymentSplitter.sol';
import '@openzeppelin/contracts/utils/math/Math.sol';
import 'erc721a/contracts/ERC721A.sol';
import '@sigpub/signatures-verify/Signature.sol';
import 'closedsea/src/OperatorFilterer.sol';

error InvalidSignature();
error InvalidAmount(uint amount, uint max);
error InvalidOffer(uint256 price, uint256 offer);
error ExceededMaxSupply();
error ExceededMintQuota(uint amount, uint quota);
error InvalidSource();
error MintNotOpened();
error InvalidSigner(address signer);

contract Okuhouse is
  ERC721A,
  ERC2981,
  PaymentSplitter,
  Ownable,
  AccessControl,
  ReentrancyGuard,
  OperatorFilterer
{
  uint public MAX_SUPPLY;
  string public baseURI;
  bool public operatorFilteringEnabled = true;

  // Phases
  enum Phases {
    CLOSED,
    PUBLIC,
    WHITELIST
  }
  mapping(Phases => address) public signer;
  mapping(Phases => bool) public phase;

  // Pricing
  mapping(Phases => uint256) public price;
  // canMint modifier should contain the most common usecase between mint functions
  // (e.g. public mint, private mint, free mint, airdrop)
  modifier canMint(uint amount, Phases p) {
    uint256 supply = totalSupply();
    if (msg.value != price[p] * amount)
      revert InvalidOffer(price[p] * amount, msg.value);
    if (supply + amount > MAX_SUPPLY) revert ExceededMaxSupply();
    if (msg.sender != tx.origin) revert InvalidSource();
    if (phase[Phases.CLOSED] == true) revert MintNotOpened();
    _;
  }

  constructor(
    string memory name,
    string memory symbol,
    string memory uri,
    address royaltyReceiver,
    address[] memory payees,
    uint256[] memory shares,
    uint maxSupply,
    uint256 publicPrice,
    uint256 whitelistPrice
  ) ERC721A(name, symbol) PaymentSplitter(payees, shares) Ownable() {
    baseURI = uri;
    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _registerForOperatorFiltering();
    _setDefaultRoyalty(royaltyReceiver, 200); // 1000 = 10% | 200 = 2%
    _transferOwnership(royaltyReceiver); // owner addr = receiver addr
    price[Phases.PUBLIC] = publicPrice;
    price[Phases.WHITELIST] = whitelistPrice;
    phase[Phases.CLOSED] = true;
    MAX_SUPPLY = maxSupply;
  }

  // Metadata
  function _startTokenId() internal pure override returns (uint256) {
    return 1;
  }

  function tokenURI(
    uint256 tokenId
  ) public view virtual override returns (string memory) {
    if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
    if (bytes(baseURI).length == 0) return '';

    return string(abi.encodePacked(baseURI, '/', _toString(tokenId), '.json'));
  }

  function mint(
    uint amount
  ) external payable canMint(amount, Phases.PUBLIC) nonReentrant {
    if (!phase[Phases.PUBLIC]) revert MintNotOpened();

    _safeMint(msg.sender, amount);
  }

  function whitelistMint(
    uint64 amount,
    uint64 maxAmount,
    bytes memory signature
  ) external payable canMint(amount, Phases.WHITELIST) nonReentrant {
    if (!phase[Phases.WHITELIST]) revert MintNotOpened();

    uint64 aux = _getAux(msg.sender);
    if (
      Signature.verify(maxAmount, msg.sender, signature) !=
      signer[Phases.WHITELIST]
    ) revert InvalidSignature();
    if (aux + amount > maxAmount)
      revert ExceededMintQuota(aux + amount, maxAmount);

    _setAux(msg.sender, aux + amount);
    _safeMint(msg.sender, amount);
  }

  function airdrop(
    address wallet,
    uint256 amount
  ) external onlyRole(DEFAULT_ADMIN_ROLE) {
    uint256 supply = totalSupply();
    if (supply + amount > MAX_SUPPLY) revert ExceededMaxSupply();
    _safeMint(wallet, amount);
  }

  function claimed(address target) external view returns (uint256) {
    return _getAux(target);
  }

  // Minting fee
  function setPrice(
    Phases _p,
    uint amount
  ) external onlyRole(DEFAULT_ADMIN_ROLE) {
    price[_p] = amount;
  }

  function claim() external {
    release(payable(msg.sender));
  }

  function setTokenURI(
    string calldata uri
  ) external onlyRole(DEFAULT_ADMIN_ROLE) {
    baseURI = uri;
  }

  function setSigner(
    Phases _p,
    address value
  ) external onlyRole(DEFAULT_ADMIN_ROLE) {
    signer[_p] = value;
  }

  // Minting count
  function setMaxSupply(uint amount) external onlyRole(DEFAULT_ADMIN_ROLE) {
    MAX_SUPPLY = amount;
  }

  // Phases
  function setPhase(
    Phases _phase,
    bool _status
  ) external onlyRole(DEFAULT_ADMIN_ROLE) {
    if (_phase != Phases.CLOSED) phase[Phases.CLOSED] = false;
    phase[_phase] = _status;
  }

  // Set default royalty to be used for all token sale
  function setDefaultRoyalty(
    address _royaltyReceiver,
    uint96 _fraction
  ) public onlyRole(DEFAULT_ADMIN_ROLE) {
    _setDefaultRoyalty(_royaltyReceiver, _fraction);
  }

  function setTokenRoyalty(
    uint256 _tokenId,
    address _royaltyReceiver,
    uint96 _fraction
  ) public onlyRole(DEFAULT_ADMIN_ROLE) {
    _setTokenRoyalty(_tokenId, _royaltyReceiver, _fraction);
  }

  function supportsInterface(
    bytes4 interfaceId
  )
    public
    view
    virtual
    override(ERC721A, ERC2981, AccessControl)
    returns (bool)
  {
    return
      ERC721A.supportsInterface(interfaceId) ||
      ERC2981.supportsInterface(interfaceId) ||
      AccessControl.supportsInterface(interfaceId);
  }

  // Operator Filter Registry
  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public payable override onlyAllowedOperator(from) {
    super.transferFrom(from, to, tokenId);
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public payable override onlyAllowedOperator(from) {
    super.safeTransferFrom(from, to, tokenId);
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes memory data
  ) public payable override onlyAllowedOperator(from) {
    super.safeTransferFrom(from, to, tokenId, data);
  }

  function _operatorFilteringEnabled() internal view override returns (bool) {
    return operatorFilteringEnabled;
  }

  function setOperatorFilteringEnabled(bool value) public onlyOwner {
    operatorFilteringEnabled = value;
  }

  function _isPriorityOperator(
    address operator
  ) internal pure override returns (bool) {
    return operator == address(0x1E0049783F008A0085193E00003D00cd54003c71);
  }
}