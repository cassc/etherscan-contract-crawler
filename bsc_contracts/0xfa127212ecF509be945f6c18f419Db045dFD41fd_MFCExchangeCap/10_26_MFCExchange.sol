// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./MFCExchangeFloor.sol";
import "../lib/token/BEP20/BEP20.sol";
import "../token/MFCToken.sol";
import "../lib/utils/Context.sol";
import "./ExchangeCheck.sol";
import "../access/BackendAgent.sol";
import "../RegistrarClient.sol";

contract MFCExchange is Context, ExchangeCheck, BackendAgent, RegistrarClient {
  struct TradeOfferCalcInfo {
    uint256 amountOut;
    uint256 takerReceives;
    uint256 takerFee;
    uint256 makerReceives;
    uint256 makerFee;
  }

  uint256 public constant EXPIRES_IN = 30 days;
  uint256 public constant MINIMUM_AUTOCLOSE_IN_BUSD = 1000000000000000000; // 1 Ether
  uint256 public constant BUSD_FEE = 20000000000000000;
  uint256 public constant MFC_FEE = 20000000000000000;
  uint256 public constant MULTIPLIER = 10**18;

  address private _busdAddress;
  address private _busdComptrollerAddress;
  MFCExchangeFloor private _mfcExchangeFloor;
  uint256 private _nonce = 1;

  enum TradingPairs {
    MFC_BUSD,
    BUSD_MFC
  }

  struct Offer {
    uint256 id;
    TradingPairs tradingPair;
    uint256 quantity;
    uint256 price;
    uint256 expiresAt;
    bool isOpen;
  }

  struct TradingPair {
    address makerAssetAddress;
    address takerAssetAddress;
    address makerTreasuryAddress;
    address takerTreasuryAddress;
    uint256 makerFeeRate;
    uint256 takerFeeRate;
  }

  mapping(address => mapping(uint256 => Offer)) private _offers;
  mapping(TradingPairs => TradingPair) private _tradingPairs;

  event CreateOffer(uint256 id, address seller, TradingPairs tradingPair, uint256 quantity, uint256 price, uint256 expiresAt, uint256 timestamp);
  event TradeOffer(uint256 id, address buyer, uint256 sellerQuantity, uint256 buyerQuantity, uint256 unfilledQuantity, uint256 timestamp);
  event CloseOffer(uint256 id, uint256 timestamp);

  constructor(
    address registrarAddress_,
    address busdAddress_,
    address busdComptrollerAddress_,
    address[] memory backendAdminAgents,
    address[] memory backendAgents
  ) RegistrarClient(registrarAddress_) {
    _busdAddress = busdAddress_;
    _busdComptrollerAddress = busdComptrollerAddress_;
    _setBackendAdminAgents(backendAdminAgents);
    _setBackendAgents(backendAgents);
  }

  modifier onlyValidCreateOffer(TradingPairs tradingPair, uint256 quantity, uint256 price) {
    require(_pairExist(tradingPair), "Invalid pair");
    require(quantity > 0, "Invalid quantity");
    require(price > 0, "Invalid price");
    _;
  }

  modifier onlyValidTradeOffer(uint256 id, address seller, uint256 quantity) {
    require(_isOfferActive(id, seller), "Invalid offer");
    require(quantity > 0, "Invalid quantity");
    _;
  }

  modifier onlyOpenOffer(uint256 id, address seller) {
    require(_offers[seller][id].isOpen, "Offer must be open in order to close");
    _;
  }

  function getNonce() external view returns (uint256) {
    return _nonce;
  }

  function getOffer(uint256 id, address seller) external view returns (Offer memory) {
    return _offers[seller][id];
  }

  function createOffer(TradingPairs tradingPair, uint256 quantity, uint256 price)
    external
    onlyValidCreateOffer(tradingPair, quantity, price)
    onlyValidMember(_msgSender())
  {
    _createOffer(tradingPair, quantity, price);
  }

  function createOffer(TradingPairs tradingPair, uint256 quantity, uint256 price, uint8 v, bytes32 r, bytes32 s)
    external
    onlyValidCreateOffer(tradingPair, quantity, price)
    onlyValidMember(_msgSender())
  {
    // Verify maker asset must be MFC
    require(_tradingPairs[tradingPair].makerAssetAddress == _tradingPairs[TradingPairs.MFC_BUSD].makerAssetAddress, "Must be [MFC_BUSD]");
    MFCToken makerAsset = MFCToken(_tradingPairs[tradingPair].makerAssetAddress);
    // Call approval
    makerAsset.permit(_msgSender(), address(this), quantity, v, r, s);
    _createOffer(tradingPair, quantity, price);
  }

  function _createOffer(TradingPairs tradingPair, uint256 quantity, uint256 price) private {
    uint256 exchangeFloorPrice = _mfcExchangeFloor.getPrice();
    if (tradingPair == TradingPairs.BUSD_MFC) {
      require(price <= exchangeFloorPrice, "Price must be <= exchangeFloorPrice");
    } else if (tradingPair == TradingPairs.MFC_BUSD) {
      require((MULTIPLIER * MULTIPLIER / price) <= exchangeFloorPrice, "Price reciprocal must be <= exchangeFloorPrice");
    } else {
      revert("Unsupported pair");
    }
    BEP20 token = _getSpendingTokenAndCheck(_tradingPairs[tradingPair].makerAssetAddress, quantity);
    uint256 expiresAt = block.timestamp + EXPIRES_IN;
    uint256 id = _nonce++;
    _offers[_msgSender()][id] = Offer(id, tradingPair, quantity, price, expiresAt, true);
    token.transferFrom(_msgSender(), address(this), quantity);
    emit CreateOffer(id, _msgSender(), tradingPair, quantity, price, expiresAt, block.timestamp);
  }

  function tradeOffer(uint256 id, address seller, uint256 quantity)
    external
    onlyValidTradeOffer(id, seller, quantity)
    onlyValidMember(_msgSender())
    returns (TradeOfferCalcInfo memory)
  {
    return _tradeOffer(id, seller, quantity);
  }

  function tradeOffer(uint256 id, address seller, uint256 quantity, uint8 v, bytes32 r, bytes32 s)
    external
    onlyValidTradeOffer(id, seller, quantity)
    onlyValidMember(_msgSender())
    returns (TradeOfferCalcInfo memory)
  {
    // Verify taker asset must be MFC
    TradingPair memory tradingPair = _tradingPairs[_offers[seller][id].tradingPair];
    require(tradingPair.takerAssetAddress == _tradingPairs[TradingPairs.BUSD_MFC].takerAssetAddress, "Must be [BUSD_MFC]");

    MFCToken takerAsset = MFCToken(tradingPair.takerAssetAddress);
    // Call approval
    takerAsset.permit(_msgSender(), address(this), quantity, v, r, s);

    return _tradeOffer(id, seller, quantity);
  }

  function estimateTradeOffer(uint256 id, address seller, uint256 quantity) external view onlyValidTradeOffer(id, seller, quantity) onlyValidMember(_msgSender()) returns (TradeOfferCalcInfo memory) {
    TradingPair memory tradingPair = _tradingPairs[_offers[seller][id].tradingPair];
    uint256 maxInput = _offers[seller][id].quantity * _offers[seller][id].price / MULTIPLIER;
    require(quantity <= maxInput, "Not enough to sell");

    return _calcTradeOffer(tradingPair, quantity, _offers[seller][id].price);
  }

  function _tradeOffer(uint256 id, address seller, uint256 quantity) private returns (TradeOfferCalcInfo memory) {
    TradingPair memory tradingPair = _tradingPairs[_offers[seller][id].tradingPair];
    uint256 maxInput = _offers[seller][id].quantity * _offers[seller][id].price / MULTIPLIER;
    require(quantity <= maxInput, "Not enough to sell");

    TradeOfferCalcInfo memory calc = _executeTrade(tradingPair, seller, quantity, _offers[seller][id].price);

    require(_offers[seller][id].quantity >= calc.amountOut, "Bad calculations");
    _offers[seller][id].quantity -= calc.amountOut;

    // BUSD_MFC market - selling amount in BUSD < MINIMUM_AUTOCLOSE_IN_BUSD
    bool makerCloseout = (tradingPair.makerAssetAddress == _busdAddress && _offers[seller][id].quantity < MINIMUM_AUTOCLOSE_IN_BUSD);
    // MFC_BUSD market - converted selling amount in MFC to BUSD < MINIMUM_AUTOCLOSE_IN_BUSD
    bool takerCloseout = (tradingPair.takerAssetAddress == _busdAddress && _offers[seller][id].quantity * _offers[seller][id].price / MULTIPLIER < MINIMUM_AUTOCLOSE_IN_BUSD);

    if (makerCloseout || takerCloseout) {
      _closeOffer(id, seller); // Auto-close when selling amount in BUSD < MINIMUM_AUTOCLOSE_IN_BUSD
    }

    // For [MFC_BUSD] pair, sellerQuantity = MFC, buyerQuantity = BUSD
    emit TradeOffer(id, _msgSender(), calc.amountOut, quantity, _offers[seller][id].quantity, block.timestamp);

    return calc;
  }

  function closeOffer(uint256 id) external onlyOpenOffer(id, _msgSender()) {
    _closeOffer(id, _msgSender());
  }

  function closeOffer(address seller, uint256 id) external onlyOpenOffer(id, seller) onlyBackendAgents {
    _closeOffer(id, seller);
  }

  function _pairExist(TradingPairs tradingPair) private view returns (bool) {
    return _tradingPairs[tradingPair].makerAssetAddress != address(0);
  }

  function _isOfferActive(uint256 id, address seller) private view returns (bool) {
    return _offers[seller][id].isOpen && _offers[seller][id].expiresAt > block.timestamp;
  }

  function _getSpendingTokenAndCheck(address assetAddress, uint256 quantity) private view returns (BEP20) {
    BEP20 token = BEP20(assetAddress);
    require(token.allowance(_msgSender(), address(this)) >= quantity, "Insufficient allowance");
    require(token.balanceOf(_msgSender()) >= quantity, "Insufficient balance");
    return token;
  }

  function _calcTradeOffer(TradingPair memory tradingPair, uint256 quantity, uint256 price) private pure returns (TradeOfferCalcInfo memory) {
    // Offer is 1,000 MFC at 10.0 BUSD each (10,000 BUSD in total)
    // Taker want to swap 100 BUSD for 10 MFC
    // buyQuantity should be 100 BUSD * (10^18 / 10^19) = 10 MFC
    uint256 buyQuantity = quantity * MULTIPLIER / price;

    TradeOfferCalcInfo memory calc;
    calc.amountOut = buyQuantity;
    calc.makerFee = quantity * tradingPair.makerFeeRate / MULTIPLIER;
    calc.takerFee = buyQuantity * tradingPair.takerFeeRate / MULTIPLIER;
    calc.makerReceives = quantity - calc.makerFee;
    calc.takerReceives = buyQuantity - calc.takerFee;

    return calc;
  }

  // @dev returns maker quantity fulfilled by this trade
  function _executeTrade(TradingPair memory tradingPair, address seller, uint256 quantity, uint256 price) private returns (TradeOfferCalcInfo memory) {
    BEP20 makerAsset = BEP20(tradingPair.makerAssetAddress);
    BEP20 takerAsset = _getSpendingTokenAndCheck(tradingPair.takerAssetAddress, quantity);

    TradeOfferCalcInfo memory calc = _calcTradeOffer(tradingPair, quantity, price);

    takerAsset.transferFrom(_msgSender(), address(this), calc.makerReceives);
    takerAsset.transfer(seller, calc.makerReceives);
    takerAsset.transferFrom(_msgSender(), tradingPair.takerTreasuryAddress, calc.makerFee);
    makerAsset.transfer(_msgSender(), calc.takerReceives);
    makerAsset.transfer(tradingPair.makerTreasuryAddress, calc.takerFee);

    return calc;
  }

  function _closeOffer(uint256 id, address seller) private {
    uint256 remainingQuantity = _offers[seller][id].quantity;
    _offers[seller][id].isOpen = false;
    if (remainingQuantity > 0) {
      _offers[seller][id].quantity = 0;
      BEP20 token = BEP20(_tradingPairs[_offers[seller][id].tradingPair].makerAssetAddress);
      token.transfer(seller, remainingQuantity);
    }
    emit CloseOffer(id, block.timestamp);
  }

  function updateAddresses() public override onlyRegistrar {
    _mfcExchangeFloor = MFCExchangeFloor(_registrar.getMFCExchangeFloor());
    _updateExchangeCheck(_registrar);
    _initTradingPairs();
  }

  function _initTradingPairs() internal {
    address mfcExchangeCap = _registrar.getMFCExchangeCap();
    address mfcToken = _registrar.getMFCToken();
    _tradingPairs[TradingPairs.MFC_BUSD] = TradingPair(mfcToken, _busdAddress, mfcExchangeCap, _busdComptrollerAddress, MFC_FEE, BUSD_FEE);
    _tradingPairs[TradingPairs.BUSD_MFC] = TradingPair(_busdAddress, mfcToken, _busdComptrollerAddress, mfcExchangeCap, BUSD_FEE, MFC_FEE);
  }
}