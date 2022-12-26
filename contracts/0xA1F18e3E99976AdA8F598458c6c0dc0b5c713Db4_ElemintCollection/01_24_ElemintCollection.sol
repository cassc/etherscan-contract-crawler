//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

// import "hardhat/console.sol";

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/common/ERC2981Upgradeable.sol";
import "operator-filter-registry/src/upgradeable/DefaultOperatorFiltererUpgradeable.sol";

import "./ERC721ACMUpgradeable.sol";

contract ElemintCollection is
  Initializable,
  UUPSUpgradeable,
  OwnableUpgradeable,
  ERC721ACMUpgradeable,
  DefaultOperatorFiltererUpgradeable,
  ERC2981Upgradeable
{
  string public constant VERSION = "1.5.0";

  uint32 public constant MAX_MINT_NUMBER = 1000000; //max number nft mint in one batch, avoid overflow uint64 number

  /// @dev init implementation when deploy (avoid leak init security)
  constructor() {
    initialize("0", "0", msg.sender, 1, 0);
  }

  /**
   */
  function initialize(
    string memory name_,
    string memory symbol_,
    address marketWallet,
    uint16 baseUriBacktrackLength,
    uint256 baseTokenId_
  ) public virtual initializer {
    bytes memory initializeParams = abi.encode(name_, symbol_, marketWallet, baseUriBacktrackLength, baseTokenId_);
    setUp(initializeParams);
  }

  /// @dev Initialize function, will be triggered when a new proxy is deployed (factory friendly)
  /// @param initializeParams Parameters of initialization encoded
  function setUp(bytes memory initializeParams) public initializer {
    __Ownable_init();

    (
      string memory name_,
      string memory symbol_,
      address marketWallet,
      uint16 baseUriBacktrackLength,
      uint256 baseTokenId_
    ) = abi.decode(initializeParams, (string, string, address, uint16, uint256));

    __ERC721ACM_init(name_, symbol_, marketWallet, baseUriBacktrackLength, baseTokenId_);
    __DefaultOperatorFilterer_init();
  }

  function _authorizeUpgrade(address) internal override onlyOwner {}

  function setName(string memory name_) external {
    require(_msgSender() == _getDefaultOwner());
    _setName(name_);
  }

  function setSymbol(string memory symbol_) external {
    require(_msgSender() == _getDefaultOwner());
    _setSymbol(symbol_);
  }

  /**
   * @dev See {IERC165-supportsInterface}.
   */
  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(ERC721ACMUpgradeable, ERC2981Upgradeable)
    returns (bool)
  {
    return super.supportsInterface(interfaceId);
  }

  /**
    @dev setDefaultRoyalty
   */
  function setDefaultRoyalty(address receiver, uint96 feeNumerator) external {
    require(_msgSender() == _getDefaultOwner());
    _setDefaultRoyalty(receiver, feeNumerator);
  }

  /**
   *
   */
  function deleteDefaultRoyalty() external virtual {
    require(_msgSender() == _getDefaultOwner());
    _deleteDefaultRoyalty();
  }

  /**
   *
   */
  function setTokenRoyalty(
    uint256 tokenId,
    address receiver,
    uint96 feeNumerator
  ) external virtual {
    require(_msgSender() == _getDefaultOwner());
    _setTokenRoyalty(tokenId, receiver, feeNumerator);
  }

  /**
   *
   */
  function resetTokenRoyalty(uint256 tokenId) external virtual {
    require(_msgSender() == _getDefaultOwner());
    _resetTokenRoyalty(tokenId);
  }

  /**
   */

  function getDefaultOwner() external view returns (address) {
    return _getDefaultOwner();
  }

  function setDefaultOwner(address nextDefaultOwner) external {
    require(_msgSender() == _getDefaultOwner());
    _setDefaultOwner(nextDefaultOwner);
  }

  /**
   
   */
  function safeMint(
    address to,
    uint32 quantity,
    string memory uri
  ) public {
    require(_msgSender() == _getDefaultOwner());
    require(quantity < MAX_MINT_NUMBER);
    _safeMint(to, quantity, uri, false);
  }

  function safeMintWithTokenId(
    address to,
    uint32 quantity,
    string memory uri,
    uint32 startTokenId
  ) public {
    require(startTokenId == _currentIndex);
    require(_msgSender() == _getDefaultOwner());
    require(quantity < MAX_MINT_NUMBER);
    _safeMint(to, quantity, uri, false);
  }

  function mint(
    address to,
    uint32 quantity,
    string memory uri,
    bytes memory data,
    bool safe
  ) public {
    require(_msgSender() == _getDefaultOwner());
    require(quantity < MAX_MINT_NUMBER);
    _mint(to, quantity, uri, data, safe, false);
  }

  function safeMintNoConsecutiveTransfer(
    address to,
    uint32 quantity,
    string memory uri
  ) public {
    require(_msgSender() == _getDefaultOwner());
    require(quantity < MAX_MINT_NUMBER);
    _safeMint(to, quantity, uri, true);
  }

  function safeMintWithTokenIdNoConsecutiveTransfer(
    address to,
    uint32 quantity,
    string memory uri,
    uint32 startTokenId
  ) public {
    require(startTokenId == _currentIndex);
    require(_msgSender() == _getDefaultOwner());
    require(quantity < MAX_MINT_NUMBER);
    _safeMint(to, quantity, uri, true);
  }

  function mintNoConsecutiveTransfer(
    address to,
    uint32 quantity,
    string memory uri,
    bytes memory data,
    bool safe
  ) public {
    require(_msgSender() == _getDefaultOwner());
    require(quantity < MAX_MINT_NUMBER);
    _mint(to, quantity, uri, data, safe, true);
  }

  /**
   */
  function exists(uint256 tokenId) external view returns (bool) {
    return _exists(tokenId);
  }

  /**
   * Override isApprovedForAll to whitelisted defaultowner .
   *
   */
  function isApprovedForAll(address owner_, address operator) public view override returns (bool) {
    // check if this is an approved marketplace
    if (operator == _getDefaultOwner()) {
      return true;
    }
    // otherwise, use the default ERC721 isApprovedForAll()
    return super.isApprovedForAll(owner_, operator);
  }

  /**
   * For BaseUriBacktrackLength
   */
  function getBaseUriBacktrackLength() external view returns (uint16) {
    return _getBaseUriBacktrackLength();
  }

  function setBaseUriBacktrackLength(uint16 baseUriBacktrackLength) external {
    require(_msgSender() == _getDefaultOwner());
    _setBaseUriBacktrackLength(baseUriBacktrackLength);
  }

  /**
   * tokensURIMap
   */

  function getTokensURIMap(uint64 tokenId) external view returns (string memory, uint64) {
    return _getTokensURIMap(tokenId);
  }

  function setTokensURIMap(
    uint64 tokenId,
    string memory uri,
    uint64 startIndex
  ) external {
    require(_msgSender() == _getDefaultOwner());
    _setTokensURIMap(tokenId, uri, startIndex);
  }

  /**
   * for operator filter registry
   */

  function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
    super.setApprovalForAll(operator, approved);
  }

  function approve(address operator, uint256 tokenId) public override onlyAllowedOperatorApproval(operator) {
    super.approve(operator, tokenId);
  }

  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public override onlyAllowedOperator(from) {
    super.transferFrom(from, to, tokenId);
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public override onlyAllowedOperator(from) {
    super.safeTransferFrom(from, to, tokenId);
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes memory data
  ) public override onlyAllowedOperator(from) {
    super.safeTransferFrom(from, to, tokenId, data);
  }
}