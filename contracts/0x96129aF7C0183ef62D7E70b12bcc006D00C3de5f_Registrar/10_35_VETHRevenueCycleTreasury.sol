// SPDX-License-Identifier: MIT
//
// VETHRevenueCycleTreasury [VY_ETH]
//

pragma solidity 0.8.18;

import { BackendAgent } from "../access/BackendAgent.sol";
import { VYToken } from "../token/VYToken.sol";
import { RegistrarClient } from "../RegistrarClient.sol";
import { RegistrarMigrator } from "../RegistrarMigrator.sol";
import { AdminGovernanceAgent } from "../access/AdminGovernanceAgent.sol";
import { Governable } from "../governance/Governable.sol";
import { VETHYieldRateTreasury } from "../treasury/VETHYieldRateTreasury.sol";
import { VYSupplyTracker } from "./VYSupplyTracker.sol";
import { Registrar } from "../Registrar.sol";
import { Router } from "../Router.sol";

contract VETHRevenueCycleTreasury is BackendAgent, RegistrarClient, RegistrarMigrator, AdminGovernanceAgent, Governable, VYSupplyTracker {

  uint256 private constant MULTIPLIER = 10**18;

  uint256 public constant ETH_FEE = 20000000000000000;
  uint256 public constant VY_FEE = 20000000000000000;
  uint256 public constant CREATE_PRICE_FACTOR = 2000000000000000000; // 2 multiplier
  uint256 public constant YIELD_RATE_FACTOR = 1030000000000000000; // 1.03 multiplier

  VYToken internal _vyToken;
  VETHYieldRateTreasury private _vethYRT;
  Router private _ethComptroller;
  address private _migration;
  uint256 private _nonce = 0;
  uint256 private _vyAllocatedInOffer = 0;
  uint256 internal _initialYieldRate = 0;

  struct Offer {
    uint256 id;
    uint256 quantity;
    uint256 price;
    bool isOpen;
  }

  mapping(uint256 => Offer) private _offers;

  event CreateOffer(uint256 id, uint256 quantity, uint256 price, uint256 timestamp);
  event TradeOffer(uint256 id, address buyer, uint256 sellerQuantity, uint256 buyerQuantity, uint256 unfilledQuantity, uint256 timestamp);
  event CloseOffer(uint256 id, uint256 timestamp);

  constructor(
    address registrarAddress,
    address ethComptrollerAddress_,
    address[] memory adminAgents,
    address[] memory backendAdminAgents,
    address[] memory backendAgents,
    address[] memory adminGovAgents,
    uint256 initialYieldRate_,
    uint256 initialStakeSupply
  ) RegistrarClient(registrarAddress)
    RegistrarMigrator(registrarAddress, uint(Registrar.Contract.VETHRevenueCycleTreasury), adminAgents)
    AdminGovernanceAgent(adminGovAgents)
    VYSupplyTracker(initialStakeSupply) {
    _ethComptroller = Router(payable(ethComptrollerAddress_));
    _setBackendAdminAgents(backendAdminAgents);
    _setBackendAgents(backendAgents);
    _initialYieldRate = initialYieldRate_;
  }

  function getNonce() external view returns (uint256) {
    return _nonce;
  }

  function getVYAllocatedInOffer() external view returns (uint256) {
    return _vyAllocatedInOffer;
  }

  function getOffer(uint256 id) external view returns (Offer memory) {
    return _offers[id];
  }

  function getMigration() external view returns (address) {
    return _migration;
  }

  function getInitialYieldRate() external view returns (uint256) {
    return _initialYieldRate;
  }

  function getYieldRate() external view returns (uint256) {
    return _getYieldRate();
  }

  function setMigration(address destination) external onlyGovernance {
    _migration = destination;
  }

  function transferMigration(uint256 amount) external onlyAdminGovAgents {
    require(_migration != address(0), "Migration not set");
    require(_vyToken.balanceOf(address(this)) >= amount, "Insufficient balance");
    _vyToken.transfer(_migration, amount);
  }

  function createOffer(uint256 quantity) external onlyBackendAgents {
    require(quantity > 0, "Invalid quantity");

    uint256 yieldRate = _getYieldRate();
    require(yieldRate > 0, "Yield rate must be greater than zero");
    uint256 price = CREATE_PRICE_FACTOR * MULTIPLIER / yieldRate;

    Offer memory offer = _offers[_nonce];
    if (offer.isOpen) {
      _closeOffer(_nonce);
    }

    uint256 _vyBalance = _vyToken.balanceOf(address(this));
    uint256 _desiredTotalVY = _vyAllocatedInOffer + quantity;

    uint256 id = ++_nonce;
    _offers[id] = Offer(id, quantity, price, true);
    _vyAllocatedInOffer += quantity;

    if (_desiredTotalVY > _vyBalance) {
      uint256 amountToMint = _desiredTotalVY - _vyBalance;
      _vyToken.mint(amountToMint);
    }

    emit CreateOffer(id, quantity, price, block.timestamp);
  }

  function tradeOffer(uint256 id) external payable {
    require(msg.value > 0, "Invalid quantity");
    require(_isOfferActive(id), "Invalid offer");

    uint256 price = _offers[id].price;
    uint256 maxInput = _offers[id].quantity * price / MULTIPLIER;
    require(msg.value <= maxInput, "Not enough to sell");

    /// @dev returns maker quantity fulfilled by this trade
    uint256 buyQuantity = msg.value * MULTIPLIER / price;
    require(_vyToken.balanceOf(address(this)) >= buyQuantity, "Not enough to sell");

    // Add yield rate > 0 check to avoid error dividing by 0 yield rate from the following cases:
    // 1. VETHYieldRateTreasury contract swap making treasuryValue 0
    // 2. Stake supply = 0 and initial yield rate = 0
    uint256 yieldRate = _getYieldRate();
    if (yieldRate > 0) {
      uint256 limitYieldRate = YIELD_RATE_FACTOR * MULTIPLIER / yieldRate;
      // Ensure offer price is still above yield rate to enforce rising yield rate rule
      require(price >= limitYieldRate, "Price must be >= limitYieldRate");
    }

    // Update offer quantity and total VY allocated
    require(_offers[id].quantity >= buyQuantity, "Bad calculations");
    _offers[id].quantity -= buyQuantity;
    _vyAllocatedInOffer -= buyQuantity;

    uint256 makerFee = msg.value * VY_FEE / MULTIPLIER;
    uint256 takerFee = buyQuantity * ETH_FEE / MULTIPLIER;

    uint256 makerReceives = msg.value - makerFee;
    uint256 takerReceives = buyQuantity - takerFee;

    _transfer(address(_vethYRT), makerReceives);
    _ethComptroller.route{ value: makerFee }();
    _vyToken.transfer(_msgSender(), takerReceives);

    emit TradeOffer(id, _msgSender(), buyQuantity, msg.value, _offers[id].quantity, block.timestamp);
  }

  function closeOffer(uint256 id) external onlyBackendAgents {
    require(_isOfferActive(id), "Invalid offer");
    _closeOffer(id);
  }

  function updateAddresses() external override onlyRegistrar {
    _vyToken = VYToken(_registrar.getVYToken());
    _vethYRT = VETHYieldRateTreasury(payable(_registrar.getVETHYieldRateTreasury()));
    _updateGovernable(_registrar);
    _updateVYSupplyTracker(_registrar);
  }

  function _isOfferActive(uint256 id) private view returns (bool) {
    return _offers[id].isOpen;
  }

  function _getYieldRate() private view returns (uint256) {
    uint256 stakeSupply = getStakeSupply();
    uint256 treasuryValue = _vethYRT.getYieldRateTreasuryValue();

    if (treasuryValue == 0) {
      return 0;
    }

    if (stakeSupply > 0) {
      return MULTIPLIER * stakeSupply / treasuryValue;
    } else {
      return _initialYieldRate;
    }
  }

  function _transfer(address recipient, uint256 amount) private {
    (bool sent,) = recipient.call{value: amount}("");
    require(sent, "Failed to send Ether");
  }

  function _closeOffer(uint256 id) private {
    _vyAllocatedInOffer -= _offers[id].quantity;
    _offers[id].isOpen = false;
    _offers[id].quantity = 0;
    emit CloseOffer(id, block.timestamp);
  }
}