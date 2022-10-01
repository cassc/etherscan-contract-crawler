// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract StanLeePayments is PaymentSplitter, Ownable {
  constructor(address[] memory _payees, uint256[] memory _shares) payable PaymentSplitter(_payees, _shares) {}

  // only owner, fail safe
  function withdraw(address _address) external onlyOwner {
    (bool success, ) = payable(_address).call{value: address(this).balance}("");

    require(success, "Withdraw failed.");
  }
}