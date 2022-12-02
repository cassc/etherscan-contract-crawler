// SPDX-License-Identifier: GPL

pragma solidity 0.8.0;

import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "../libs/fota/Auth.sol";
import "../libs/zeppelin/token/BEP20/IBEP20.sol";
import "../interfaces/IFOTAGame.sol";
import "../interfaces/IFOTAToken.sol";
import "../interfaces/IMarketPlace.sol";
import "../interfaces/IFOTAPricer.sol";
import "../interfaces/ILandNFT.sol";
import "../interfaces/ICitizen.sol";
import "../libs/fota/Math.sol";
import "../libs/fota/StringUtil.sol";
import "../libs/fota/ArrayUtil.sol";

contract LandLordManager is Auth, PausableUpgradeable {
  using Math for uint;
  using ArrayUtil for uint[];
  struct Land {
    address landLord;
    uint landLordPercentage;
    uint pendingReward;
    uint totalRewarded;
    uint foundingPrice;
    address[] shareHolders;
    mapping (address => uint) shareHolderPercentage;
  }
  struct ShareOrder {
    uint mission;
    address maker;
    address taker;
    uint sharePercentage; // decimal 3
    uint price;
    bool active;
  }
  struct LandOrder {
    uint mission;
    uint nftId;
    address maker;
    address taker;
    uint price;
    bool active;
  }
  enum OrderType {
    land,
    shareHolder
  }
  IMarketPlace.PaymentType public paymentType;
  IFOTAGame public gameProxyContract;
  IFOTAToken public fotaToken;
  IFOTAPricer public fotaPricer;
  IBEP20 public busdToken;
  IBEP20 public usdtToken;
  ILandNFT public landNFT;
  ICitizen public citizen;
  mapping (uint => Land) public lands;
  mapping (uint => ShareOrder) public shareOrders;
  mapping (uint => LandOrder) public landOrders;
  mapping (address => uint[]) public ownerActiveShareOrders; // address -> orderId
  mapping (address => mapping (uint => bool)) public ownerActiveLandOrders; // address => mission
  uint private totalOrder;
  address public treasuryAddress;
  address public fundAdmin;
  uint public referralShare; // decimal 3
  uint public creativeShare; // decimal 3
  uint public treasuryShare; // decimal 3
  uint constant FULL_PERCENT_DECIMAL3 = 100000;
  uint public landMinPrice; // decimal 3
  uint public shareMinPrice; // decimal 3

  event Claimed(address indexed landLord, uint amount, uint landLordAmount, uint mission, uint percentage);
  event OrderCreated(uint _mission, OrderType orderType, address indexed maker, uint orderId, uint sharePercentage, uint price);
  event OrderTaken(address indexed taker, uint orderId, address maker, IMarketPlace.PaymentType paymentType, IMarketPlace.PaymentCurrency paymentCurrency);
  event OrderCanceled(uint orderId);
  event FoundingPriceUpdated(uint mission, uint price);
  event ShareHolderChanged(uint mission, address oldHolder, address newHolder);
  event PaymentTypeChanged(IMarketPlace.PaymentType newMethod);
  event LandLordGranted(uint mission, address landLord, uint price, IMarketPlace.PaymentType paymentType, IMarketPlace.PaymentCurrency paymentCurrency);
  event ReferralSent(address indexed inviter, address indexed invitee, uint referralSharingAmount, IMarketPlace.PaymentCurrency paymentCurrency);
  event MinPriceUpdated(uint landMinPrice, uint shareMinPrice, uint timestamp);
  event ShareHolderClaimed(address indexed landLord, uint mission, address indexed shareHolder, uint shareAmount, uint landLordAmount, uint percentage);
  event GiveReward(uint indexed mission, uint amount);

  modifier onlyLandLord(uint _mission) {
    require(_isLandLord(_mission, msg.sender) && landNFT.ownerOf(_mission) == msg.sender, "Only land lord");
    _;
  }

  function initialize(
    address _mainAdmin,
    address _fotaToken,
    address _fotaPricer,
    address _landNFT,
    address _treasuryAddress,
    address _gameProxy,
    address _citizen
  ) public initializer {
    super.initialize(_mainAdmin);
    busdToken = IBEP20(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56);
    usdtToken = IBEP20(0x55d398326f99059fF775485246999027B3197955);
    fotaToken = IFOTAToken(_fotaToken);
    fotaPricer = IFOTAPricer(_fotaPricer);
    landNFT = ILandNFT(_landNFT);
    fundAdmin = _mainAdmin;
    treasuryAddress = _treasuryAddress;
    gameProxyContract = IFOTAGame(_gameProxy);
    citizen = ICitizen(_citizen);
    referralShare = 2000;
    creativeShare = 3000;
    treasuryShare = 5000;
  }

  function giveReward(uint _mission, uint _amount) external {
    _takeFundFOTA(_amount, address(this));
    lands[_mission].pendingReward += _amount;
    emit GiveReward(_mission, lands[_mission].pendingReward);
  }

  function claim(uint _mission) external onlyLandLord(_mission) whenNotPaused {
    uint pendingReward = lands[_mission].pendingReward;
    if (pendingReward > 0) {
      lands[_mission].pendingReward = 0;
      lands[_mission].totalRewarded += pendingReward;
      uint landLordPercentage = lands[_mission].landLordPercentage;
      uint landLordAmount = pendingReward * landLordPercentage / FULL_PERCENT_DECIMAL3;
      fotaToken.transfer(msg.sender, landLordAmount);
      for(uint i = 0; i < lands[_mission].shareHolders.length; i++) {
        address shareHolder = lands[_mission].shareHolders[i];
        uint percentage = lands[_mission].shareHolderPercentage[shareHolder];
        uint shareAmount = pendingReward * percentage / FULL_PERCENT_DECIMAL3;
        fotaToken.transfer(shareHolder, shareAmount);
        emit ShareHolderClaimed(msg.sender, _mission, shareHolder, shareAmount, landLordAmount, percentage);
      }
      emit Claimed(msg.sender, pendingReward, landLordAmount, _mission, landLordPercentage);
    }
  }

  function makeLandOrder(uint _mission, uint _price) external onlyLandLord(_mission) {
    require(landNFT.isApprovedForAll(msg.sender, address(this)) || landNFT.getApproved(_mission) == address(this), "Please call approve first");
    require(!ownerActiveLandOrders[msg.sender][_mission], 'This land is selling');
    require(_price >= landMinPrice, "LandLordManager: price invalid");
    landOrders[totalOrder] = LandOrder(_mission, _mission, msg.sender, address(0), _price, true);
    ownerActiveLandOrders[msg.sender][_mission] = true;
    landNFT.transferFrom(msg.sender, address(this), _mission);
    emit OrderCreated(_mission, OrderType.land, msg.sender, totalOrder, 0, _price);
    totalOrder += 1;
  }

  function makeShareOrder(uint _mission, uint _sharePercent, uint _price) external {
    _validateMaker(_mission, _sharePercent);
    require(_price >= shareMinPrice, "LandLordManager: price invalid");
    shareOrders[totalOrder] = ShareOrder(_mission, msg.sender, address(0), _sharePercent, _price, true);
    emit OrderCreated(_mission, OrderType.shareHolder, msg.sender, totalOrder, _sharePercent, _price);
    ownerActiveShareOrders[msg.sender].push(totalOrder);
    totalOrder += 1;
  }

  function cancelOrder(uint _id) external {
    ShareOrder storage shareOrder = shareOrders[_id];
    if (shareOrder.active) {
      require(shareOrder.maker == msg.sender || _isMainAdmin(), "401");
      shareOrder.active = false;
      _removeOwnerActiveShareOrders(shareOrder.maker, _id);
    } else {
      LandOrder storage landOrder = landOrders[_id];
      require(landOrder.maker == msg.sender || _isMainAdmin(), "401");
      require(landOrder.active, "Order invalid");
      landOrder.active = false;
      delete ownerActiveLandOrders[landOrder.maker][landOrder.mission];
      landNFT.transferFrom(address(this), landOrder.maker, landOrder.nftId);
    }
    emit OrderCanceled(_id);
  }

  function takeLandOrder(uint _id, IMarketPlace.PaymentCurrency _paymentCurrency) external whenNotPaused {
    _validatePaymentMethod(_paymentCurrency);
    LandOrder storage order = landOrders[_id];
    require(order.active && order.taker == address(0), "Order is invalid");
    order.taker = msg.sender;
    order.active = false;
    delete ownerActiveLandOrders[order.maker][order.mission];
    for(uint i = 0; i < ownerActiveShareOrders[order.maker].length; i++) {
      uint orderId = ownerActiveShareOrders[order.maker][i];
      shareOrders[orderId].active = false;
      emit OrderCanceled(orderId);
    }
    delete ownerActiveShareOrders[order.maker];
    landNFT.transferFrom(address(this), order.taker, order.nftId);
    lands[order.mission].landLord = msg.sender;
    uint paymentAmount = _getPaymentAmount(order.price, _paymentCurrency);
    _transferOrderValue(order.mission, order.maker, paymentAmount, _paymentCurrency);
    emit OrderTaken(msg.sender, _id, order.maker, paymentType, _paymentCurrency);
  }

  function takeShareOrder(uint _id, IMarketPlace.PaymentCurrency _paymentCurrency) external whenNotPaused {
    _validatePaymentMethod(_paymentCurrency);
    ShareOrder storage order = shareOrders[_id];
    require(order.active && order.taker == address(0), "Invalid order");
    require(order.sharePercentage > 0, "Invalid order");
    if(_isLandLord(order.mission, order.maker)) {
      lands[order.mission].landLordPercentage = lands[order.mission].landLordPercentage.sub(order.sharePercentage);
    } else {
      lands[order.mission].shareHolderPercentage[order.maker] = lands[order.mission].shareHolderPercentage[order.maker].sub(order.sharePercentage);
    }
    if (_isHolders(lands[order.mission], msg.sender)) {
      lands[order.mission].shareHolderPercentage[msg.sender] = lands[order.mission].shareHolderPercentage[msg.sender].add(order.sharePercentage);
    } else {
      lands[order.mission].shareHolderPercentage[msg.sender] = order.sharePercentage;
      lands[order.mission].shareHolders.push(msg.sender);
    }
    order.taker = msg.sender;
    order.active = false;
    _removeOwnerActiveShareOrders(order.maker, _id);
    uint paymentAmount = _getPaymentAmount(order.price, _paymentCurrency);
    _transferOrderValue(order.mission, order.maker, paymentAmount, _paymentCurrency);
    emit OrderTaken(msg.sender, _id, order.maker, paymentType, _paymentCurrency);
  }

  function takeFounding(uint _mission, IMarketPlace.PaymentCurrency _paymentCurrency) external whenNotPaused {
    require(lands[_mission].foundingPrice > 0, "Land is not available");
    require(lands[_mission].landLord == address(0), "Land has occupied");
    _validatePaymentMethod(_paymentCurrency);
    uint currentPrice = _getPaymentAmount(lands[_mission].foundingPrice, _paymentCurrency);
    _takeFund(currentPrice, _paymentCurrency, address(this));
    _transferFund(fundAdmin, currentPrice, _paymentCurrency);
    lands[_mission].landLord = msg.sender;
    lands[_mission].landLordPercentage = FULL_PERCENT_DECIMAL3;
    landNFT.mintLand(_mission, msg.sender);
    emit LandLordGranted(_mission, msg.sender, lands[_mission].foundingPrice, paymentType, _paymentCurrency);
  }

  function syncLandLord(uint _mission) public {
    address landLord = landNFT.ownerOf(_mission);
    if (lands[_mission].landLord == address(0) && landLord != address(0)) {
      lands[_mission].landLordPercentage = FULL_PERCENT_DECIMAL3;
    }
    lands[_mission].landLord = landLord;
  }

  function getShareHolderInfo(uint _mission, address _shareHolder) external view returns (uint, uint) {
    Land storage land = lands[_mission];
    return(
      land.shareHolders.length,
      land.shareHolderPercentage[_shareHolder]
    );
  }

  function getLandInfo(uint _mission) external view returns (address, address[] memory, uint[] memory) {
    Land storage land = lands[_mission];
    uint[] memory percentages = new uint[](land.shareHolders.length);
    for (uint i = 0; i < land.shareHolders.length; i++) {
      address holder = land.shareHolders[i];
      percentages[i] = land.shareHolderPercentage[holder];
    }
    return(
      land.landLord,
      land.shareHolders,
      percentages
    );
  }

  // ADMINS FUNCTIONS

  function updatePaymentType(IMarketPlace.PaymentType _type) external onlyMainAdmin {
    paymentType = _type;
    emit PaymentTypeChanged(_type);
  }

  function setFoundingPrice(uint _mission, uint _price) external onlyMainAdmin {
    require(lands[_mission].landLord == address(0), "Land have land lord already");
    lands[_mission].foundingPrice = _price;
    emit FoundingPriceUpdated(_mission, _price);
  }

  function updateShareHolder(uint _mission, address _old, address _new) external onlyMainAdmin {
    Land storage land = lands[_mission];
    require(land.shareHolderPercentage[_old] > 0, "Invalid old holder");
    land.shareHolderPercentage[_new] += land.shareHolderPercentage[_old];
    delete land.shareHolderPercentage[_old];
    uint newIndex = _indexOf(land, _new);
    uint oldIndex = _indexOf(land, _old);
    if (newIndex == type(uint).max) {
      land.shareHolders[oldIndex] = _new;
    } else {
      land.shareHolders[oldIndex] = land.shareHolders[land.shareHolders.length - 1];
      land.shareHolders.pop();
    }
    emit ShareHolderChanged(_mission, _old, _new);
  }

  function setContracts(
    address _fotaToken,
    address _busdToken,
    address _usdtToken,
    address _fotaPricer,
    address _landNFT,
    address _gameProxy,
    address _citizen
  ) external onlyMainAdmin {
    fotaToken = IFOTAToken(_fotaToken);
    busdToken = IBEP20(_busdToken);
    usdtToken = IBEP20(_usdtToken);
    fotaPricer = IFOTAPricer(_fotaPricer);
    landNFT = ILandNFT(_landNFT);
    gameProxyContract = IFOTAGame(_gameProxy);
    citizen = ICitizen(_citizen);
  }

  function setShares(uint _referralShare, uint _creatorShare, uint _treasuryShare) external onlyMainAdmin {
    require(_referralShare > 0 && _referralShare <= 10000);
    referralShare = _referralShare;
    require(_creatorShare > 0 && _creatorShare <= 10000);
    creativeShare = _creatorShare;
    require(_treasuryShare > 0 && _treasuryShare <= 10000);
    treasuryShare = _treasuryShare;
  }

  function updateFundAdmin(address _address) external onlyMainAdmin {
    require(_address != address(0));
    fundAdmin = _address;
  }

  function updateMinPrice(uint _landMinPrice, uint _shareMinPrice) external onlyMainAdmin {
    landMinPrice = _landMinPrice;
    shareMinPrice = _shareMinPrice;
    emit MinPriceUpdated(landMinPrice, shareMinPrice, block.timestamp);
  }

  function updatePauseStatus(bool _paused) external onlyMainAdmin {
    if(_paused) {
      _pause();
    } else {
      _unpause();
    }
  }

  function drain(address _tokenAddress, uint _amount, address _receiver) external onlyMainAdmin {
    IBEP20 token = IBEP20(_tokenAddress);
    require(_amount <= token.balanceOf(address(this)), "FOTAFarm: Contract is insufficient balance");
    token.transfer(_receiver, _amount);
  }

  // PRIVATE FUNCTIONS

  function _isFotaPayment(IMarketPlace.PaymentCurrency _paymentCurrency) private view returns (bool) {
    return paymentType == IMarketPlace.PaymentType.fota || (paymentType == IMarketPlace.PaymentType.all && _paymentCurrency == IMarketPlace.PaymentCurrency.fota);
  }

  function _validatePaymentMethod(IMarketPlace.PaymentCurrency _paymentCurrency) private view {
    if (paymentType == IMarketPlace.PaymentType.fota) {
      require(_paymentCurrency == IMarketPlace.PaymentCurrency.fota, "400");
    } else if (paymentType == IMarketPlace.PaymentType.usd) {
      require(_paymentCurrency != IMarketPlace.PaymentCurrency.fota, "400");
    }
  }

  function _takeFund(uint _amount, IMarketPlace.PaymentCurrency _paymentCurrency, address _to) private {
    if (paymentType == IMarketPlace.PaymentType.fota) {
      _takeFundFOTA(_amount, _to);
    } else if (paymentType == IMarketPlace.PaymentType.usd) {
      _takeFundUSD(_amount, _paymentCurrency, _to);
    } else if (_paymentCurrency == IMarketPlace.PaymentCurrency.fota) {
      _takeFundFOTA(_amount, _to);
    } else {
      _takeFundUSD(_amount, _paymentCurrency, _to);
    }
  }

  function _takeFundUSD(uint _amount, IMarketPlace.PaymentCurrency _paymentCurrency, address _to) private {
    require(_paymentCurrency != IMarketPlace.PaymentCurrency.fota, "Invalid payment currency");
    IBEP20 usdToken = _paymentCurrency == IMarketPlace.PaymentCurrency.busd ? busdToken : usdtToken;
    require(usdToken.allowance(msg.sender, address(this)) >= _amount, "Please call approve first");
    require(usdToken.balanceOf(msg.sender) >= _amount, "Insufficient balance");
    require(usdToken.transferFrom(msg.sender, _to, _amount), "Transfer USD failed");
  }

  function _takeFundFOTA(uint _amount, address _to) private {
    require(fotaToken.allowance(msg.sender, address(this)) >= _amount, "Please call approve first");
    require(fotaToken.balanceOf(msg.sender) >= _amount, "Insufficient balance");
    require(fotaToken.transferFrom(msg.sender, _to, _amount), "Transfer FOTA failed");
  }

  function _transferFund(address _receiver, uint _amount, IMarketPlace.PaymentCurrency _paymentCurrency) private {
    if (_receiver == address(this)) {
      _receiver = fundAdmin;
    }
    if (paymentType == IMarketPlace.PaymentType.usd) {
      _transferFundUSD(_receiver, _amount, _paymentCurrency);
    } else if (paymentType == IMarketPlace.PaymentType.fota) {
      _transferFundFOTA(_receiver, _amount);
    } else if (_paymentCurrency == IMarketPlace.PaymentCurrency.fota) {
      _transferFundFOTA(_receiver, _amount);
    } else {
      _transferFundUSD(_receiver, _amount, _paymentCurrency);
    }
  }

  function _transferFundUSD(address _receiver, uint _amount, IMarketPlace.PaymentCurrency _paymentCurrency) private {
    if (_paymentCurrency == IMarketPlace.PaymentCurrency.usdt) {
      require(usdtToken.transfer(_receiver, _amount), "Transfer USDT failed");
    } else {
      require(busdToken.transfer(_receiver, _amount), "Transfer BUSD failed");
    }
  }

  function _transferFundFOTA(address _receiver, uint _amount) private {
    require(fotaToken.transfer(_receiver, _amount), "Transfer FOTA failed");
  }

  function _validateMaker(uint _mission, uint _sharePercent) private view {
    require(_sharePercent <= FULL_PERCENT_DECIMAL3, "Share percentage invalid");
    if (_isLandLord(_mission, msg.sender)) {
      require(lands[_mission].landLordPercentage >= _sharePercent, "Maker invalid");
    } else {
      require(lands[_mission].shareHolderPercentage[msg.sender] >= _sharePercent, "Maker invalid");
    }
  }

  function _isLandLord(uint _mission, address _landLord) private view returns (bool) {
    return lands[_mission].landLord == _landLord;
  }

  function _isHolders(Land storage _land, address _address) private view returns (bool) {
    for(uint i = 0; i < _land.shareHolders.length; i++) {
      if (_land.shareHolders[i] == _address) {
        return true;
      }
    }
    return false;
  }

  function _indexOf(Land storage _land, address _address) private view returns (uint) {
    for(uint i = 0; i < _land.shareHolders.length; i++) {
      if (_land.shareHolders[i] == _address) {
        return i;
      }
    }
    return type(uint).max;
  }

  function _getPaymentAmount(uint _price, IMarketPlace.PaymentCurrency _paymentCurrency) private view returns (uint) {
    if (_isFotaPayment(_paymentCurrency)) {
      return _price * 1000 / fotaPricer.fotaPrice();
    }
    return _price;
  }

  function _transferOrderValue(uint _mission, address _receiver, uint _paymentAmount, IMarketPlace.PaymentCurrency _paymentCurrency) private {
    uint shareAmount = _paymentAmount * (referralShare + creativeShare + treasuryShare) / FULL_PERCENT_DECIMAL3;
    _takeFund(_paymentAmount, _paymentCurrency, address(this));
    _transferFund(_receiver, _paymentAmount - shareAmount, _paymentCurrency);
    _shareOrderValue(_mission, shareAmount, _paymentCurrency);
  }

  function _shareOrderValue(uint _tokenId, uint _totalShareAmount, IMarketPlace.PaymentCurrency _paymentCurrency) private {
    uint totalSharePercent = referralShare + creativeShare + treasuryShare;
    uint referralSharingAmount = referralShare * _totalShareAmount / totalSharePercent;
    uint treasurySharingAmount = treasuryShare * _totalShareAmount / totalSharePercent;
    uint creativeSharingAmount = creativeShare * _totalShareAmount / totalSharePercent;
    address inviter = citizen.getInviter(msg.sender);
    if (inviter == address(0)) {
      inviter = treasuryAddress;
    } else {
      bool validInviter = _validateInviter(inviter);
      if (!validInviter) {
        inviter = treasuryAddress;
      }
    }
    emit ReferralSent(inviter, msg.sender, referralSharingAmount, _paymentCurrency);
    _transferFund(inviter, referralSharingAmount, _paymentCurrency);

    address creator = landNFT.creators(_tokenId);
    if (creator == address(0)) {
      creator = fundAdmin;
    }
    _transferFund(creator, creativeSharingAmount, _paymentCurrency);

    _transferFund(treasuryAddress, treasurySharingAmount, _paymentCurrency);
  }

  function _validateInviter(address _inviter) private view returns (bool) {
    return gameProxyContract.validateInviter(_inviter);
  }

  function _removeOwnerActiveShareOrders(address _maker, uint _orderId) private {
    ownerActiveShareOrders[_maker].removeElementFromArray(_orderId);
  }
}