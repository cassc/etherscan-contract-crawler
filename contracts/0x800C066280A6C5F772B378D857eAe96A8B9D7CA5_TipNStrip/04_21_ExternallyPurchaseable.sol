// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./Purchaseable.sol";

// @author rollauver.eth

abstract contract ExternallyPurchaseable is Purchaseable {
  mapping(address => uint256) private _externalRelays;

  constructor() {
    _externalRelays[0xdAb1a1854214684acE522439684a145E62505233] = 1;
    _externalRelays[0x12A80DAEaf8E7D646c4adfc4B107A2f1414E2002] = 1;
    _externalRelays[0xDa30ee0788276c093e686780C25f6C9431027234] = 1;
  }
  
  modifier onlyRelay() {
    require(_externalRelays[msg.sender] == 1, "Invalid External relay");
    _;
  }

  function externalPurchase(address to, uint256 count) external payable whenNotPaused onlyRelay {
    purchaseHelper(to, count);
  }

  function externalEarlyPurchase(address to, uint256 count) external payable whenNotPaused onlyRelay {
    require(isPreSaleActive(), "BASE_COLLECTION/CANNOT_MINT_PRESALE");

    earlyPurchaseHelper(to, count);
  }

  function addExternalRelay(address relay) external onlyOwner {
    _externalRelays[relay] = 1;
  }

  function removeExternalRelay(address relay) external onlyOwner {
    _externalRelays[relay] = 0;
  }
}