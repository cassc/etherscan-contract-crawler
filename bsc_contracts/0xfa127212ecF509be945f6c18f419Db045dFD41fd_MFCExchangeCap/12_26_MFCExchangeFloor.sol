// SPDX-License-Identifier: MIT
//
// MFCExchangeFloor [BUSD_MFC]
//

pragma solidity ^0.8.4;

import "../lib/token/BEP20/IBEP20.sol";
import "../token/MFCToken.sol";
import "../lib/utils/Context.sol";
import "../treasury/BUSDT.sol";
import "../exchange/MFCExchangeCap.sol";
import "./ExchangeCheck.sol";
import "../RegistrarClient.sol";

contract MFCExchangeFloor is ExchangeCheck, RegistrarClient {

  uint256 public constant MFC_FEE = 20000000000000000;
  uint256 public constant BUSD_FEE = 20000000000000000;
  uint256 public constant MULTIPLIER = 10**18;

  MFCToken private _mfc;
  IBEP20 private _busd;
  BUSDT private _busdt;
  MFCExchangeCap private _mfcExchangeCap;
  address private _deployer;
  uint256 private _initialPrice = 0;

  event TradeOffer(address buyer, uint256 price, uint256 sellerQuantity, uint256 buyerQuantity, uint256 timestamp);

  constructor(
    address registrarAddress_,
    address busdAddress_,
    uint256 initialPrice_
  ) RegistrarClient(registrarAddress_) {
    _busd = IBEP20(busdAddress_);
    _initialPrice = initialPrice_;
    _deployer = _msgSender();
  }

  modifier onlyDeployer() {
    require(_deployer == _msgSender(), "Caller is not the deployer");
    _;
  }

  function getInitialPrice() external view returns (uint256) {
    return _initialPrice;
  }

  function setInitialPrice(uint256 price) external onlyDeployer {
    uint256 mfcCirculation = _mfc.getMfcCirculation();
    require(mfcCirculation == 0, "Can no longer set");
    _initialPrice = price;
  }

  function getPrice() external view returns (uint256) {
    return _getPrice();
  }

  function getAmountOut(uint256 quantity) external view returns (uint256) {
    return _getAmountOut(quantity);
  }

  function tradeOffer(uint256 quantity, uint256 minimumOut) external onlyValidMember(_msgSender()) {
    require(quantity > 0, "Invalid quantity");
    _tradeOffer(quantity, minimumOut);
  }

  function tradeOffer(uint256 quantity, uint256 minimumOut, uint8 v, bytes32 r, bytes32 s) external onlyValidMember(_msgSender()) {
    require(quantity > 0, "Invalid quantity");
    _mfc.permit(_msgSender(), address(this), quantity, v, r, s);
    _tradeOffer(quantity, minimumOut);
  }

  function _tradeOffer(uint256 quantity, uint256 minimumOut) private {
    require(_mfc.allowance(_msgSender(), address(this)) >= quantity, "Insufficient allowance");
    require(_mfc.balanceOf(_msgSender()) >= quantity, "Insufficient balance");
    uint256 price = _getPrice();
    uint256 amountOut = _getAmountOut(quantity);
    require(amountOut >= minimumOut, "Insufficient output amount");

    // uint256 mfcFee = quantity * MFC_FEE / MULTIPLIER;
    // uint256 sellerReceives = quantity - mfcFee;
    uint256 busdFee = amountOut * BUSD_FEE / MULTIPLIER;
    uint256 buyerReceives = amountOut - busdFee;

    _mfc.transferFrom(_msgSender(), address(_mfcExchangeCap), quantity);
    _busdt.floorTransfer(_msgSender(), buyerReceives);

    emit TradeOffer(_msgSender(), price, amountOut, quantity, block.timestamp);
  }

  function updateAddresses() public override onlyRegistrar {
    _mfc = MFCToken(_registrar.getMFCToken());
    _busdt = BUSDT(_registrar.getBUSDT());
    _mfcExchangeCap = MFCExchangeCap(_registrar.getMFCExchangeCap());
    _updateExchangeCheck(_registrar);
  }

  function _getAmountOut(uint256 quantity) private view returns (uint256) {
    uint256 mfcCirculation = _mfc.getMfcCirculation();
    uint256 busdBalance = _busdt.getBusdtValue();
    uint256 amountOut = 0;
    if (mfcCirculation > 0) {
      amountOut = quantity * busdBalance / mfcCirculation;
    } else {
      amountOut = quantity * MULTIPLIER / _initialPrice;
    }
    if (amountOut > busdBalance) {
      amountOut = busdBalance;
    }
    return amountOut;
  }

  function _getPrice() private view returns (uint256) {
    uint256 mfcCirculation = _mfc.getMfcCirculation();
    uint256 busdBalance = _busdt.getBusdtValue();
    if (busdBalance == 0) {
      return 0;
    }
    if (mfcCirculation > 0) {
      return MULTIPLIER * mfcCirculation / busdBalance;
    } else {
      return _initialPrice;
    }
  }
}