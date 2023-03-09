//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

import {console} from "hardhat/console.sol";
import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {CountersUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";

import {ERC721Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import {ERC721URIStorageUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";

import {DeHubUpgradeable} from "./abstracts/DeHubUpgradeable.sol";
import {ICheckout} from "./interfaces/ICheckout.sol";
import {IReceipt} from "./interfaces/IReceipt.sol";

contract ReceiptV2 is
  DeHubUpgradeable,
  AccessControlUpgradeable,
  ERC721Upgradeable,
  ERC721URIStorageUpgradeable,
  IReceipt
{
  using CountersUpgradeable for CountersUpgradeable.Counter;

  bytes32 public constant SET_STATUS_ROLE = keccak256("SET_STATUS_ROLE");

  CountersUpgradeable.Counter private _receiptIds;

  bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
  bytes32 public constant TRANSFER_ROLE = keccak256("TRANSFER_ROLE");
  bytes32 public constant AIRDROP_ROLE = keccak256("AIRDROP_ROLE");

  // address to checkout contract
  address public checkout;
  // <receipt id, ReceiptWithStatus>
  mapping(uint256 => ReceiptWithStatus) private _receipts;

  /* -------------------------------------------------------------------------- */
  /*                                  Modifiers                                 */
  /* -------------------------------------------------------------------------- */

  modifier onlyCheckout() {
    require(msg.sender == checkout, "Not a checkout contract");
    _;
  }

  modifier onlyChecker() {
    require(hasRole(SET_STATUS_ROLE, msg.sender), "Invalid permission");
    _;
  }

  modifier onlyAirdrop() {
    require(hasRole(AIRDROP_ROLE, msg.sender), "Invalid permission");
    _;
  }

  /* -------------------------------------------------------------------------- */
  /*                                 Initializer                                */
  /* -------------------------------------------------------------------------- */

  function __Receipt_init(address _parent) external initializer {
    DeHubUpgradeable.initialize();
    __ERC721_init("Receipt", "Receipt");
    __ERC721URIStorage_init();
    __AccessControl_init();
    _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _grantRole(SET_STATUS_ROLE, msg.sender);

    checkout = _parent;
  }

  /* -------------------------------------------------------------------------- */
  /*                             External Functions                             */
  /* -------------------------------------------------------------------------- */

  function setCheckout(address _checkout) external override onlyOwner {
    checkout = _checkout;
  }

  /**
   * @notice Grant the role to target wallet who can set receipt status,
   *         Callable by owner
   * @param _target Target wallet address
   */
  function setCheckerRole(address _target) external override onlyOwner {
    _grantRole(SET_STATUS_ROLE, _target);
  }

  function mint(
    address _to,
    uint256 _currency,
    uint256 _price,
    uint256 _quantity,
    uint256 _totalAmount,
    bytes32 _orderId,
    string calldata _metadataURI
  ) external onlyCheckout returns (uint256) {
    return
      _mintFor(
        _to,
        _currency,
        _price,
        _quantity,
        _totalAmount,
        _orderId,
        _metadataURI
      );
  }

  function airdrop(
    address _to,
    uint256 _quantity,
    string calldata _metadataURI
  ) external onlyAirdrop returns (uint256) {
    _receiptIds.increment();
    uint256 receiptId = _receiptIds.current();
    _safeMint(_to, receiptId);
    _setTokenURI(receiptId, _metadataURI);
    _receipts[receiptId] = ReceiptWithStatus({
      currency: uint256(ICheckout.Currency.DeHub),
      price: 0,
      quantity: _quantity,
      totalAmount: 0,
      orderId: 0,
      status: uint256(IReceipt.Status.Confirmed),
      reason: ""
    });

    return receiptId;
  }

  function airdropBulk(
    address[] calldata _to,
    uint256[] calldata _quantity,
    string[] calldata _metadataURI
  ) external onlyAirdrop {
    require(_to.length == _quantity.length && _quantity.length == _metadataURI.length, "Invalid parameter");

    uint256 length = _to.length;
    for (uint256 i = 0; i < length; ++i) {
      _receiptIds.increment();
      uint256 receiptId = _receiptIds.current();
      _safeMint(_to[i], receiptId);
      _setTokenURI(receiptId, _metadataURI[i]);
      _receipts[receiptId] = ReceiptWithStatus({
        currency: uint256(ICheckout.Currency.DeHub),
        price: 0,
        quantity: _quantity[i],
        totalAmount: 0,
        orderId: 0,
        status: uint256(IReceipt.Status.Confirmed),
        reason: ""
      });
    }
  }

  function setStatus(
    uint256 _receiptId,
    IReceipt.Status _status,
    string calldata _reason
  ) external onlyChecker {
    require(_receiptId <= _receiptIds.current(), "Invalid receipt Id");
    require(
      _isValidStatus(IReceipt.Status(_receipts[_receiptId].status), _status),
      "Invalid status"
    );

    _receipts[_receiptId].status = uint256(_status);
    _receipts[_receiptId].reason = _reason;

    emit ReceiptStatus(
      _receiptId,
      msg.sender,
      msg.sender,
      uint256(_status),
      _reason
    );
  }

  function tokenURI(uint256 _receiptId)
    public
    view
    override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
    returns (string memory)
  {
    return ERC721URIStorageUpgradeable.tokenURI(_receiptId);
  }

  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(ERC721Upgradeable, AccessControlUpgradeable)
    returns (bool)
  {
    return
      ERC721Upgradeable.supportsInterface(interfaceId) ||
      AccessControlUpgradeable.supportsInterface(interfaceId);
  }

  /* -------------------------------------------------------------------------- */
  /*                             Internal Functions                             */
  /* -------------------------------------------------------------------------- */

  function _mintFor(
    address _to,
    uint256 _currency,
    uint256 _price,
    uint256 _quantity,
    uint256 _totalAmount,
    bytes32 _orderId,
    string memory _metadataURI
  ) internal virtual returns (uint256) {
    _receiptIds.increment();
    uint256 receiptId = _receiptIds.current();
    _safeMint(_to, receiptId);
    _setTokenURI(receiptId, _metadataURI);
    _receipts[receiptId] = ReceiptWithStatus({
      currency: _currency,
      price: _price,
      quantity: _quantity,
      totalAmount: _totalAmount,
      orderId: _orderId,
      status: uint256(IReceipt.Status.Pending),
      reason: ""
    });

    return receiptId;
  }

  function _isValidStatus(IReceipt.Status _prev, IReceipt.Status _next)
    internal
    virtual
    returns (bool)
  {
    if (
      _prev == IReceipt.Status.Pending &&
      (_next == IReceipt.Status.InTransit || _next == IReceipt.Status.Archived)
    ) {
      return true;
    }
    if (
      _prev == IReceipt.Status.InTransit && _next == IReceipt.Status.Delivered
    ) {
      return true;
    }
    if (
      _prev == IReceipt.Status.Delivered && _next == IReceipt.Status.Confirmed
    ) {
      return true;
    }
    return false;
  }

  // The following functions are overrides required by Solidity.

  function _burn(uint256 _receiptId)
    internal
    override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
  {
    super._burn(_receiptId);
  }

  /* -------------------------------------------------------------------------- */
  /*                               View Functions                               */
  /* -------------------------------------------------------------------------- */

  function lastReceiptId() external view override returns (uint256) {
    return _receiptIds.current();
  }

  function price(uint256 _receiptId) external view override returns (uint256) {
    return _receipts[_receiptId].price;
  }

  function quantity(uint256 _receiptId)
    external
    view
    override
    returns (uint256)
  {
    return _receipts[_receiptId].quantity;
  }

  function totalAmount(uint256 _receiptId)
    external
    view
    override
    returns (uint256)
  {
    return _receipts[_receiptId].totalAmount;
  }

  function status(uint256 _receiptId)
    external
    view
    override
    returns (uint256, string memory)
  {
    return (_receipts[_receiptId].status, _receipts[_receiptId].reason);
  }

  function receipt(uint256 _receiptId)
    external
    view
    override
    returns (ReceiptWithStatus memory)
  {
    return _receipts[_receiptId];
  }
}