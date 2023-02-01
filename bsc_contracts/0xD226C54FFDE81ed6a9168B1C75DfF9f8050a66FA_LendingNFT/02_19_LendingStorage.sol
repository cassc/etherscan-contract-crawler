// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract LendingStorage is AccessControl, ReentrancyGuard, Pausable {
  using ECDSA for bytes32;
  using Address for address;
  using Counters for Counters.Counter;

  enum OrderStatus {
    default_zero,
    WaitPayment,
    Paid,
    IsClaimPrice,
    Expired,
    Cancel,
    IsClaimNFT
  }

  struct OrderERC4907 {
    uint256 id;
    address lender;
    address borrower;
    uint8 status;
    uint64 rentalDuration;
    uint256 dailyRentalPrice;
    uint256 startTime;
    uint256 expiredTime;
    uint32 commissionPercent;
    uint32 percentDecimals;
  }

  struct StorageInfor {
    uint256 countNFTContract;
    uint32 maxWaitingTime;
    uint32 percentDecimals;
    address adminVerify;
    address commissionWallet;
    address currencyToken;
  }

  bytes32 private constant OPERATOR = keccak256("OPERATOR");
  bytes32 private constant MARKET = keccak256("MARKET");
  address private _transactionWallet;
  address private _commissionWallet;
  address private _verifier;
  address private _currencyToken;
  uint32 private _commissionPercent;

  mapping(uint256 => Counters.Counter) private _orderIds;
  mapping(uint256 => mapping(uint256 => OrderERC4907)) private orders;
  mapping(string => bool) private _orderUUids;
  address[] private _contractAddresses;
  uint32 private _percentDecimals;
  uint32 private _maxWaitingTime;

  constructor() {
    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
  }

  modifier onlyAdmin() {
    require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Restricted to admin.");
    _;
  }

  modifier onlyOperator() {
    require(hasRole(OPERATOR, msg.sender), "Restricted to OPERATOR.");
    _;
  }

  function setPause(bool _isPause) external onlyOperator {
    require(paused() != _isPause, "PAUSEABLE_IS_NOT_CHANGE");
    if (_isPause) {
      _pause();
    } else {
      _unpause();
    }
  }

  modifier onlyMarket() {
    require(hasRole(MARKET, msg.sender), "Restricted to market.");
    _;
  }

  function setOperator(address _operator) external onlyAdmin {
    _setupRole(OPERATOR, _operator);
  }

  function setMarket(address _market) external onlyOperator {
    _setupRole(MARKET, _market);
  }

  function setMaxWaitingTime(uint32 _minutes) external onlyOperator {
    require(_minutes > 0 && _minutes <= 60, "VALUE_INVALID");
    _maxWaitingTime = _minutes * 60;
  }

  function setPercentDecimals(uint32 _decimals) external onlyOperator {
    require(_decimals > 0 && _decimals <= 10000, "VALUE_INVALID");
    _percentDecimals = _decimals * 100; // decimal * 100%
  }

  function setCommissionWallet(address _address) external onlyOperator {
    require(_address != address(0), "ADDRESS_CAN_NOT_IS_ZERO");
    _commissionWallet = _address;
  }

  function setCurrencyToken(address _token) external onlyOperator {
    require(_token != address(0), "ADDRESS_CAN_NOT_IS_ZERO");
    _currencyToken = _token;
  }

  function setCommissionVal(uint32 _value) external onlyMarket {
    _commissionPercent = _value;
  }

  function getCommistionVal() external onlyMarket view returns(uint32) {
    return _commissionPercent;
  }

  function setAddressVerify(address _address) external onlyOperator {
    require(_address != address(0), "ADDRESS_CAN_NOT_IS_ZERO");
    _verifier = _address;
  }

  function addNFTContractAddress(address[] memory _nftContractAddresses) external onlyOperator {
    for(uint256 i = 0; i < _nftContractAddresses.length; i++) {
      _contractAddresses.push(_nftContractAddresses[i]);
    }
  }

  function reloadNFTContractAddress(address[] memory _nftContractAddresses) external onlyOperator {
    require(_nftContractAddresses.length > 0, "INVALD_WALLET");
    require(_contractAddresses.length >= _nftContractAddresses.length, "INVALID_PARAMS");
    for(uint256 i = 0; i < _nftContractAddresses.length; i++) {
      _contractAddresses[i] = _nftContractAddresses[i];
    }
  }

  function createItemOrder(
    uint256 _nftId,
    uint8 _nftType,
    uint256 _dailyRentalPrice,
    uint64 _rentalDuration,
    address _lender,
    address _borrower
  ) external onlyMarket nonReentrant whenNotPaused returns (uint256) {
    OrderERC4907 memory existedOrder = orders[_nftId][_nftType];
    require(existedOrder.id == 0, "Sell order is already existed");
    _orderIds[_nftType].increment();
    uint256 orderId = _orderIds[_nftType].current();
    orders[_nftId][_nftType] = OrderERC4907({
      id: orderId,
      lender: _lender,
      borrower: _borrower,
      status: uint8(OrderStatus.WaitPayment),
      rentalDuration: _rentalDuration,
      dailyRentalPrice: _dailyRentalPrice,
      startTime: 0,
      expiredTime: 0,
      commissionPercent: _commissionPercent,
      percentDecimals: _percentDecimals
    });
    return orderId;
  }

  function getOrder(uint256 _nftId, uint256 _nftType) external onlyMarket view returns (OrderERC4907 memory) {
    return orders[_nftId][_nftType];
  }

  function updateOrderItem(
    uint256 _nftId,
    uint8 _nftType,
    uint8 _newStatus,
    uint256 _expiredTime
  ) external onlyMarket {
    if (_newStatus != uint8(OrderStatus.default_zero)) {
      orders[_nftId][_nftType].status = _newStatus;
    }
    if (_expiredTime != 0) {
      orders[_nftId][_nftType].startTime = block.timestamp;
      orders[_nftId][_nftType].expiredTime = _expiredTime;
    }
  }

  function deleteSellOrder(
    uint256 _nftId,
    uint8 _nftType
  ) external onlyMarket {
    orders[_nftId][_nftType].id = 0;
    delete orders[_nftId][_nftType];
  }

  function getNFTContractAddress(uint256 _nftType) external onlyMarket view returns(address) {
    return _contractAddresses[_nftType];
  }

  function isExecutedOrder(string memory _orderUUid) external onlyMarket view returns(bool) {
    return _orderUUids[_orderUUid];
  }

  function setExecutedOrder(string memory _orderUUid, bool _status) external onlyMarket {
    _orderUUids[_orderUUid] = _status;
  }

  function getInfor() onlyMarket external view returns (StorageInfor memory) {
    StorageInfor memory info = StorageInfor({
      countNFTContract: _contractAddresses.length,
      maxWaitingTime: _maxWaitingTime,
      percentDecimals: _percentDecimals,
      adminVerify: _verifier,
      commissionWallet: _commissionWallet,
      currencyToken: _currencyToken
    });
    return info;
  }
}