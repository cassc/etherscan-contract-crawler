// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import { VETHRevenueCycleTreasury } from "./VETHRevenueCycleTreasury.sol";
import { ERC20 } from "../lib/token/ERC20/ERC20.sol";
import { VYToken } from "../token/VYToken.sol";
import { BackendAgent } from "../access/BackendAgent.sol";
import { RegistrarClient } from "../RegistrarClient.sol";
import { Router } from "../Router.sol";

contract VETHP2P is BackendAgent, RegistrarClient {

  uint256 private constant MULTIPLIER = 10**18;

  struct TradeOfferCalcInfo {
    uint256 amountOut;
    uint256 takerReceives;
    uint256 takerFee;
    uint256 makerReceives;
    uint256 makerFee;
  }

  uint256 public constant EXPIRES_IN = 30 days;
  uint256 public constant MINIMUM_AUTOCLOSE_IN_ETH = 500000000000000; // 0.0005 ETH
  uint256 public constant ETH_FEE = 20000000000000000;
  uint256 public constant VY_FEE = 20000000000000000;

  Router private _ethComptroller;
  VETHRevenueCycleTreasury private _vethRevenueCycleTreasury;
  uint256 private _nonce = 1;

  enum TradingPairs {
    VY_ETH,
    ETH_VY
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
    address registrarAddress,
    address ethComptrollerAddress_,
    address[] memory backendAdminAgents,
    address[] memory backendAgents
  ) RegistrarClient(registrarAddress) {
    require(ethComptrollerAddress_ != address(0), "Invalid address");

    _ethComptroller = Router(payable(ethComptrollerAddress_));
    _setBackendAdminAgents(backendAdminAgents);
    _setBackendAgents(backendAgents);
  }

  modifier onlyValidCreateOffer(TradingPairs tradingPair, uint256 quantity, uint256 price) {
    require(_pairExist(tradingPair), "Invalid pair");
    require(quantity > 0, "Invalid quantity");
    require(price > 0, "Invalid price");

    if (tradingPair == TradingPairs.ETH_VY) {
      require(msg.value == quantity, "Invalid ETH amount sent");
    } else {
      require(msg.value == 0, "Invalid ETH amount sent");
    }
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
    payable
    onlyValidCreateOffer(tradingPair, quantity, price)
  {
    _createOffer(tradingPair, quantity, price);
  }

  function createOffer(TradingPairs tradingPair, uint256 quantity, uint256 price, uint8 v, bytes32 r, bytes32 s)
    external
    payable
    onlyValidCreateOffer(tradingPair, quantity, price)
  {
    // Verify maker asset must be VY
    require(_tradingPairs[tradingPair].makerAssetAddress == _tradingPairs[TradingPairs.VY_ETH].makerAssetAddress, "Must be [VY_ETH]");
    VYToken makerAsset = VYToken(_tradingPairs[tradingPair].makerAssetAddress);
    // Call approval
    makerAsset.permit(_msgSender(), address(this), quantity, v, r, s);
    _createOffer(tradingPair, quantity, price);
  }

  function _createOffer(TradingPairs tradingPair, uint256 quantity, uint256 price) private {
    uint256 yieldRate = _vethRevenueCycleTreasury.getYieldRate();
    if (tradingPair == TradingPairs.ETH_VY) {
      require(price <= yieldRate, "Price must be <= yieldRate");
    } else if (tradingPair == TradingPairs.VY_ETH) {
      require((MULTIPLIER * MULTIPLIER / price) <= yieldRate, "Price reciprocal must be <= yieldRate");
    } else {
      revert("Unsupported pair");
    }

    // Create offer
    uint256 expiresAt = block.timestamp + EXPIRES_IN;
    uint256 id = _nonce++;
    _offers[_msgSender()][id] = Offer(id, tradingPair, quantity, price, expiresAt, true);

    // Transfer VY to the contract
    if (tradingPair == TradingPairs.VY_ETH) {
      ERC20 token = _getSpendingTokenAndCheck(_tradingPairs[tradingPair].makerAssetAddress, quantity);
      token.transferFrom(_msgSender(), address(this), quantity);
    }

    emit CreateOffer(id, _msgSender(), tradingPair, quantity, price, expiresAt, block.timestamp);
  }

  function tradeOffer(uint256 id, address seller, uint256 quantity)
    external
    payable
    onlyValidTradeOffer(id, seller, quantity)
    returns (TradeOfferCalcInfo memory)
  {
    _validateTradeOfferETHAmount(id, seller, quantity);

    return _tradeOffer(id, seller, quantity);
  }

  function tradeOffer(uint256 id, address seller, uint256 quantity, uint8 v, bytes32 r, bytes32 s)
    external
    payable
    onlyValidTradeOffer(id, seller, quantity)
    returns (TradeOfferCalcInfo memory)
  {
    _validateTradeOfferETHAmount(id, seller, quantity);

    // Verify taker asset must be VY
    TradingPair memory tradingPair = _tradingPairs[_offers[seller][id].tradingPair];
    require(tradingPair.takerAssetAddress == _tradingPairs[TradingPairs.ETH_VY].takerAssetAddress, "Must be [ETH_VY]");

    VYToken takerAsset = VYToken(tradingPair.takerAssetAddress);
    // Call approval
    takerAsset.permit(_msgSender(), address(this), quantity, v, r, s);

    return _tradeOffer(id, seller, quantity);
  }

  function estimateTradeOffer(uint256 id, address seller, uint256 quantity) external view onlyValidTradeOffer(id, seller, quantity) returns (TradeOfferCalcInfo memory) {
    TradingPair memory tradingPair = _tradingPairs[_offers[seller][id].tradingPair];
    uint256 maxInput = _offers[seller][id].quantity * _offers[seller][id].price / MULTIPLIER;
    require(quantity <= maxInput, "Not enough to sell");

    return _calcTradeOffer(tradingPair, quantity, _offers[seller][id].price);
  }

  function _tradeOffer(uint256 id, address seller, uint256 quantity) private returns (TradeOfferCalcInfo memory) {
    TradingPair memory tradingPair = _tradingPairs[_offers[seller][id].tradingPair];
    uint256 maxInput = _offers[seller][id].quantity * _offers[seller][id].price / MULTIPLIER;
    require(quantity <= maxInput, "Not enough to sell");

    /// @dev returns maker quantity fulfilled by this trade
    TradeOfferCalcInfo memory calc = _calcTradeOffer(tradingPair, quantity, _offers[seller][id].price);

    // Update offer quantity
    require(_offers[seller][id].quantity >= calc.amountOut, "Bad calculations");
    _offers[seller][id].quantity -= calc.amountOut;

    // VY_ETH trade
    if (tradingPair.takerAssetAddress == address(0)) {
      ERC20 makerAsset = ERC20(tradingPair.makerAssetAddress);

      // Transfer taker ETH
      _transfer(seller, calc.makerReceives);
      _ethComptroller.route{ value: calc.makerFee }();

      // Transfer maker VY
      makerAsset.transfer(_msgSender(), calc.takerReceives);
      makerAsset.transfer(tradingPair.makerTreasuryAddress, calc.takerFee);
    } else { // ETH_VY trade
      ERC20 takerAsset = _getSpendingTokenAndCheck(tradingPair.takerAssetAddress, quantity);

      /**
       * Transfer taker VY
       *
       * @dev the code below transfers makerReceives from taker to contract, then from contract to maker
       * instead of transferring makerReceives directly from taker to maker, is to avoid user transfer fee
       * being applied to (See ticket-296 for more info)
       */
      takerAsset.transferFrom(_msgSender(), address(this), calc.makerReceives);
      takerAsset.transfer(seller, calc.makerReceives);
      takerAsset.transferFrom(_msgSender(), tradingPair.takerTreasuryAddress, calc.makerFee);

      // Transfer maker ETH
      _transfer(_msgSender(), calc.takerReceives);
      _ethComptroller.route{ value: calc.takerFee }();
    }

    // ETH_VY market - selling amount in ETH < MINIMUM_AUTOCLOSE_IN_ETH
    bool makerCloseout = (tradingPair.makerAssetAddress == address(0) && _offers[seller][id].quantity < MINIMUM_AUTOCLOSE_IN_ETH);
    // VY_ETH market - converted selling amount in VY to ETH < MINIMUM_AUTOCLOSE_IN_ETH
    bool takerCloseout = (tradingPair.takerAssetAddress == address(0) && _offers[seller][id].quantity * _offers[seller][id].price / MULTIPLIER < MINIMUM_AUTOCLOSE_IN_ETH);

    if (makerCloseout || takerCloseout) {
      _closeOffer(id, seller); // Auto-close when selling amount in ETH < MINIMUM_AUTOCLOSE_IN_ETH
    }

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
    return _tradingPairs[tradingPair].makerAssetAddress != address(0) || _tradingPairs[tradingPair].takerAssetAddress != address(0);
  }

  function _isOfferActive(uint256 id, address seller) private view returns (bool) {
    return _offers[seller][id].isOpen && _offers[seller][id].expiresAt > block.timestamp;
  }

  function _getSpendingTokenAndCheck(address assetAddress, uint256 quantity) private view returns (ERC20) {
    ERC20 token = ERC20(assetAddress);
    require(token.allowance(_msgSender(), address(this)) >= quantity, "Insufficient allowance");
    require(token.balanceOf(_msgSender()) >= quantity, "Insufficient balance");
    return token;
  }

  function _calcTradeOffer(TradingPair memory tradingPair, uint256 quantity, uint256 price) private pure returns (TradeOfferCalcInfo memory) {
    // Offer is 1,000 VY at 10.0 ETH each (10,000 ETH in total)
    // Taker want to swap 100 ETH for 10 VY
    // buyQuantity should be 100 ETH * (10^18 / 10^19) = 10 VY
    uint256 buyQuantity = quantity * MULTIPLIER / price;

    TradeOfferCalcInfo memory calc;
    calc.amountOut = buyQuantity;
    calc.makerFee = quantity * tradingPair.makerFeeRate / MULTIPLIER;
    calc.takerFee = buyQuantity * tradingPair.takerFeeRate / MULTIPLIER;
    calc.makerReceives = quantity - calc.makerFee;
    calc.takerReceives = buyQuantity - calc.takerFee;

    return calc;
  }

  function _closeOffer(uint256 id, address seller) private {
    uint256 remainingQuantity = _offers[seller][id].quantity;
    _offers[seller][id].isOpen = false;
    if (remainingQuantity > 0) {
      _offers[seller][id].quantity = 0;

      address makerAssetAddress = _tradingPairs[_offers[seller][id].tradingPair].makerAssetAddress;
      if (makerAssetAddress == address(0)) {
        _transfer(seller, remainingQuantity);
      } else {
        ERC20 token = ERC20(makerAssetAddress);
        token.transfer(seller, remainingQuantity);
      }
    }
    emit CloseOffer(id, block.timestamp);
  }

  function updateAddresses() external override onlyRegistrar {
    _vethRevenueCycleTreasury = VETHRevenueCycleTreasury(_registrar.getVETHRevenueCycleTreasury());
    _initTradingPairs();
  }

  function _initTradingPairs() internal {
    address vethRevenueCycleTreasury = _registrar.getVETHRevenueCycleTreasury();
    address vyToken = _registrar.getVYToken();
    _tradingPairs[TradingPairs.VY_ETH] = TradingPair(vyToken, address(0), vethRevenueCycleTreasury, address(_ethComptroller), VY_FEE, ETH_FEE);
    _tradingPairs[TradingPairs.ETH_VY] = TradingPair(address(0), vyToken, address(_ethComptroller), vethRevenueCycleTreasury, ETH_FEE, VY_FEE);
  }

  function _transfer(address recipient, uint256 amount) private {
    (bool sent,) = recipient.call{value: amount}("");
    require(sent, "Failed to send Ether");
  }

  function _validateTradeOfferETHAmount(uint256 id, address seller, uint256 quantity) private {
    if (_offers[seller][id].tradingPair == TradingPairs.VY_ETH) {
      require(msg.value == quantity, "Invalid ETH amount sent");
    } else {
      require(msg.value == 0, "Invalid ETH amount sent");
    }
  }
}