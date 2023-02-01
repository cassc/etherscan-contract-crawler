// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./interfaces/ILendingNFT.sol";
import "./interfaces/IERC4907.sol";
import "./common/TransferHelper.sol";
import "./LendingStorage.sol";

contract LendingNFT is AccessControl, ILendingNFT, ReentrancyGuard, Pausable, ERC721Holder
{
  using ECDSA for bytes32;
  using Address for address;

  bytes32 private constant OPERATOR = keccak256("OPERATOR");

  uint32 public constant timeADay = 1 days;
  LendingStorage private _storageAddress;

  event ORDERCREATE(address lender, address borrower, uint8 status, uint256 orderId, uint8 nftType, uint256 nftId, uint64 rentalDuration, uint256 dailyRentalPrice, uint256 timeStamp);
  event ORDERCANCEL(address canceler, uint8 status, uint256 orderId, uint8 nftType, uint256 nftId, uint256 timeStamp);
  event LENDINGPAYMENT(address borrower, uint8 status, uint256 orderId, uint8 nftType, uint256 nftId, uint256 receivedPrice, uint256 commissionPrice, uint256 expiredTime, uint256 timeStamp);
  event CLAIMPRICE(address lender, uint8 status, uint256 orderId, uint8 nftType, uint256 nftId, uint256 receivedPrice, uint256 timeStamp);
  event CLAIMNFT(address lender, uint8 status, uint256 orderId, uint8 nftType, uint256 nftId, uint256 timeStamp);

  constructor(address _storage) {
    _storageAddress = LendingStorage(_storage);
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

  function setOperator(address _operator) external onlyAdmin {
    _setupRole(OPERATOR, _operator);
  }

  function setCommissionPercent(uint32 _value) external onlyAdmin {
    LendingStorage.StorageInfor memory info = _storageAddress.getInfor();
    require(_value > 0 && _value < info.percentDecimals, "VALUE_INVALID");
    _storageAddress.setCommissionVal(_value);
  }

  function getCommissionPercent() external view returns(uint32) {
    return _storageAddress.getCommistionVal();
  }

  function setPause(bool _isPause) external onlyOperator {
    require(paused() != _isPause, "PAUSEABLE_IS_NOT_CHANGE");
    if (_isPause) {
      _pause();
    } else {
      _unpause();
    }
  }

  function orderNFT(
    address _borrower,
    uint8 _nftType,
    uint256 _nftId,
    uint64 _rentalDuration,
    uint256 _dailyRentalPrice
  ) external override
    nonReentrant whenNotPaused {
    LendingStorage.StorageInfor memory info = _storageAddress.getInfor();
    require(_borrower != address(0), "ADDRESS_INVALID");
    require(_nftType >= 0 && _nftType < info.countNFTContract, "NFT_TYPE_INVALID");
    require(_rentalDuration > 0, "RENTAL_DURATION_INVALID");
    require(_dailyRentalPrice > 0, "DAILY_RENTAL_PRICE_INVALID");
    require(_nftId > 0, "NFTID_INVALID");
    IERC721 nft = IERC721(_storageAddress.getNFTContractAddress(_nftType));
    require(nft.ownerOf(_nftId) == msg.sender, "YOU_MUST_OWNER_OF_TOKEN");
    address lender = _msgSender();
    uint256 orderId = _storageAddress.createItemOrder(_nftId, _nftType, _dailyRentalPrice, _rentalDuration, lender, _borrower);
    nft.safeTransferFrom(lender, address(this), _nftId, "");
    emit ORDERCREATE(lender, _borrower, uint8(LendingStorage.OrderStatus.WaitPayment), orderId, _nftType, _nftId, _rentalDuration, _dailyRentalPrice, block.timestamp);
  }

  function cancelOrderItem(
    uint256 _nftId,
    uint8 _nftType
  ) external override
    nonReentrant whenNotPaused {
    LendingStorage.StorageInfor memory info = _storageAddress.getInfor();
    require(_nftId > 0, "NFT_INVALID");
    require(_nftType >= 0 && _nftType < info.countNFTContract, "NFT_TYPE_INVALID");
    LendingStorage.OrderERC4907 memory orderItem = _storageAddress.getOrder(_nftId, _nftType);
    require(msg.sender == orderItem.lender || msg.sender == orderItem.borrower , "UNAUTHORIZED");
    require(orderItem.status == uint8(LendingStorage.OrderStatus.WaitPayment), "METHOD_NOT_ALLOWED");
    _storageAddress.deleteSellOrder(_nftId, _nftType);
    IERC721 nft = IERC721(_storageAddress.getNFTContractAddress(_nftType));
    nft.safeTransferFrom(address(this), orderItem.lender, _nftId, "");
    emit ORDERCANCEL(msg.sender, uint8(LendingStorage.OrderStatus.Cancel), orderItem.id, _nftType, _nftId, block.timestamp);
  }

  function paymentOrder(
    uint256 _nftId,
    uint8 _nftType,
    uint256 _startTime,
    string memory _orderUUid,
    bytes memory _signature
  ) external override
    nonReentrant whenNotPaused {
    LendingStorage.StorageInfor memory info = _storageAddress.getInfor();
    require(_nftId > 0, "NFT_INVALID");
    require(_nftType >= 0 && _nftType < info.countNFTContract, "NFT_TYPE_INVALID");
    require(_startTime > 0 && _startTime < block.timestamp + info.maxWaitingTime, "STARTTIME_ERROR");
    address borrower = _msgSender();
    require(_storageAddress.isExecutedOrder(_orderUUid) == false, "ORDER_IS_EXECUTED");
    _storageAddress.setExecutedOrder(_orderUUid, true);
    LendingStorage.OrderERC4907 memory orderItem = _storageAddress.getOrder(_nftId, _nftType);
    require(verifySignature(_nftId, _nftType, _signature, _orderUUid, info.adminVerify, orderItem.lender, msg.sender), "SIGNATURE_INVALID");
    require(orderItem.borrower == borrower, "UNAUTHORIZED");
    require(orderItem.status == uint8(LendingStorage.OrderStatus.WaitPayment), "ORDER_STATUS_NOT_ACTION");
    uint8 nftType = _nftType;
    uint256 expiredTime = block.timestamp + orderItem.rentalDuration * timeADay;
    uint256 nftId = _nftId;
    IERC4907 nft = IERC4907(_storageAddress.getNFTContractAddress(nftType));
    nft.setUser(nftId, borrower, uint64(expiredTime));
    uint8 statusPaid = uint8(LendingStorage.OrderStatus.Paid);
    _storageAddress.updateOrderItem(nftId, nftType, statusPaid, expiredTime);
    uint256 rentalPrice = orderItem.dailyRentalPrice * orderItem.rentalDuration;
    uint256 commissionPrice = (rentalPrice * orderItem.commissionPercent) / orderItem.percentDecimals;
    uint256 receivedPrice = rentalPrice - commissionPrice;
    _payment(address(this), info.commissionWallet, info.currencyToken, borrower, receivedPrice, commissionPrice);
    emit LENDINGPAYMENT(borrower, statusPaid, orderItem.id, nftType, nftId, receivedPrice, commissionPrice, expiredTime, block.timestamp);
  }

  function lenderRewardClaim(
    uint256 _nftId,
    uint8 _nftType,
    string memory _orderUUid,
    bytes memory _signature
  ) external override
    nonReentrant whenNotPaused {
    LendingStorage.StorageInfor memory info = _storageAddress.getInfor();
    require(_nftId > 0, "NFT_INVALID");
    require(_nftType >= 0 && _nftType < info.countNFTContract, "NFT_TYPE_INVALID");
    require(_storageAddress.isExecutedOrder(_orderUUid) == false, "ORDER_IS_EXECUTED");
    _storageAddress.setExecutedOrder(_orderUUid, true);
    LendingStorage.OrderERC4907 memory orderItem = _storageAddress.getOrder(_nftId, _nftType);
    require(verifySignature(_nftId, _nftType, _signature, _orderUUid, info.adminVerify, msg.sender, orderItem.borrower), "SIGNATURE_INVALID");
    require(orderItem.lender == msg.sender, "UNAUTHORIZED");
    uint8 statusPaid = uint8(LendingStorage.OrderStatus.Paid);
    uint8 statusClaimPrice = uint8(LendingStorage.OrderStatus.IsClaimPrice);
    uint8 statusExpired = uint8(LendingStorage.OrderStatus.Expired);
    require(orderItem.status == statusPaid || orderItem.status == statusExpired, "METHOD_NOT_ALLOWED");
    _storageAddress.updateOrderItem(_nftId, _nftType, statusClaimPrice, 0);
    uint256 rentalPrice = orderItem.dailyRentalPrice * orderItem.rentalDuration;
    uint256 receivedPrice = (rentalPrice * (orderItem.percentDecimals - orderItem.commissionPercent)) / orderItem.percentDecimals;
    TransferHelper.contractTransfer(info.currencyToken, msg.sender, receivedPrice);
    emit CLAIMPRICE(msg.sender, statusClaimPrice, orderItem.id, _nftType, _nftId, receivedPrice, block.timestamp);
  }

  function lenderClaimNFT(
    uint256 _nftId,
    uint8 _nftType,
    string memory _orderUUid,
    bytes memory _signature
  ) external override
    nonReentrant whenNotPaused {
    LendingStorage.StorageInfor memory info = _storageAddress.getInfor();
    require(_nftId > 0, "NFT_INVALID");
    require(_nftType >= 0 && _nftType < info.countNFTContract, "NFT_TYPE_INVALID");
    require(_storageAddress.isExecutedOrder(_orderUUid) == false, "ORDER_IS_EXECUTED");
    _storageAddress.setExecutedOrder(_orderUUid, true);
    LendingStorage.OrderERC4907 memory orderItem = _storageAddress.getOrder(_nftId, _nftType);
    require(verifySignature(_nftId, _nftType, _signature, _orderUUid, info.adminVerify, msg.sender, orderItem.borrower), "SIGNATURE_INVALID");
    require(orderItem.lender == msg.sender, "UNAUTHORIZED");
    require(orderItem.status == uint8(LendingStorage.OrderStatus.IsClaimPrice) && orderItem.expiredTime < block.timestamp, "METHOD_NOT_ALLOWED");
    _storageAddress.deleteSellOrder(_nftId, _nftType);
    IERC721 nft = IERC721(_storageAddress.getNFTContractAddress(_nftType));
    nft.safeTransferFrom(address(this), msg.sender, _nftId, "");
    emit CLAIMNFT(msg.sender, uint8(LendingStorage.OrderStatus.IsClaimNFT), orderItem.id, _nftType, _nftId, block.timestamp);
  }

  function _payment(
    address transactionWallet,
    address commisionWallet,
    address currencyExchange,
    address sender,
    uint256 receivedPrice,
    uint256 commissionPrice
  ) private {
    TransferHelper.safeTransferFrom(currencyExchange, sender, transactionWallet, receivedPrice);
    TransferHelper.safeTransferFrom(currencyExchange, sender, commisionWallet, commissionPrice);
  }

  function verifySignature(
    uint256 nftId,
    uint256 nftType,
    bytes memory signature,
    string memory orderUUid,
    address verifier,
    address lender,
    address borrower
  ) private pure returns (bool) {
    bytes32 hashValue = keccak256(abi.encodePacked(nftId, nftType, orderUUid, lender, borrower));
    address recover = hashValue.toEthSignedMessageHash().recover(signature);
    return recover == verifier;
  }
}