// SPDX-License-Identifier: MIT
// BuildingIdeas.io (Withdrawable.sol)

pragma solidity ^0.8.11;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

abstract contract Withdrawable is Ownable, ReentrancyGuard {

  address private DEVELOPER_ADDRESS;
  uint256 private DEVELOPER_FEE;

  function setDeveloperPaymentAddress(address _developerAddress) public virtual onlyOwner {
    DEVELOPER_ADDRESS = _developerAddress;
  }

  function setDeveloperPaymentFee(uint256 fee) public virtual onlyOwner {
    DEVELOPER_FEE = fee;
  }

  function ceilDiv(uint256 a, uint256 b) private pure returns (uint256) {
    // (a + b - 1) / b can overflow on addition, so we distribute.
    return a / b + (a % b == 0 ? 0 : 1);
  }

  function withdraw() external onlyOwner nonReentrant {
    require(address(this).balance > 0, "Contract must have balance");

    uint256 unit = ceilDiv(address(this).balance, 100);

    (bool paymentDevelopersSuccess, ) = DEVELOPER_ADDRESS.call{value: unit * DEVELOPER_FEE }("");
    require(paymentDevelopersSuccess, "Payment to developers failed.");

    (bool paymentOwnersSuccess, ) = _msgSender().call{value: address(this).balance}("");
    require(paymentOwnersSuccess, "Withdrawal failed.");
  }
}