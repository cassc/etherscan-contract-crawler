// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./OwnableUpgradeable.sol";

abstract contract HPApprovedMarketplaceUpgradeable is OwnableUpgradeable {

  event MessageSender(address sender, bool hasAccess);

  mapping(address => bool) internal _approvedMarketplaces;

  function setApprovedMarketplaceActive(address marketplaceAddress, bool approveMarket) public onlyOwner {
    _approvedMarketplaces[marketplaceAddress] = approveMarket;
  }

  function isApprovedMarketplace(address marketplaceAddress) public view returns(bool) {
    return _approvedMarketplaces[marketplaceAddress];
  }

  function msgSenderEmit() public {
    bool hasAccess = _approvedMarketplaces[msg.sender];
    emit MessageSender(msg.sender, hasAccess);
  }
}