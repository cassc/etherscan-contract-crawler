// SPDX-License-Identifier: MIT
//
// MFCExchangeCap [MFC_BUSD]
//
pragma solidity ^0.8.4;

import "../access/BackendAgent.sol";
import "../lib/token/BEP20/BEP20.sol";
import "../token/MFCToken.sol";
import "../treasury/Treasury.sol";
import "./ExchangeCheck.sol";
import "../RegistrarClient.sol";
import "../RegistrarMigrator.sol";
import "../access/AdminGovernanceAgent.sol";
import "../governance/Governable.sol";
import "./MFCExchangeFloor.sol";

contract MFCExchangeCap is BackendAgent, ExchangeCheck, RegistrarClient, RegistrarMigrator, AdminGovernanceAgent, Governable {

  uint256 public constant BUSD_FEE = 20000000000000000;
  uint256 public constant MFC_FEE = 20000000000000000;
  uint256 public constant MULTIPLIER = 10**18;
  uint256 public constant MIN_PRICE_FACTOR = 1900000000000000000; // 1.9 ethers

  MFCToken private _mfc;
  BEP20 private _busd;
  MFCExchangeFloor private _mfcExchangeFloor;
  address private _busdTreasuryAddress;
  address private _busdComptrollerAddress;
  address private _migration;
  uint256 private _nonce = 1;
  uint256 private _mfcAllocatedInOffers = 0;

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
    address registrarAddress_,
    address busdAddress_,
    address busdComptrollerAddress_,
    address[] memory adminAgents,
    address[] memory backendAdminAgents,
    address[] memory backendAgents,
    address[] memory adminGovAgents
  ) RegistrarClient(registrarAddress_)
    RegistrarMigrator(registrarAddress_, adminAgents)
    AdminGovernanceAgent(adminGovAgents) {
    _busd = BEP20(busdAddress_);
    _busdComptrollerAddress = busdComptrollerAddress_;
    _setBackendAdminAgents(backendAdminAgents);
    _setBackendAgents(backendAgents);
  }

  function getNonce() external view returns (uint256) {
    return _nonce;
  }

  function getMfcAllocatedInOffers() external view returns (uint256) {
    return _mfcAllocatedInOffers;
  }

  function getOffer(uint256 id) external view returns (Offer memory) {
    return _offers[id];
  }

  function getMigration() external view returns (address) {
    return _migration;
  }

  function setMigration(address destination) external onlyGovernance {
    _migration = destination;
  }

  function transferMigration(uint256 amount) external onlyAdminGovAgents {
    require(_migration != address(0), "Migration not set");
    require(_mfc.balanceOf(address(this)) >= amount, "Insufficient balance");
    _mfc.transfer(_migration, amount);
  }

  function createOffer(uint256 quantity, uint256 price) external onlyBackendAgents {
    require(quantity > 0, "Invalid quantity");
    require(price > 0, "Invalid price");

    // If the floor price is > 0, then enforce the 1.9x minimum price
    // else if the floor price is 0 then any price is ok and don't enforce a minimum price.
    // Min price = inverted floor price in BUSD/MFC * 1.9
    if (_mfcExchangeFloor.getPrice() > 0) {
      uint256 minPrice = MIN_PRICE_FACTOR * MULTIPLIER / _mfcExchangeFloor.getPrice();
      require(price >= minPrice, "Price must be >= minPrice");
    }

    uint256 _mfcBalance = _mfc.balanceOf(address(this));
    uint256 _desiredTotalMfc = _mfcAllocatedInOffers + quantity;
    if (_desiredTotalMfc > _mfcBalance) {
      uint256 amountToMint = _desiredTotalMfc - _mfcBalance;
      _mfc.mint(amountToMint);
    }

    uint256 id = _nonce++;
    _offers[id] = Offer(id, quantity, price, true);
    _mfcAllocatedInOffers += quantity;
    emit CreateOffer(id, quantity, price, block.timestamp);
  }

  function tradeOffer(uint256 id, uint256 quantity) external onlyValidMember(_msgSender()) {
    require(_isOfferActive(id), "Invalid offer");
    require(quantity > 0, "Invalid quantity");

    uint256 maxInput = _offers[id].quantity * _offers[id].price / MULTIPLIER;

    require(quantity <= maxInput, "Not enough to sell");

    uint256 buyQuantity = _tradeOffer(quantity, _offers[id].price);

    require(_offers[id].quantity >= buyQuantity, "Bad calculations");
    _offers[id].quantity -= buyQuantity;
    _mfcAllocatedInOffers -= buyQuantity;

    emit TradeOffer(id, _msgSender(), buyQuantity, quantity, _offers[id].quantity, block.timestamp);
  }

  function closeOffer(uint256 id) external onlyBackendAgents {
    require(_isOfferActive(id), "Invalid offer");
    _closeOffer(id);
  }

  function updateAddresses() public override onlyRegistrar {
    _mfc = MFCToken(_registrar.getMFCToken());
    _busdTreasuryAddress = _registrar.getBUSDT();
    _mfcExchangeFloor = MFCExchangeFloor(_registrar.getMFCExchangeFloor());
    _updateExchangeCheck(_registrar);
    _updateGovernable(_registrar);
  }

  function _isOfferActive(uint256 id) private view returns (bool) {
    return _offers[id].isOpen;
  }

  // @dev returns maker quantity fulfilled by this trade
  function _tradeOffer(uint256 quantity, uint256 price) private returns (uint256) {
    require(_busd.allowance(_msgSender(), address(this)) >= quantity, "Insufficient allowance");
    require(_busd.balanceOf(_msgSender()) >= quantity, "Insufficient balance");

    uint256 buyQuantity = quantity * MULTIPLIER / price;

    require(_mfc.balanceOf(address(this)) >= buyQuantity, "Not enough to sell");

    uint256 makerFee = quantity * MFC_FEE / MULTIPLIER;
    uint256 takerFee = buyQuantity * BUSD_FEE / MULTIPLIER;

    uint256 makerReceives = quantity - makerFee;
    uint256 takerReceives = buyQuantity - takerFee;

    _busd.transferFrom(_msgSender(), _busdTreasuryAddress, makerReceives);
    _busd.transferFrom(_msgSender(), _busdComptrollerAddress, makerFee);
    _mfc.transfer(_msgSender(), takerReceives);

    return buyQuantity;
  }

  function _closeOffer(uint256 id) private {
    _mfcAllocatedInOffers -= _offers[id].quantity;
    _offers[id].isOpen = false;
    _offers[id].quantity = 0;
    emit CloseOffer(id, block.timestamp);
  }

  function _registrarMigrate(uint256 amount) internal override {
    _mfc.registrarMigrateExchangeCap(getRegistrarMigrateDestination(), amount);
  }
}