// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/finance/PaymentSplitterUpgradeable.sol";
import "../generated/impl/BaseCedarPaymentSplitterV0.sol";


contract CedarPaymentSplitterV0 is PaymentSplitterUpgradeable, BaseCedarPaymentSplitterV0 {
  mapping(address => bool) private payeeExists;

  function initialize (address[] memory payees, uint256[] memory shares_) external initializer {
    uint256 totalShares = 0;
    for(uint i = 0; i < shares_.length; i++) {
      totalShares = totalShares + shares_[i];

      require(payeeExists[payees[i]] == false, "duplicate");
      payeeExists[payees[i]] = true;
    }

    require(totalShares == 10000, "total share should be 10000");

    __PaymentSplitter_init(payees, shares_);
  }

  // Concrete implementation semantic version - provided for completeness but not designed to be the point of dispatch
  function minorVersion() public pure override returns (uint256 minor, uint256 patch) {
      minor = 0;
      patch = 0;
  }

  function getTotalReleased() external override view returns (uint256) {
    return totalReleased();
  }

  function getTotalReleased(IERC20Upgradeable token) external override view returns (uint256) {
    return totalReleased(token);
  }

  function getReleased(address account) external override view returns (uint256) {
    return released(account);
  }

  function getReleased(IERC20Upgradeable token, address account) external override view returns (uint256) {
    return released(token, account);
  }

  function releasePayment(address payable account) external override {
    release(account);
  }

  function releasePayment(IERC20Upgradeable token, address account) external override {
    release(token, account);
  }
}